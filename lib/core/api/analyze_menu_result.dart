/// AI 서버 요청 단위 - OCR 줄 하나
class MenuRequestItem {
  const MenuRequestItem({required this.itemId, required this.rawText});

  final String itemId;
  final String rawText;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'raw_text': rawText,
      };
}

/// AI 서버 응답 단위 - 번역/정규화된 메뉴 항목 하나
class AnalyzedMenuItem {
  const AnalyzedMenuItem({
    required this.itemId,
    required this.originalText,
    required this.translatedText,
    required this.normalizedText,
  });

  final String itemId;
  final String originalText;
  final String translatedText;
  final String normalizedText;

  factory AnalyzedMenuItem.fromJson(Map<String, dynamic> json) =>
      AnalyzedMenuItem(
        itemId: json['item_id'] as String,
        originalText: json['original_text'] as String,
        translatedText: json['translated_text'] as String,
        normalizedText: json['normalized_text'] as String,
      );
}

/// AI 서버 전체 응답
class AnalyzeMenuResponse {
  const AnalyzeMenuResponse({
    required this.items,
    required this.requestUrl,
    required this.requestJson,
    required this.rawResponseBody,
  });

  final List<AnalyzedMenuItem> items;
  final String requestUrl;
  final String requestJson;
  final String rawResponseBody;

  factory AnalyzeMenuResponse.fromJson(
    Map<String, dynamic> json, {
    required String requestUrl,
    required String requestJson,
    required String rawResponseBody,
  }) {
    final list = json['analyzed_menu_items'] as List<dynamic>;
    return AnalyzeMenuResponse(
      items: list
          .map((e) => AnalyzedMenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      requestUrl: requestUrl,
      requestJson: requestJson,
      rawResponseBody: rawResponseBody,
    );
  }
}
