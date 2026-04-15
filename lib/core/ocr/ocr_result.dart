class OcrResult {
  const OcrResult({required this.fullText, required this.lines});

  /// Vision API가 추출한 전체 텍스트
  final String fullText;

  /// 줄 단위로 분리된 텍스트 목록 (빈 줄 제외)
  final List<String> lines;

  bool get isEmpty => fullText.isEmpty;
}
