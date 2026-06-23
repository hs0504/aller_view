import 'package:allerview/core/api/analyze_menu_client.dart';
import 'package:allerview/core/ocr/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildRequestBody matches the analyze-menu request spec', () {
    final body = AnalyzeMenuClient.buildRequestBody(
      const [
        OcrTextBlock(
          itemId: 'box_001',
          rawText: 'Shrimp Butter',
          boundingBox: OcrBoundingBox(
            vertices: [
              Offset(10, 10),
              Offset(50, 10),
              Offset(50, 20),
              Offset(10, 20),
            ],
          ),
        ),
      ],
      departureLanguage: 'en',
      arrivalLanguage: 'ko',
      userAllergies: ['땅콩', '우유', '새우'],
      userPreferences: {
        'spicy': 3,
        'salty': 3,
        'sweet': 3,
        'meat': 5,
        'seafood': 1,
        'vegetarian': 1,
      },
    );

    expect(body, {
      'departure_language': 'en',
      'arrival_language': 'ko',
      'user_allergies': ['땅콩', '우유', '새우'],
      'user_preferences': {
        'spicy': 3,
        'salty': 3,
        'sweet': 3,
        'meat': 5,
        'seafood': 1,
        'vegetarian': 1,
      },
      'menu_items': [
        {
          'box_id': 'box_001',
          'raw_text': 'Shrimp Butter',
          'vertices': [
            {'x': 10, 'y': 10},
            {'x': 50, 'y': 10},
            {'x': 50, 'y': 20},
            {'x': 10, 'y': 20},
          ],
        },
      ],
    });
  });

  test('buildRequestBody fills missing preference keys with zero', () {
    final body = AnalyzeMenuClient.buildRequestBody(
      const <OcrTextBlock>[],
      userPreferences: {'spicy': 4},
    );

    expect(body['user_preferences'], {
      'spicy': 4,
      'salty': 0,
      'sweet': 0,
      'meat': 0,
      'seafood': 0,
      'vegetarian': 0,
    });
  });
}
