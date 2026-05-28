import 'dart:typed_data';

import 'package:image/image.dart' as img;

class NormalizedMenuImage {
  const NormalizedMenuImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final double width;
  final double height;
}

class MenuImageNormalizer {
  const MenuImageNormalizer._();

  static NormalizedMenuImage normalize(
    Uint8List sourceBytes, {
    int? maxLongSide,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return NormalizedMenuImage(bytes: sourceBytes, width: 0, height: 0);
    }

    final oriented = img.bakeOrientation(decoded);
    final longSide = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final output = maxLongSide != null && longSide > maxLongSide
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? maxLongSide : null,
            height: oriented.height > oriented.width ? maxLongSide : null,
          )
        : oriented;
    final normalizedBytes = Uint8List.fromList(
      img.encodeJpg(output, quality: 100),
    );

    return NormalizedMenuImage(
      bytes: normalizedBytes,
      width: output.width.toDouble(),
      height: output.height.toDouble(),
    );
  }
}
