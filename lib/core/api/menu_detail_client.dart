import '../network/dio_client.dart';

class MenuDetailException implements Exception {
  const MenuDetailException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MenuDetail {
  const MenuDetail({
    required this.dishId,
    required this.koreanName,
    required this.calorieMin,
    required this.calorieMax,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
  });

  final int dishId;
  final String koreanName;
  final int? calorieMin;
  final int? calorieMax;
  final String? imageUrl;
  final String? description;
  final List<String> ingredients;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  String get calorieLabel {
    if (calorieMin == null && calorieMax == null) {
      return '칼로리 정보 없음';
    }
    if (calorieMin != null && calorieMax != null) {
      if (calorieMin == calorieMax) {
        return '${calorieMin!} kcal';
      }
      return '${calorieMin!}~${calorieMax!} kcal';
    }
    if (calorieMin != null) {
      return '${calorieMin!} kcal 이상';
    }
    return '${calorieMax!} kcal 이하';
  }

  factory MenuDetail.fromJson(Map<String, dynamic> json) {
    return MenuDetail(
      dishId: (json['dish_id'] as num?)?.toInt() ?? 0,
      koreanName: json['korean_name'] as String? ?? '',
      calorieMin: (json['calorie_min'] as num?)?.toInt(),
      calorieMax: (json['calorie_max'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class MenuDetailClient {
  MenuDetailClient._();

  static final DioClient _dioClient = DioClient();
  static const _path =
      'https://allerview-729003075709.asia-northeast3.run.app/menu/details';

  static Future<List<MenuDetail>> fetchMenuDetails(List<int> dishIds) async {
    final normalizedIds = dishIds.toSet().toList();
    if (normalizedIds.isEmpty) {
      return const [];
    }

    final response = await _dioClient.post(
      _path,
      data: {'dish_ids': normalizedIds},
    );

    if (response == null) {
      throw const MenuDetailException('서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MenuDetailException(
        '메뉴 상세 정보를 불러오지 못했습니다. (${response.statusCode})',
      );
    }

    final data = response.data;
    if (data is! List) {
      throw const MenuDetailException('메뉴 상세 정보 응답 형식이 올바르지 않습니다.');
    }

    return data.map<MenuDetail>((entry) {
      if (entry is Map<String, dynamic>) {
        return MenuDetail.fromJson(entry);
      }
      if (entry is Map) {
        return MenuDetail.fromJson(
          entry.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      throw const MenuDetailException('메뉴 상세 정보 응답 형식이 올바르지 않습니다.');
    }).toList();
  }
}
