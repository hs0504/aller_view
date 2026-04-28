import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../env/app_env.dart';
import 'ocr_result.dart';

class VisionApiClient {
  VisionApiClient._();

  static const _endpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  /// 이미지 bytes를 Google Vision API에 전송하여 텍스트를 추출합니다.
  ///
  /// Throws [VisionApiException] on API key missing, network error, or API error.
  static Future<OcrResult> extractText(Uint8List imageBytes) async {
    final apiKey = AppEnv.googleVisionApiKey;

    if (apiKey.isEmpty) {
      throw const VisionApiException('API 키가 설정되지 않았습니다. .env 파일을 확인해 주세요.');
    }

    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Encode(imageBytes)},
                  'features': [
                    {'type': 'TEXT_DETECTION'},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const VisionApiException(
        '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해 주세요.',
      );
    }

    if (response.statusCode != 200) {
      throw VisionApiException('서버 오류가 발생했습니다. (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final responses = body['responses'] as List<dynamic>;
    if (responses.isEmpty) {
      return const OcrResult(
        fullText: '',
        lines: [],
        strategy: OcrExtractionStrategy.legacyTextAnnotations,
      );
    }

    final firstResponse = responses.first as Map<String, dynamic>;

    final blockResult = _extractFromBlocks(firstResponse);
    if (blockResult != null && !blockResult.isEmpty) {
      return blockResult;
    }

    final legacyResult = _extractFromLegacyTextAnnotations(firstResponse);
    if (legacyResult != null) {
      return legacyResult;
    }

    return const OcrResult(
      fullText: '',
      lines: [],
      strategy: OcrExtractionStrategy.legacyTextAnnotations,
    );
  }

  static OcrResult? _extractFromBlocks(Map<String, dynamic> responseJson) {
    final fullTextAnnotation =
        responseJson['fullTextAnnotation'] as Map<String, dynamic>?;
    final pages = fullTextAnnotation?['pages'] as List<dynamic>?;

    if (pages == null || pages.isEmpty) {
      return null;
    }

    final lines = <String>[];

    for (final page in pages) {
      final pageJson = page as Map<String, dynamic>;
      final blocks = pageJson['blocks'] as List<dynamic>? ?? const [];

      for (final block in blocks) {
        final blockText = _extractBlockText(block as Map<String, dynamic>);
        if (blockText.isEmpty) continue;
        lines.add(blockText);
      }
    }

    if (lines.isEmpty) {
      return null;
    }

    return OcrResult(
      fullText: lines.join('\n'),
      lines: lines,
      strategy: OcrExtractionStrategy.blocks,
    );
  }

  static String _extractBlockText(Map<String, dynamic> blockJson) {
    final paragraphs = blockJson['paragraphs'] as List<dynamic>? ?? const [];
    final paragraphTexts = <String>[];

    for (final paragraph in paragraphs) {
      final paragraphJson = paragraph as Map<String, dynamic>;
      final words = paragraphJson['words'] as List<dynamic>? ?? const [];
      final wordTexts = <String>[];

      for (final word in words) {
        final wordText = _extractWordText(word as Map<String, dynamic>);
        if (wordText.isNotEmpty) {
          wordTexts.add(wordText);
        }
      }

      final paragraphText = wordTexts.join(' ').trim();
      if (paragraphText.isNotEmpty) {
        paragraphTexts.add(paragraphText);
      }
    }

    return paragraphTexts.join(' ').trim();
  }

  static String _extractWordText(Map<String, dynamic> wordJson) {
    final symbols = wordJson['symbols'] as List<dynamic>? ?? const [];
    final buffer = StringBuffer();

    for (final symbol in symbols) {
      final symbolJson = symbol as Map<String, dynamic>;
      final text = symbolJson['text'] as String? ?? '';
      if (text.isNotEmpty) {
        buffer.write(text);
      }
    }

    return buffer.toString().trim();
  }

  static OcrResult? _extractFromLegacyTextAnnotations(
    Map<String, dynamic> responseJson,
  ) {
    final annotations = responseJson['textAnnotations'] as List<dynamic>?;

    if (annotations == null || annotations.isEmpty) {
      return null;
    }

    final fullText = annotations.first['description'] as String? ?? '';
    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return OcrResult(
      fullText: fullText,
      lines: lines,
      strategy: OcrExtractionStrategy.legacyTextAnnotations,
    );
  }
}

class VisionApiException implements Exception {
  const VisionApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
