import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/allergy_data.dart';

class UserPrefs {
  UserPrefs._();

  static const _keySetupComplete = 'setup_complete';
  static const _keyNickname = 'nickname';
  static const _keyAllergyIndices = 'allergy_indices';
  static const _keyPreferenceScores = 'preference_scores';
  static const _keyDepartureLanguage = 'departure_language';
  static const _keyArrivalLanguage = 'arrival_language';

  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySetupComplete) ?? false;
  }

  static Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupComplete, true);
  }

  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, nickname);
  }

  static Future<String?> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNickname);
  }

  static Future<void> saveAllergyIndices(Set<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAllergyIndices, jsonEncode(indices.toList()));
  }

  static Future<Set<int>> loadAllergyIndices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAllergyIndices);
    if (raw == null) return {};
    return Set<int>.from(jsonDecode(raw) as List);
  }

  static List<String> allergyNamesFromIndices(Set<int> indices) {
    return indices
        .where((i) => i >= 0 && i < allergyItems.length)
        .map((i) => allergyItems[i]['name']!)
        .toList();
  }

  static const Map<String, String> _preferenceKeyToEn = {
    '매운맛': 'spicy',
    '짠맛':  'salty',
    '단맛':  'sweet',
    '육식':  'meat',
    '해산물': 'seafood',
    '채식':  'vegetarian',
  };

  /// 저장된 한국어 key를 영문 snake_case로 변환하여 반환합니다.
  static Map<String, int> preferenceScoresToEn(Map<String, int> scores) {
    final result = <String, int>{};
    scores.forEach((ko, score) {
      final en = _preferenceKeyToEn[ko];
      if (en != null) result[en] = score;
    });
    return result;
  }

  static Future<void> savePreferenceScores(Map<String, int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPreferenceScores,
      jsonEncode(_normalizePreferenceScores(scores)),
    );
  }

  static Future<Map<String, int>> loadPreferenceScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPreferenceScores);
    if (raw == null) return {};
    return _normalizePreferenceScores(jsonDecode(raw) as Map);
  }

  static Map<String, int> _normalizePreferenceScores(Map raw) {
    final normalized = <String, int>{};

    raw.forEach((key, value) {
      if (key is! String || value is! num) {
        return;
      }

      final score = value.toInt();
      if (score >= 1 && score <= 5) {
        normalized[key] = score;
      }
    });

    return normalized;
  }

  static Future<void> saveLanguageSettings({
    required String departureLanguage,
    required String arrivalLanguage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDepartureLanguage, departureLanguage);
    await prefs.setString(_keyArrivalLanguage, arrivalLanguage);
  }

  static Future<({String departure, String arrival})> loadLanguageSettings()
      async {
    final prefs = await SharedPreferences.getInstance();
    return (
      departure: prefs.getString(_keyDepartureLanguage) ?? 'ja',
      arrival: prefs.getString(_keyArrivalLanguage) ?? 'ko',
    );
  }
}
