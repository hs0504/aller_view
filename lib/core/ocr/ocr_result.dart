enum OcrExtractionStrategy {
  blocks,
  legacyTextAnnotations,
}

class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.lines,
    required this.strategy,
  });

  /// Vision API가 추출한 전체 텍스트
  final String fullText;

  /// 줄 단위로 분리된 텍스트 목록 (빈 줄 제외)
  final List<String> lines;

  /// 어떤 OCR 추출 경로를 사용했는지 표시
  final OcrExtractionStrategy strategy;

  bool get isEmpty => fullText.isEmpty;

  String get strategyLabel => switch (strategy) {
        OcrExtractionStrategy.blocks => 'Blocks 추출',
        OcrExtractionStrategy.legacyTextAnnotations => 'Legacy 추출',
      };
}
