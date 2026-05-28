import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/analyze_menu_client.dart';
import '../../core/ocr/ocr_result.dart';
import '../../core/ocr/vision_api_client.dart';
import '../../core/storage/user_prefs.dart';
import 'menu_image_normalizer.dart';
import 'ocr_result_screen.dart';
import 'photo_quality_analyzer.dart';

enum MenuPhotoSource { camera, gallery }

const int _galleryPreviewMaxLongSide = 2200;

_PreviewData _buildPreviewData(Uint8List sourceBytes, {int? maxLongSide}) {
  final normalized = MenuImageNormalizer.normalize(
    sourceBytes,
    maxLongSide: maxLongSide,
  );
  final quality = PhotoQualityAnalyzer.analyze(normalized.bytes);

  return _PreviewData(
    bytes: normalized.bytes,
    quality: quality,
    imageWidth: normalized.width,
    imageHeight: normalized.height,
  );
}

_PreviewData _buildGalleryPreviewData(Uint8List sourceBytes) {
  return _buildPreviewData(
    sourceBytes,
    maxLongSide: _galleryPreviewMaxLongSide,
  );
}

class MenuPhotoPreviewScreen extends StatefulWidget {
  const MenuPhotoPreviewScreen({
    super.key,
    required this.photo,
    this.source = MenuPhotoSource.camera,
  });

  final XFile photo;
  final MenuPhotoSource source;

  @override
  State<MenuPhotoPreviewScreen> createState() => _MenuPhotoPreviewScreenState();
}

class _MenuPhotoPreviewScreenState extends State<MenuPhotoPreviewScreen> {
  static const _minimumProcessingOverlayDuration = Duration(milliseconds: 450);

  late final Future<_PreviewData> _previewDataFuture;
  bool _isAnalyzing = false;
  bool _isTestingApi = false;
  bool _isPreviewingLoading = false;

  bool get _isBusy => _isAnalyzing || _isTestingApi || _isPreviewingLoading;
  String get _retryLabel =>
      widget.source == MenuPhotoSource.gallery ? '다시 선택' : '다시 촬영';

  @override
  void initState() {
    super.initState();
    _previewDataFuture = _loadPreviewData();
  }

  Future<_PreviewData> _loadPreviewData() async {
    final sourceBytes = await widget.photo.readAsBytes();
    if (widget.source == MenuPhotoSource.camera) {
      return _buildPreviewData(sourceBytes);
    }

    return compute(
      _buildGalleryPreviewData,
      sourceBytes,
      debugLabel: 'menu_photo_preview',
    );
  }

  Future<void> _startOcr(
    Uint8List imageBytes, {
    required double imageWidth,
    required double imageHeight,
  }) async {
    setState(() => _isAnalyzing = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(
            imageBytes: imageBytes,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showError('예상하지 못한 오류가 발생했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _previewLoadingScreen(
    Uint8List imageBytes, {
    required double imageWidth,
    required double imageHeight,
  }) async {
    setState(() => _isPreviewingLoading = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(
            imageBytes: imageBytes,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            previewOnly: true,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPreviewingLoading = false);
      }
    }
  }

  Future<void> _startApiJsonTest(Uint8List imageBytes) async {
    setState(() => _isTestingApi = true);
    final startedAt = DateTime.now();

    try {
      final OcrResult result = await VisionApiClient.extractText(imageBytes);
      final settings = await UserPrefs.loadLanguageSettings();
      final allergyIndices = await UserPrefs.loadAllergyIndices();
      final preferenceScores = await UserPrefs.loadPreferenceScores();
      final userAllergies = UserPrefs.allergyNamesFromIndices(allergyIndices);
      final userPreferences = UserPrefs.preferenceScoresToEn(preferenceScores);

      final exchange = await AnalyzeMenuClient.analyzeMenuRaw(
        result.blocks,
        departureLanguage: settings.departure,
        arrivalLanguage: settings.arrival,
        userAllergies: userAllergies,
        userPreferences: userPreferences,
      );

      if (!mounted) return;
      await _waitForMinimum(startedAt, _minimumProcessingOverlayDuration);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ApiJsonTestSheet(exchange: exchange),
      );
    } on VisionApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on AnalyzeMenuException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('JSON 테스트 중 오류가 발생했습니다. $e');
    } finally {
      if (mounted) {
        setState(() => _isTestingApi = false);
      }
    }
  }

  Future<void> _waitForMinimum(DateTime startedAt, Duration minimum) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = minimum - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isBusy
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_retryLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isBusy
                                ? null
                                : () async {
                                    await HapticFeedback.selectionClick();
                                    if (!mounted) return;
                                    await _startApiJsonTest(preview.bytes);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFD1DE),
                              disabledForegroundColor: Colors.white38,
                              side: const BorderSide(color: Color(0xFFFF8FB1)),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isTestingApi
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFD1DE),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.data_object_rounded,
                                    size: 18,
                                  ),
                            label: const Text(
                              'JSON 테스트',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isBusy
                                ? null
                                : () async {
                                    await HapticFeedback.selectionClick();
                                    if (!mounted) return;
                                    await _previewLoadingScreen(
                                      preview.bytes,
                                      imageWidth: preview.imageWidth,
                                      imageHeight: preview.imageHeight,
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white38,
                              side: const BorderSide(color: Colors.white70),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isPreviewingLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_circle_outline_rounded),
                            label: const Text(
                              '로딩화면 테스트',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: quality.isTooBlurry || _isBusy
                                ? null
                                : () async {
                                    await HapticFeedback.selectionClick();
                                    if (!mounted) return;
                                    await _startOcr(
                                      preview.bytes,
                                      imageWidth: preview.imageWidth,
                                      imageHeight: preview.imageHeight,
                                    );
                                  },
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
                  ],
                ),
              ),
              if (_isTestingApi)
                Positioned.fill(
                  child: _ProcessingOverlay(isTestingApi: _isTestingApi),
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

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.isTestingApi});

  final bool isTestingApi;

  @override
  Widget build(BuildContext context) {
    final title = isTestingApi ? '테스트 요청을 확인하고 있습니다' : '메뉴 글자 인식 중';
    final description = isTestingApi
        ? 'OCR과 AI 서버 응답을 함께 점검하는 중입니다.'
        : '사진 속 메뉴 이름과 설명을 읽고 있어요.';
    final stageLabel = isTestingApi ? '테스트 진행 중' : '메뉴 글자 인식';

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.56)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06292).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF06292),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.document_scanner_outlined,
                            color: Color(0xFFF06292),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stageLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewData {
  const _PreviewData({
    required this.bytes,
    required this.quality,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List bytes;
  final PhotoQualityResult quality;
  final double imageWidth;
  final double imageHeight;
}

class _ApiJsonTestSheet extends StatelessWidget {
  const _ApiJsonTestSheet({required this.exchange});

  final AnalyzeMenuRawExchange exchange;

  String get _prettyResponse {
    try {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(exchange.rawResponseBody));
    } catch (_) {
      return exchange.rawResponseBody.isEmpty
          ? '(empty response body)'
          : exchange.rawResponseBody;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = exchange.statusCode >= 200 && exchange.statusCode < 300;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI 서버 JSON 테스트',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isSuccess
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE53935))
                            .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'HTTP ${exchange.statusCode}',
                    style: TextStyle(
                      color: isSuccess
                          ? const Color(0xFF81C784)
                          : const Color(0xFFFF8A80),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _JsonDebugSection(title: '요청 URL', text: exchange.requestUrl),
            const SizedBox(height: 14),
            _JsonDebugSection(title: '요청 JSON', text: exchange.requestJson),
            const SizedBox(height: 14),
            _JsonDebugSection(title: '응답 JSON', text: _prettyResponse),
          ],
        ),
      ),
    );
  }
}

class _JsonDebugSection extends StatelessWidget {
  const _JsonDebugSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('복사되었습니다'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  tooltip: '복사',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              text,
              style: const TextStyle(
                color: Color(0xFFB5CEA8),
                fontSize: 12,
                height: 1.55,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
