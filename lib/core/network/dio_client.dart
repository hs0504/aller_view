import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  late final Dio publicDio;

  static const _storage = FlutterSecureStorage();
  final String _baseUrl =
      'https://allerview-729003075709.asia-northeast3.run.app';

  /// 토큰이 완전히 만료되어 재로그인이 필요할 때 호출되는 콜백
  static void Function()? onSessionExpired;

  bool _isRefreshing = false;
  final List<({RequestOptions opts, ErrorInterceptorHandler handler})>
      _retryQueue = [];

  DioClient() {
    publicDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    publicDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // 이미 리프레시 진행 중이면 큐에 적재 후 대기
          if (_isRefreshing) {
            _retryQueue
                .add((opts: error.requestOptions, handler: handler));
            return;
          }

          _isRefreshing = true;
          try {
            final newToken = await _tryRefresh();
            if (newToken != null) {
              await _replayQueue(newToken);
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              handler.resolve(await publicDio.fetch(opts));
            } else {
              await _storage.delete(key: 'access_token');
              await _storage.delete(key: 'refresh_token');
              onSessionExpired?.call();
              _failQueue(error);
              handler.next(error);
            }
          } catch (e) {
            _failQueue(error);
            handler.next(error);
          } finally {
            _isRefreshing = false;
            _retryQueue.clear();
          }
        },
      ),
    );

    if (kDebugMode) {
      publicDio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  /// refresh_token으로 새 access_token 발급. 실패 시 null 반환.
  Future<String?> _tryRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final newAccess = res.data['access_token'] as String;
        final newRefresh = res.data['refresh_token'] as String;
        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);
        return newAccess;
      }
    } catch (e) {
      if (kDebugMode) print('Token refresh error: $e');
    }
    return null;
  }

  /// 대기 중인 요청들을 새 토큰으로 재시도
  Future<void> _replayQueue(String newToken) async {
    final queue = List.of(_retryQueue);
    for (final item in queue) {
      item.opts.headers['Authorization'] = 'Bearer $newToken';
      try {
        final response = await publicDio.fetch(item.opts);
        item.handler.resolve(response);
      } on DioException catch (e) {
        item.handler.next(e);
      }
    }
  }

  /// 리프레시 실패 시 대기 중인 요청들 모두 에러 처리
  void _failQueue(DioException error) {
    for (final item in _retryQueue) {
      item.handler.next(error);
    }
  }

  Future<Response?> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await publicDio.get(path, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse && e.response != null) {
        return e.response;
      }
      _handleDioError(e);
      return null;
    }
  }

  Future<Response?> post(
    String path, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response =
          await publicDio.post(path, data: data, options: options);
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse && e.response != null) {
        return e.response;
      }
      _handleDioError(e);
      return null;
    }
  }

  Future<Response?> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await publicDio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse && e.response != null) {
        return e.response;
      }
      _handleDioError(e);
      return null;
    }
  }

  void _handleDioError(DioException error) {
    if (kDebugMode) {
      if (error.type == DioExceptionType.connectionTimeout) {
        print('Connection Timeout: ${error.message}');
      } else if (error.type == DioExceptionType.receiveTimeout) {
        print('Receive Timeout: ${error.message}');
      } else if (error.type == DioExceptionType.badResponse) {
        print(
            'HTTP Error: ${error.response?.statusCode}, ${error.response?.data}');
      } else {
        print('Unexpected Error: ${error.message}');
      }
    }
  }
}
