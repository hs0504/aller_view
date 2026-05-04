import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'analyze_menu_result.dart';

enum AnalyzeMenuRequestMethod {
  get,
  post,
}

class AnalyzeMenuClient {
  AnalyzeMenuClient._();

  static const String _baseUrl = 'https://allerview-ai-server-969074948675.us-central1.run.app';
  static const String _endpoint = '/api/analyze-menu';
  static const AnalyzeMenuRequestMethod _requestMethod =
      AnalyzeMenuRequestMethod.post;

  static List<MenuRequestItem> buildMenuItems(List<String> lines) {
    return lines.asMap().entries.map((e) {
      final id = 'box_${(e.key + 1).toString().padLeft(3, '0')}';
      return MenuRequestItem(itemId: id, rawText: e.value);
    }).toList();
  }

  static List<String> buildLinesFromRawText(String rawText) {
    return rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> buildRequestBody(
    List<String> lines, {
    String departureLanguage = 'ja',
    String arrivalLanguage = 'ko',
    List<String> userAllergies = const [],
    Map<String, int> userPreferences = const {},
  }) {
    final menuItems = buildMenuItems(lines);
    return {
      'departure_language': departureLanguage,
      'arrival_language': arrivalLanguage,
      'user_allergies': userAllergies,
      'user_preferences': userPreferences,
      'menu_items': menuItems.map((e) => e.toJson()).toList(),
    };
  }

  static String buildPrettyRequestJson(
    List<String> lines, {
    String departureLanguage = 'ja',
    String arrivalLanguage = 'ko',
    List<String> userAllergies = const [],
    Map<String, int> userPreferences = const {},
  }) {
    return const JsonEncoder.withIndent('  ').convert(
      buildRequestBody(
        lines,
        departureLanguage: departureLanguage,
        arrivalLanguage: arrivalLanguage,
        userAllergies: userAllergies,
        userPreferences: userPreferences,
      ),
    );
  }

  static String get requestUrl => Uri.parse('$_baseUrl$_endpoint').toString();

  /// OCR 줄 목록을 AI 서버로 전송하여 번역/정규화 결과를 반환합니다.
  ///
  /// [departureLanguage] : 메뉴판 원본 언어 코드 (ISO 639-1, 예: 'ja', 'zh', 'en')
  /// [arrivalLanguage]   : 번역 목표 언어 코드 (ISO 639-1, 예: 'ko')
  ///
  /// Throws [AnalyzeMenuException] on network error or server error.
  static Future<AnalyzeMenuResponse> analyzeMenu(
    List<String> lines, {
    String departureLanguage = 'ja',
    String arrivalLanguage = 'ko',
    List<String> userAllergies = const [],
    Map<String, int> userPreferences = const {},
  }) async {
    if (_baseUrl.contains('YOUR_SERVER_URL')) {
      throw const AnalyzeMenuException(
        'AnalyzeMenuClient의 baseUrl을 실제 서버 주소로 변경해 주세요.',
      );
    }

    final menuItems = buildMenuItems(lines);
    final requestBody = buildRequestBody(
      lines,
      departureLanguage: departureLanguage,
      arrivalLanguage: arrivalLanguage,
      userAllergies: userAllergies,
      userPreferences: userPreferences,
    );
    final requestJson = const JsonEncoder.withIndent('  ').convert(requestBody);
    final requestUrl = _buildRequestUrl(requestBody);

    debugPrint('');
    debugPrint('┌─────────────────────────────────────────');
    debugPrint(
      '│ [AnalyzeMenu] ${_requestMethod.name.toUpperCase()} 요청 → $requestUrl',
    );
    debugPrint('│ 항목 수: ${menuItems.length}개  |  $departureLanguage → $arrivalLanguage');
    debugPrint('├─────────────────────────────────────────');
    debugPrint(requestJson);
    debugPrint('└─────────────────────────────────────────');

    final http.Response response;
    try {
      response = switch (_requestMethod) {
        AnalyzeMenuRequestMethod.get => await http
            .get(
              Uri.parse(requestUrl),
              headers: {'Accept': 'application/json; charset=utf-8'},
            )
            .timeout(const Duration(seconds: 30)),
        AnalyzeMenuRequestMethod.post => await http
            .post(
              Uri.parse(requestUrl),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 30)),
      };
    } catch (e) {
      final detail = switch (e) {
        TimeoutException _ => '요청 시간 초과',
        _ => '${e.runtimeType}: $e',
      };
      debugPrint('[AnalyzeMenu] 네트워크 오류: $detail');
      throw AnalyzeMenuException('네트워크 오류가 발생했습니다.\n$detail');
    }

    final responseBody = utf8.decode(response.bodyBytes);
    debugPrint('');
    debugPrint('┌─────────────────────────────────────────');
    debugPrint('│ [AnalyzeMenu] 응답 ← 상태코드: ${response.statusCode}');
    debugPrint('├─────────────────────────────────────────');
    try {
      final prettyJson = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(responseBody));
      debugPrint(prettyJson);
    } catch (_) {
      debugPrint(responseBody);
    }
    debugPrint('└─────────────────────────────────────────');

    if (response.statusCode != 200) {
      throw AnalyzeMenuException('서버 오류가 발생했습니다. (${response.statusCode})');
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      return AnalyzeMenuResponse.fromJson(
        body,
        requestUrl: requestUrl,
        requestJson: requestJson,
        rawResponseBody: responseBody,
      );
    } catch (e) {
      debugPrint('[AnalyzeMenu] 응답 파싱 오류: $e');
      throw const AnalyzeMenuException('응답 형식이 올바르지 않습니다.');
    }
  }

  static String _buildRequestUrl(Map<String, dynamic> requestBody) {
    final baseUri = Uri.parse('$_baseUrl$_endpoint');

    if (_requestMethod == AnalyzeMenuRequestMethod.post) {
      return baseUri.toString();
    }

    return baseUri.replace(queryParameters: {
      'departure_language': requestBody['departure_language'],
      'arrival_language': requestBody['arrival_language'],
      'menu_items': jsonEncode(requestBody['menu_items']),
    }).toString();
  }
}

class AnalyzeMenuException implements Exception {
  const AnalyzeMenuException(this.message);

  final String message;

  @override
  String toString() => message;
}
