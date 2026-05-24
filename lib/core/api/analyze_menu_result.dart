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
    required this.boxId,
    required this.rawText,
    required this.vertices,
  });

  final String boxId;
  final String rawText;
  final List<Map<String, int>> vertices;

  Map<String, dynamic> toJson() => {
    'box_id': boxId,
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

  static RiskAnalyzedResult? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return RiskAnalyzedResult.fromJson(json);
  }

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

class AnalyzedMenuContent {
  const AnalyzedMenuContent({
    required this.itemType,
    required this.rawText,
    required this.translatedText,
    required this.convertedPrice,
    required this.normalizedText,
  });

  final String? itemType;
  final String? rawText;
  final String? translatedText;
  final String? convertedPrice;
  final String? normalizedText;

  factory AnalyzedMenuContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AnalyzedMenuContent(
        itemType: null,
        rawText: null,
        translatedText: null,
        convertedPrice: null,
        normalizedText: null,
      );
    }

    return AnalyzedMenuContent(
      itemType: json['item_type'] as String?,
      rawText: json['raw_text'] as String?,
      translatedText: json['translated_text'] as String?,
      convertedPrice: json['converted_price'] as String?,
      normalizedText: json['normalized_text'] as String?,
    );
  }
}

class AnalyzedMenuLayout {
  const AnalyzedMenuLayout({
    required this.sourceBoxIds,
    required this.direction,
    required this.ratio,
  });

  final List<String> sourceBoxIds;
  final String? direction;
  final double? ratio;

  factory AnalyzedMenuLayout.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AnalyzedMenuLayout(
        sourceBoxIds: <String>[],
        direction: null,
        ratio: null,
      );
    }

    return AnalyzedMenuLayout(
      sourceBoxIds: (json['source_box_ids'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      direction: json['direction'] as String?,
      ratio: (json['ratio'] as num?)?.toDouble(),
    );
  }
}

class AnalyzedMenuItem {
  const AnalyzedMenuItem({
    required this.itemId,
    required this.content,
    required this.layout,
    required this.riskAnalyzedResult,
  });

  final String itemId;
  final AnalyzedMenuContent content;
  final AnalyzedMenuLayout layout;
  final RiskAnalyzedResult? riskAnalyzedResult;

  String get itemType => content.itemType ?? '';
  String get originalText => content.rawText ?? '';
  String get translatedText =>
      content.translatedText ??
      content.convertedPrice ??
      content.normalizedText ??
      content.rawText ??
      '';
  String get normalizedText => content.normalizedText ?? '';
  String? get convertedPrice => content.convertedPrice;
  List<String> get sourceBoxIds => layout.sourceBoxIds;
  String? get layoutDirection => layout.direction;
  double? get layoutRatio => layout.ratio;
  bool get hasRiskAnalysis => riskAnalyzedResult != null;

  int? get dishId => riskAnalyzedResult?.dishId;
  AllergyRisk get allergyRisk =>
      riskAnalyzedResult?.riskLevel ?? AllergyRisk.unknown;
  List<String> get detectedAllergens =>
      riskAnalyzedResult?.riskCauses ?? const <String>[];

  factory AnalyzedMenuItem.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as Map<String, dynamic>?;
    final layoutJson = json['layout'] as Map<String, dynamic>?;

    return AnalyzedMenuItem(
      itemId: json['item_id'] as String? ?? '',
      content: contentJson == null
          ? AnalyzedMenuContent(
              itemType: null,
              rawText: json['raw_text'] as String?,
              translatedText: json['translated_text'] as String?,
              convertedPrice: null,
              normalizedText: json['normalized_text'] as String?,
            )
          : AnalyzedMenuContent.fromJson(contentJson),
      layout: AnalyzedMenuLayout.fromJson(layoutJson),
      riskAnalyzedResult: RiskAnalyzedResult.maybeFromJson(
        json['risk_analyzed_result'] as Map<String, dynamic>?,
      ),
    );
  }
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
    required this.status,
    required this.errorCode,
    required this.errorMessage,
    required this.items,
    required this.recommendations,
    required this.requestUrl,
    required this.requestJson,
    required this.rawResponseBody,
  });

  final String status;
  final String? errorCode;
  final String? errorMessage;
  final List<AnalyzedMenuItem> items;
  final List<RecommendedMenuItem> recommendations;
  final String requestUrl;
  final String requestJson;
  final String rawResponseBody;

  bool get isSuccess => status == 'success';

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
      status: json['status'] as String? ?? 'success',
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
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
        content: AnalyzedMenuContent(
          itemType: 'menu_name',
          rawText: entry.value,
          translatedText: entry.value,
          convertedPrice: null,
          normalizedText: '[정규화] ${entry.value}',
        ),
        layout: AnalyzedMenuLayout(
          sourceBoxIds: [itemId],
          direction: null,
          ratio: null,
        ),
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
      status: 'success',
      errorCode: null,
      errorMessage: null,
      items: items,
      recommendations: recommendations,
      requestUrl: 'DUMMY (API 미연결 상태)',
      requestJson: '{}',
      rawResponseBody: '{}',
    );
  }
}
