import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 설정 데이터를 SharedPreferences에 저장/불러오는 클래스
class UserPrefs {
  UserPrefs._();

  static const _keySetupComplete = 'setup_complete';
  static const _keyAllergyIndices = 'allergy_indices';
  static const _keyPreferenceScores = 'preference_scores';

  /// 온보딩 완료 여부
  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySetupComplete) ?? false;
  }

  static Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupComplete, true);
  }

  /// 선택한 알레르기 항목 인덱스 저장/불러오기
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

  /// 식성 선호도 점수 저장/불러오기
  static Future<void> savePreferenceScores(Map<String, int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferenceScores, jsonEncode(scores));
  }

  static Future<Map<String, int>> loadPreferenceScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPreferenceScores);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }
}
