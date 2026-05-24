import 'dart:convert';

import 'package:allerview/core/api/analyze_menu_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the updated analyze-menu success response', () {
    final response = AnalyzeMenuResponse.fromJson(
      jsonDecode(_successResponseJson) as Map<String, dynamic>,
      requestUrl: 'https://example.test/api/analyze-menu',
      requestJson: '{}',
      rawResponseBody: _successResponseJson,
    );

    expect(response.status, 'success');
    expect(response.errorCode, isNull);
    expect(response.errorMessage, isNull);
    expect(response.isSuccess, isTrue);
    expect(response.items, hasLength(4));
    expect(response.recommendations.single.itemId, 'result_003');

    final mergedItem = response.items[0];
    expect(mergedItem.itemId, 'result_001');
    expect(mergedItem.itemType, 'menu_name');
    expect(mergedItem.originalText, 'Shrimp Butter Steak');
    expect(mergedItem.translatedText, '새우 버터 스테이크');
    expect(mergedItem.normalizedText, '새우버터스테이크');
    expect(mergedItem.sourceBoxIds, ['box_001', 'box_002']);
    expect(mergedItem.layoutDirection, isNull);
    expect(mergedItem.layoutRatio, isNull);
    expect(mergedItem.hasRiskAnalysis, isTrue);
    expect(mergedItem.dishId, 1);
    expect(mergedItem.allergyRisk, AllergyRisk.danger);
    expect(mergedItem.detectedAllergens, ['새우']);

    final splitItem = response.items[1];
    expect(splitItem.sourceBoxIds, ['box_003']);
    expect(splitItem.layoutDirection, 'horizontal');
    expect(splitItem.layoutRatio, 0.5);

    final priceItem = response.items[3];
    expect(priceItem.itemType, 'price');
    expect(priceItem.convertedPrice, '4,200원');
    expect(priceItem.hasRiskAnalysis, isFalse);
    expect(priceItem.allergyRisk, AllergyRisk.unknown);
    expect(priceItem.detectedAllergens, isEmpty);
  });

  test('parses the updated analyze-menu error response', () {
    final response = AnalyzeMenuResponse.fromJson(
      jsonDecode(_errorResponseJson) as Map<String, dynamic>,
      requestUrl: 'https://example.test/api/analyze-menu',
      requestJson: '{}',
      rawResponseBody: _errorResponseJson,
    );

    expect(response.status, 'error');
    expect(response.isSuccess, isFalse);
    expect(response.errorCode, 'OCR_NOISE_TOO_HIGH');
    expect(response.errorMessage, '메뉴판의 텍스트를 인식하기 어렵습니다.');
    expect(response.items, isEmpty);
    expect(response.recommendations, isEmpty);
  });
}

const _successResponseJson = '''
{
  "status": "success",
  "error_code": null,
  "error_message": null,
  "analyzed_menu_items": [
    {
      "item_id": "result_001",
      "content": {
        "item_type": "menu_name",
        "raw_text": "Shrimp Butter Steak",
        "translated_text": "새우 버터 스테이크",
        "converted_price": null,
        "normalized_text": "새우버터스테이크"
      },
      "layout": {
        "source_box_ids": ["box_001", "box_002"],
        "direction": null,
        "ratio": null
      },
      "risk_analyzed_result": {
        "dish_id": 1,
        "risk_level": "danger",
        "risk_causes": ["새우"]
      }
    },
    {
      "item_id": "result_002",
      "content": {
        "item_type": "menu_name",
        "raw_text": "Coke",
        "translated_text": "콜라",
        "converted_price": null,
        "normalized_text": "콜라"
      },
      "layout": {
        "source_box_ids": ["box_003"],
        "direction": "horizontal",
        "ratio": 0.5
      },
      "risk_analyzed_result": {
        "dish_id": 2,
        "risk_level": "safe",
        "risk_causes": []
      }
    },
    {
      "item_id": "result_003",
      "content": {
        "item_type": "menu_name",
        "raw_text": "Sprite",
        "translated_text": "사이다",
        "converted_price": null,
        "normalized_text": "사이다"
      },
      "layout": {
        "source_box_ids": ["box_003"],
        "direction": "horizontal",
        "ratio": 0.5
      },
      "risk_analyzed_result": {
        "dish_id": 3,
        "risk_level": "safe",
        "risk_causes": []
      }
    },
    {
      "item_id": "result_004",
      "content": {
        "item_type": "price",
        "raw_text": "\$ 3.00",
        "translated_text": "\$ 3.00",
        "converted_price": "4,200원",
        "normalized_text": null
      },
      "layout": {
        "source_box_ids": ["box_004"],
        "direction": null,
        "ratio": null
      },
      "risk_analyzed_result": null
    }
  ],
  "recommendations": [
    {
      "item_id": "result_003",
      "korean_name": "사이다"
    }
  ]
}
''';

const _errorResponseJson = '''
{
  "status": "error",
  "error_code": "OCR_NOISE_TOO_HIGH",
  "error_message": "메뉴판의 텍스트를 인식하기 어렵습니다.",
  "analyzed_menu_items": [],
  "recommendations": []
}
''';
