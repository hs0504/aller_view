import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const _keyNickname = 'nickname';
  static const _keyAllergies = 'allergies';
  static const _keyPreferredIngredients = 'preferred_ingredients';
  static const _keyIsGuest = 'is_guest';
  static const _keyOnboardingComplete = 'onboarding_complete';

  Future<void> saveProfile({
    required String nickname,
    required List<String> allergies,
    required List<String> preferredIngredients,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, nickname);
    await prefs.setString(_keyAllergies, jsonEncode(allergies));
    await prefs.setString(
        _keyPreferredIngredients, jsonEncode(preferredIngredients));
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNickname);
  }

  Future<List<String>> getAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAllergies);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<List<String>> getPreferredIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPreferredIngredients);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  Future<void> setGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, value);
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}