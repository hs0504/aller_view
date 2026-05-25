import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  late final Dio publicDio;

  static const _storage = FlutterSecureStorage();
  final String _baseUrl = 'https://allerview-729003075709.asia-northeast3.run.app';
  // final String _baseUrl = 'http://10.184.144.46:8080';

  /// 토큰이 완전히 만료되어 재로그인이 필요할 때 호출되는 콜백
  /// main.dart 또는 최상위 위젯에서 네비게이터 이동 로직을 등록해두면 됨
  static void Function()? onSessionExpired;

  DioClient() {
    publicDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    // Auth Interceptor: 저장된 토큰 헤더 첨부 + 401 시 토큰 갱신 후 재시도
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
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
                final refreshResponse = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                if (refreshResponse.statusCode == 200 ||
                    refreshResponse.statusCode == 201) {
                  final newAccess =
                      refreshResponse.data['access_token'] as String;
                  final newRefresh =
                      refreshResponse.data['refresh_token'] as String;
                  await _storage.write(key: 'access_token', value: newAccess);
                  await _storage.write(
                      key: 'refresh_token', value: newRefresh);

                  // 원래 요청 재시도
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newAccess';
                  final retryResponse = await publicDio.fetch(opts);
                  handler.resolve(retryResponse);
                  return;
                }
              } catch (e) {
                if (kDebugMode) print('Token refresh error: $e');
              }
            }
            // refresh 실패 → 토큰 삭제 후 세션 만료 알림
            await _storage.delete(key: 'access_token');
            await _storage.delete(key: 'refresh_token');
            onSessionExpired?.call();
          }
          handler.next(error);
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

  Future<Response?> get(
      String path, {
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final response = await publicDio.get(path, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      // 4xx/5xx는 response를 그대로 반환 → 호출부에서 statusCode 분기 가능
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
        String? token, // 일회성 Bearer 토큰 (Google OAuth 등)
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