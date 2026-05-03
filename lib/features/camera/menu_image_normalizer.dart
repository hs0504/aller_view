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

  static NormalizedMenuImage normalize(Uint8List sourceBytes) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return NormalizedMenuImage(
        bytes: sourceBytes,
        width: 0,
        height: 0,
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final normalizedBytes = Uint8List.fromList(
      img.encodeJpg(oriented, quality: 100),
    );

    return NormalizedMenuImage(
      bytes: normalizedBytes,
      width: oriented.width.toDouble(),
      height: oriented.height.toDouble(),
    );
  }
}
