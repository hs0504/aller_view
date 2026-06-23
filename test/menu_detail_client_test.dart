import 'package:allerview/core/api/menu_detail_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses updated menu detail response fields', () {
    final detail = MenuDetail.fromJson(const {
      'dish_id': 246,
      'korean_name': '쌀국수',
      'calorie_min': 300,
      'calorie_max': 500,
      'image_url':
          'https://aller-view-s3-bucket.s3.us-east-1.amazonaws.com/dishes/246.jpg',
      'description': '쌀로 만든 얇은 국수를 고기나 해물과 함께 먹는 베트남의 대표적인 국수 요리입니다.',
      'ingredients': ['쌀국수', '돼지 고기', '해물', '채소', '고추장', '생강'],
    });

    expect(detail.dishId, 246);
    expect(detail.koreanName, '쌀국수');
    expect(detail.calorieLabel, '300~500 kcal');
    expect(detail.hasImage, isTrue);
    expect(detail.description, contains('베트남'));
    expect(detail.ingredients, ['쌀국수', '돼지 고기', '해물', '채소', '고추장', '생강']);
  });
}
