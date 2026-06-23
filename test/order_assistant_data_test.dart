import 'package:allerview/core/data/language_data.dart';
import 'package:allerview/core/data/order_assistant_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language options include expanded AI language codes', () {
    final departureCodes = departureLanguageOptions.map((e) => e.code).toSet();
    final arrivalCodes = arrivalLanguageOptions.map((e) => e.code).toSet();

    expect(departureCodes.length, greaterThanOrEqualTo(15));
    expect(arrivalCodes.length, greaterThanOrEqualTo(15));
    expect(departureCodes, containsAll(['ko', 'en', 'ja', 'zh-CN', 'zh-TW']));
    expect(departureCodes, containsAll(['es', 'fr', 'de', 'it', 'pt']));
    expect(departureCodes, containsAll(['vi', 'th', 'id', 'ar', 'ru']));
    expect(arrivalCodes, containsAll(departureCodes));
  });

  test('buildOrderAssistantQuestion uses departure language copy', () {
    final question = buildOrderAssistantQuestion(
      languageCode: 'en',
      menuName: 'Shrimp Butter Steak',
      allergyNames: ['shrimp', 'milk'],
    );

    expect(question, contains('shrimp, milk'));
    expect(question, contains('Shrimp Butter Steak'));
    expect(question, startsWith('I have allergies'));
  });

  test('translatedAllergyName falls back to Korean name', () {
    expect(translatedAllergyName('새우', 'ja'), 'エビ');
    expect(translatedAllergyName('없는 항목', 'en'), '없는 항목');
  });
}
