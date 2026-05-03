import 'dart:math' as math;
import 'dart:ui';

/// Bounding box for one OCR block.
///
/// Vertices are ordered roughly clockwise from top-left.
class OcrBoundingBox {
  const OcrBoundingBox({required this.vertices});

  final List<Offset> vertices;

  double get left => vertices.map((v) => v.dx).reduce(math.min);
  double get top => vertices.map((v) => v.dy).reduce(math.min);
  double get right => vertices.map((v) => v.dx).reduce(math.max);
  double get bottom => vertices.map((v) => v.dy).reduce(math.max);
  double get width => right - left;
  double get height => bottom - top;

  Rect get rect => Rect.fromLTRB(left, top, right, bottom);
}

/// One OCR text block that is safe to use for overlay rendering.
class OcrTextBlock {
  const OcrTextBlock({
    required this.itemId,
    required this.rawText,
    required this.boundingBox,
  });

  final String itemId;
  final String rawText;
  final OcrBoundingBox boundingBox;
}

enum OcrExtractionStrategy {
  blocks,
}

class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.strategy,
    this.imageWidth = 0.0,
    this.imageHeight = 0.0,
  });

  final String fullText;
  final List<OcrTextBlock> blocks;
  final OcrExtractionStrategy strategy;

  /// Vision API page width/height used as the source coordinate system.
  final double imageWidth;
  final double imageHeight;

  List<String> get lines => blocks.map((b) => b.rawText).toList();

  Map<String, OcrTextBlock> get blockMap => {
        for (final block in blocks) block.itemId: block,
      };

  bool get isEmpty => fullText.isEmpty;

  String get strategyLabel => switch (strategy) {
        OcrExtractionStrategy.blocks => 'Blocks 추출',
      };
}
