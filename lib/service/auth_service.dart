import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/dio_client.dart';
import '../core/storage/user_prefs.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';

  final DioClient _dioClient = DioClient();

  // 토큰 저장
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  // 토큰 조회
  Future<String?> getToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  // 로그인 여부
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  // 저장된 userId (numeric)
  Future<int?> getUserId() async {
    final value = await _storage.read(key: _keyUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // 이메일 회원가입 → 성공 시 자동 로그인으로 토큰 발급
  Future<AuthResult> signup({
    required String email,
    required String password,
    required String nickname,
    required List<String> allergies,
    required List<String> preferredIngredients,
  }) async {
    try {
      final response = await _dioClient.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
          'allergies': allergies,
          'preferred_ingredients': preferredIngredients,
        },
      );

      if (response == null) {
        if (kDebugMode) {
          print("1");
        }
        return AuthResult.networkError();
      }

      if (response.statusCode == 409) {
        if (kDebugMode) {
          print("2");
        }
        return AuthResult.emailConflict();
      }
      if (response.statusCode == 400) {
        if (kDebugMode) {
          print("3");
        }
        return AuthResult.validationError();
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode){
          print("4");
        }
        return login(email: email, password: password);
      }
      if(kDebugMode){
        print("5");
      }
      return AuthResult.unknown();
    } catch (e) {
      if (kDebugMode) print('Signup error: $e');
      return AuthResult.networkError();
    }
  }

  // 이메일 로그인
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response == null) return AuthResult.networkError();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await _saveTokens(data['access_token'], data['refresh_token']);
        if (data['allergy_ids'] != null) {
          await UserPrefs.saveAllergyIds(
            List<int>.from(data['allergy_ids'] as List),
          );
        }
        return AuthResult.success();
      }

      if (response.statusCode == 401) return AuthResult.invalidCredentials();
      if (response.statusCode == 400) return AuthResult.validationError();

      return AuthResult.unknown();
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      return AuthResult.networkError();
    }
  }

  // Google OAuth 프로필 등록 (Supabase 토큰 사용)
  Future<AuthResult> socialComplete({
    required String supabaseToken,
    required String nickname,
    required List<String> allergies,
    required List<String> preferredIngredients,
  }) async {
    try {
      final response = await _dioClient.post(
        '/auth/social/complete',
        token: supabaseToken,
        data: {
          'nickname': nickname,
          'allergies': allergies,
          'preferred_ingredients': preferredIngredients,
        },
      );

      if (response == null) return AuthResult.networkError();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        // Supabase 토큰을 access_token으로 저장 (이후 API 호출에 사용)
        await _storage.write(key: _keyAccessToken, value: supabaseToken);
        if (data['id'] != null) {
          await _storage.write(key: _keyUserId, value: data['id'].toString());
        }
        return AuthResult.success();
      }

      return AuthResult.unknown();
    } catch (e) {
      if (kDebugMode) print('Social complete error: $e');
      return AuthResult.networkError();
    }
  }

  // 알레르기/선호 식재료/아바타 프로필 서버 동기화
  Future<void> updateProfile({
    required List<String> allergies,
    String? avatarUrl,
    String? nickname,
  }) async {
    try {
      await _dioClient.put(
        '/users/me/profile',
        data: {
          'allergies': allergies,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (nickname != null) 'nickname': nickname,
        },
      );
    } catch (e) {
      if (kDebugMode) print('updateProfile error: $e');
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
  }
}

enum AuthResultType {
  success,
  emailConflict,
  invalidCredentials,
  validationError,
  networkError,
  unknown,
}

class AuthResult {
  final AuthResultType type;

  const AuthResult._(this.type);

  factory AuthResult.success() => const AuthResult._(AuthResultType.success);

  factory AuthResult.emailConflict() =>
      const AuthResult._(AuthResultType.emailConflict);

  factory AuthResult.invalidCredentials() =>
      const AuthResult._(AuthResultType.invalidCredentials);

  factory AuthResult.validationError() =>
      const AuthResult._(AuthResultType.validationError);

  factory AuthResult.networkError() =>
      const AuthResult._(AuthResultType.networkError);

  factory AuthResult.unknown() => const AuthResult._(AuthResultType.unknown);

  bool get isSuccess => type == AuthResultType.success;

  String get errorMessage {
    switch (type) {
      case AuthResultType.emailConflict:
        return '이미 사용 중인 이메일입니다';
      case AuthResultType.invalidCredentials:
        return '이메일 또는 비밀번호를 확인해주세요';
      case AuthResultType.validationError:
        return '입력 정보를 확인해주세요';
      case AuthResultType.networkError:
        return '네트워크 오류가 발생했습니다';
      default:
        return '오류가 발생했습니다. 다시 시도해주세요';
    }
  }
}
