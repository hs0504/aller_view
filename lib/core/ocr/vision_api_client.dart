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
    final annotations = responses.first['textAnnotations'] as List<dynamic>?;

    if (annotations == null || annotations.isEmpty) {
      return const OcrResult(fullText: '', lines: []);
    }

    final fullText = annotations.first['description'] as String;
    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return OcrResult(fullText: fullText, lines: lines);
  }
}

class VisionApiException implements Exception {
  const VisionApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
