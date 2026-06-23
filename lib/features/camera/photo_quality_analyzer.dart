import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PhotoQualityResult {
  const PhotoQualityResult({
    required this.focusScore,
    required this.isTooBlurry,
    required this.isLikelyBlurry,
    required this.title,
    required this.message,
  });

  final double focusScore;

  /// true: 매우 흐림 → 버튼 비활성, API 호출 차단
  final bool isTooBlurry;

  /// true: 약간 흐림 → 경고 표시, 버튼은 활성
  final bool isLikelyBlurry;

  final String title;
  final String message;
}

class PhotoQualityAnalyzer {
  const PhotoQualityAnalyzer._();

  static const double _blockThreshold = 4.0;  // 이하: 버튼 차단
  static const double _warnThreshold = 7.0;   // 이하: 경고만

  static PhotoQualityResult analyze(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return const PhotoQualityResult(
        focusScore: 0,
        isTooBlurry: true,
        isLikelyBlurry: true,
        title: '사진을 확인할 수 없어요',
        message: '이미지를 다시 촬영해 주세요.',
      );
    }

    final resized = img.copyResize(
      decoded,
      width: math.min(decoded.width, 480),
    );
    final score = _calculateFocusScore(resized);

    final isTooBlurry = score < _blockThreshold;
    final isLikelyBlurry = score < _warnThreshold;

    final String title;
    final String message;

    if (isTooBlurry) {
      title = '너무 흐릿해요';
      message = '초점이 맞지 않아 텍스트 인식이 어려워요. 다시 촬영해 주세요.';
    } else if (isLikelyBlurry) {
      title = '약간 흐릿할 수 있어요';
      message = '인식은 가능하지만 더 선명하게 찍으면 정확도가 올라가요.';
    } else {
      title = '촬영 상태가 좋아요';
      message = '이 사진으로 메뉴판 분석을 시작할 수 있어요.';
    }

    return PhotoQualityResult(
      focusScore: score,
      isTooBlurry: isTooBlurry,
      isLikelyBlurry: isLikelyBlurry,
      title: title,
      message: message,
    );
  }

  static double _calculateFocusScore(img.Image image) {
    double total = 0;
    int count = 0;

    for (var y = 1; y < image.height - 1; y += 2) {
      for (var x = 1; x < image.width - 1; x += 2) {
        final center = _luminance(image.getPixel(x, y));
        final left = _luminance(image.getPixel(x - 1, y));
        final right = _luminance(image.getPixel(x + 1, y));
        final up = _luminance(image.getPixel(x, y - 1));
        final down = _luminance(image.getPixel(x, y + 1));

        total += (center * 4 - left - right - up - down).abs();
        count++;
      }
    }

    return count == 0 ? 0 : total / count;
  }

  static double _luminance(img.Pixel pixel) {
    return 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
  }
}
