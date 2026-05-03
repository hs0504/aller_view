import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:http/http.dart' as http;

import '../env/app_env.dart';
import 'ocr_result.dart';

class VisionApiClient {
  VisionApiClient._();

  static const _endpoint =
      'https://vision.googleapis.com/v1/images:annotate';
  static const _retakeMessage =
      '텍스트 위치 정보를 추출하지 못했어요. 메뉴판을 정면에서 더 선명하게 다시 촬영해 주세요.';

  /// Extracts OCR blocks with bounding boxes from Google Vision API.
  ///
  /// Only block data that can be rendered as overlays is accepted. If Vision
  /// does not return usable paragraph-level bounding boxes, this throws a
  /// [VisionApiException] instead of falling back to text-only OCR.
  static Future<OcrResult> extractText(Uint8List imageBytes) async {
    final apiKey = AppEnv.googleVisionApiKey;

    if (apiKey.isEmpty) {
      throw const VisionApiException(
        'API 키가 설정되지 않았습니다. .env 파일을 확인해 주세요.',
      );
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
                    {'type': 'DOCUMENT_TEXT_DETECTION'},
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
      throw const VisionApiException(_retakeMessage);
    }

    final firstResponse = responses.first as Map<String, dynamic>;
    final blockResult = _extractFromBlocks(firstResponse);

    if (blockResult == null || blockResult.isEmpty) {
      throw const VisionApiException(_retakeMessage);
    }

    return blockResult;
  }

  static OcrResult? _extractFromBlocks(Map<String, dynamic> responseJson) {
    final fullTextAnnotation =
        responseJson['fullTextAnnotation'] as Map<String, dynamic>?;
    final pages = fullTextAnnotation?['pages'] as List<dynamic>?;

    if (pages == null || pages.isEmpty) return null;

    final ocrBlocks = <OcrTextBlock>[];
    var blockIndex = 0;
    var coordWidth = 0.0;
    var coordHeight = 0.0;

    for (final page in pages) {
      final pageJson = page as Map<String, dynamic>;
      final imageWidth = (pageJson['width'] as num?)?.toDouble() ?? 1.0;
      final imageHeight = (pageJson['height'] as num?)?.toDouble() ?? 1.0;
      final rawBlocks = pageJson['blocks'] as List<dynamic>? ?? const [];

      if (coordWidth == 0.0) {
        coordWidth = imageWidth;
        coordHeight = imageHeight;
      }

      for (final block in rawBlocks) {
        final blockJson = block as Map<String, dynamic>;
        final paragraphs =
            blockJson['paragraphs'] as List<dynamic>? ?? const [];

        for (final paragraph in paragraphs) {
          final paraJson = paragraph as Map<String, dynamic>;
          final text = _extractParagraphText(paraJson);
          if (text.isEmpty) continue;

          final boundingBox = _parseBoundingBox(
            paraJson['boundingBox'] as Map<String, dynamic>?,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
          );
          if (boundingBox == null) continue;

          blockIndex++;
          final itemId = 'box_${blockIndex.toString().padLeft(3, '0')}';

          ocrBlocks.add(
            OcrTextBlock(
              itemId: itemId,
              rawText: text,
              boundingBox: boundingBox,
            ),
          );
        }
      }
    }

    if (ocrBlocks.isEmpty) return null;

    return OcrResult(
      fullText: ocrBlocks.map((block) => block.rawText).join('\n'),
      blocks: ocrBlocks,
      strategy: OcrExtractionStrategy.blocks,
      imageWidth: coordWidth,
      imageHeight: coordHeight,
    );
  }

  static String _extractParagraphText(Map<String, dynamic> paragraphJson) {
    final words = paragraphJson['words'] as List<dynamic>? ?? const [];
    final wordTexts = <String>[];

    for (final word in words) {
      final wordText = _extractWordText(word as Map<String, dynamic>);
      if (wordText.isNotEmpty) {
        wordTexts.add(wordText);
      }
    }

    return wordTexts.join(' ').trim();
  }

  static String _extractWordText(Map<String, dynamic> wordJson) {
    final symbols = wordJson['symbols'] as List<dynamic>? ?? const [];
    final buffer = StringBuffer();

    for (final symbol in symbols) {
      final text = (symbol as Map<String, dynamic>)['text'] as String? ?? '';
      if (text.isNotEmpty) {
        buffer.write(text);
      }
    }

    return buffer.toString().trim();
  }

  static OcrBoundingBox? _parseBoundingBox(
    Map<String, dynamic>? json, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (json == null) return null;

    final vertices = json['vertices'] as List<dynamic>?;
    if (vertices != null && vertices.length == 4) {
      final offsets = vertices.map((vertex) {
        final map = vertex as Map<String, dynamic>;
        return Offset(
          (map['x'] as num? ?? 0).toDouble(),
          (map['y'] as num? ?? 0).toDouble(),
        );
      }).toList();

      return OcrBoundingBox(vertices: offsets);
    }

    final normalized = json['normalizedVertices'] as List<dynamic>?;
    if (normalized != null && normalized.length == 4) {
      final offsets = normalized.map((vertex) {
        final map = vertex as Map<String, dynamic>;
        return Offset(
          (map['x'] as num? ?? 0).toDouble() * imageWidth,
          (map['y'] as num? ?? 0).toDouble() * imageHeight,
        );
      }).toList();

      return OcrBoundingBox(vertices: offsets);
    }

    return null;
  }
}

class VisionApiException implements Exception {
  const VisionApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
