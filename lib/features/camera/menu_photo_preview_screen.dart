import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/ocr/ocr_result.dart';
import '../../core/ocr/vision_api_client.dart';
import 'ocr_result_screen.dart';
import 'photo_quality_analyzer.dart';

class MenuPhotoPreviewScreen extends StatefulWidget {
  const MenuPhotoPreviewScreen({super.key, required this.photo});

  final XFile photo;

  @override
  State<MenuPhotoPreviewScreen> createState() => _MenuPhotoPreviewScreenState();
}

class _MenuPhotoPreviewScreenState extends State<MenuPhotoPreviewScreen> {
  late final Future<_PreviewData> _previewDataFuture;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _previewDataFuture = _loadPreviewData();
  }

  Future<_PreviewData> _loadPreviewData() async {
    final bytes = await widget.photo.readAsBytes();
    final quality = PhotoQualityAnalyzer.analyze(bytes);

    return _PreviewData(bytes: bytes, quality: quality);
  }

  Future<void> _startOcr(Uint8List imageBytes) async {
    setState(() => _isAnalyzing = true);

    try {
      final OcrResult result = await VisionApiClient.extractText(imageBytes);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(
            imageBytes: imageBytes,
            ocrResult: result,
          ),
        ),
      );
    } on VisionApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('알 수 없는 오류가 발생했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<_PreviewData>(
        future: _previewDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final preview = snapshot.data!;
          final quality = preview.quality;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.memory(preview.bytes, fit: BoxFit.contain),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 16,
                child: _QualityBanner(quality: quality),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isAnalyzing ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('다시 촬영'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: quality.isTooBlurry || _isAnalyzing
                            ? null
                            : () => _startOcr(preview.bytes),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF06292),
                          disabledBackgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white54,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('이 사진 사용'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QualityBanner extends StatelessWidget {
  const _QualityBanner({required this.quality});

  final PhotoQualityResult quality;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (quality.isTooBlurry) {
      color = const Color(0xFFEF5350);
      icon = Icons.error_outline;
    } else if (quality.isLikelyBlurry) {
      color = const Color(0xFFFFD54F);
      icon = Icons.warning_amber;
    } else {
      color = const Color(0xFF81C784);
      icon = Icons.check_circle;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quality.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quality.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewData {
  const _PreviewData({required this.bytes, required this.quality});

  final Uint8List bytes;
  final PhotoQualityResult quality;
}
