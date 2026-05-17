enum AllergyRisk { danger, caution, safe, unknown }

extension AllergyRiskLabel on AllergyRisk {
  String get label => switch (this) {
    AllergyRisk.danger => '위험',
    AllergyRisk.caution => '주의',
    AllergyRisk.safe => '안전',
    AllergyRisk.unknown => '미확인',
  };
}

class MenuRequestItem {
  const MenuRequestItem({
    required this.itemId,
    required this.rawText,
    required this.vertices,
  });

  final String itemId;
  final String rawText;
  final List<Map<String, int>> vertices;

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'raw_text': rawText,
    'vertices': vertices,
  };
}

class RiskAnalyzedResult {
  const RiskAnalyzedResult({
    required this.dishId,
    required this.riskLevel,
    required this.riskCauses,
  });

  final int? dishId;
  final AllergyRisk riskLevel;
  final List<String> riskCauses;

  factory RiskAnalyzedResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RiskAnalyzedResult(
        dishId: null,
        riskLevel: AllergyRisk.unknown,
        riskCauses: <String>[],
      );
    }

    return RiskAnalyzedResult(
      dishId: (json['dish_id'] as num?)?.toInt(),
      riskLevel: AllergyRisk.values.firstWhere(
        (risk) => risk.name == (json['risk_level'] as String? ?? 'unknown'),
        orElse: () => AllergyRisk.unknown,
      ),
      riskCauses: (json['risk_causes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class AnalyzedMenuItem {
  const AnalyzedMenuItem({
    required this.itemId,
    required this.originalText,
    required this.translatedText,
    required this.normalizedText,
    required this.riskAnalyzedResult,
  });

  final String itemId;
  final String originalText;
  final String translatedText;
  final String normalizedText;
  final RiskAnalyzedResult riskAnalyzedResult;

  int? get dishId => riskAnalyzedResult.dishId;
  AllergyRisk get allergyRisk => riskAnalyzedResult.riskLevel;
  List<String> get detectedAllergens => riskAnalyzedResult.riskCauses;

  factory AnalyzedMenuItem.fromJson(Map<String, dynamic> json) =>
      AnalyzedMenuItem(
        itemId: json['item_id'] as String? ?? '',
        originalText: json['raw_text'] as String? ?? '',
        translatedText: json['translated_text'] as String? ?? '',
        normalizedText: json['normalized_text'] as String? ?? '',
        riskAnalyzedResult: RiskAnalyzedResult.fromJson(
          json['risk_analyzed_result'] as Map<String, dynamic>?,
        ),
      );
}

class RecommendedMenuItem {
  const RecommendedMenuItem({required this.itemId, required this.koreanName});

  final String itemId;
  final String koreanName;

  factory RecommendedMenuItem.fromJson(Map<String, dynamic> json) =>
      RecommendedMenuItem(
        itemId: json['item_id'] as String? ?? '',
        koreanName: json['korean_name'] as String? ?? '',
      );
}

class AnalyzeMenuResponse {
  const AnalyzeMenuResponse({
    required this.items,
    required this.recommendations,
    required this.requestUrl,
    required this.requestJson,
    required this.rawResponseBody,
  });

  final List<AnalyzedMenuItem> items;
  final List<RecommendedMenuItem> recommendations;
  final String requestUrl;
  final String requestJson;
  final String rawResponseBody;

  factory AnalyzeMenuResponse.fromJson(
    Map<String, dynamic> json, {
    required String requestUrl,
    required String requestJson,
    required String rawResponseBody,
  }) {
    final rawItems = json['analyzed_menu_items'] as List<dynamic>? ?? const [];
    final rawRecommendations =
        json['recommendations'] as List<dynamic>? ?? const [];

    return AnalyzeMenuResponse(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(AnalyzedMenuItem.fromJson)
          .toList(),
      recommendations: rawRecommendations
          .whereType<Map<String, dynamic>>()
          .map(RecommendedMenuItem.fromJson)
          .toList(),
      requestUrl: requestUrl,
      requestJson: requestJson,
      rawResponseBody: rawResponseBody,
    );
  }

  factory AnalyzeMenuResponse.dummy(List<String> lines) {
    const riskCycle = [
      AllergyRisk.danger,
      AllergyRisk.caution,
      AllergyRisk.safe,
      AllergyRisk.unknown,
    ];
    const allergenCycle = [
      ['계란', '밀'],
      ['우유', '새우'],
      <String>[],
      <String>[],
    ];

    final items = lines.asMap().entries.map((entry) {
      final index = entry.key;
      final itemId = 'box_${(index + 1).toString().padLeft(3, '0')}';
      final riskIndex = index % riskCycle.length;

      return AnalyzedMenuItem(
        itemId: itemId,
        originalText: entry.value,
        translatedText: entry.value,
        normalizedText: '[정규화] ${entry.value}',
        riskAnalyzedResult: RiskAnalyzedResult(
          dishId: index + 1,
          riskLevel: riskCycle[riskIndex],
          riskCauses: List<String>.from(allergenCycle[riskIndex]),
        ),
      );
    }).toList();

    final recommendations = items.isEmpty
        ? const <RecommendedMenuItem>[]
        : [
            RecommendedMenuItem(
              itemId: items.first.itemId,
              koreanName: items.first.translatedText,
            ),
          ];

    return AnalyzeMenuResponse(
      items: items,
      recommendations: recommendations,
      requestUrl: 'DUMMY (API 미연결 상태)',
      requestJson: '{}',
      rawResponseBody: '{}',
    );
  }
}
