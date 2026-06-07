import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _minimumGalleryPreviewLoadingDuration = Duration(seconds: 3);

  late final Future<_PreviewData> _previewDataFuture;
  bool _isAnalyzing = false;

  bool get _isBusy => _isAnalyzing;
  String get _retryLabel =>
      widget.source == MenuPhotoSource.gallery ? '다시 선택' : '다시 촬영';

  @override
  void initState() {
    super.initState();
    _previewDataFuture = _loadPreviewData();
  }

  Future<_PreviewData> _loadPreviewData() async {
    final startedAt = DateTime.now();
    final sourceBytes = await widget.photo.readAsBytes();
    if (widget.source == MenuPhotoSource.camera) {
      return _buildPreviewData(sourceBytes);
    }

    final preview = await compute(
      _buildGalleryPreviewData,
      sourceBytes,
      debugLabel: 'menu_photo_preview',
    );
    await _waitForMinimum(startedAt, _minimumGalleryPreviewLoadingDuration);
    return preview;
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
            return widget.source == MenuPhotoSource.gallery
                ? const _GalleryPhotoLoadingView()
                : const Center(
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
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_retryLabel),
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
            ],
          );
        },
      ),
    );
  }
}

class _GalleryPhotoLoadingView extends StatefulWidget {
  const _GalleryPhotoLoadingView();

  @override
  State<_GalleryPhotoLoadingView> createState() =>
      _GalleryPhotoLoadingViewState();
}

class _GalleryPhotoLoadingViewState extends State<_GalleryPhotoLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1920),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: child,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GalleryObserveImage(),
              const SizedBox(height: 24),
              _GalleryLoadingText(animation: _controller),
              const SizedBox(height: 8),
              const Text(
                '잠시만 기다려 주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryLoadingText extends StatelessWidget {
  const _GalleryLoadingText({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final visibleDots = (animation.value * 4).floor().clamp(0, 3);
        return Text.rich(
          TextSpan(
            text: '갤러리에서 사진 불러오는 중',
            children: [
              for (var i = 0; i < 3; i++)
                TextSpan(
                  text: ' .',
                  style: TextStyle(
                    color: i < visibleDots ? Colors.white : Colors.transparent,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.35,
            letterSpacing: 0.1,
          ),
        );
      },
    );
  }
}

class _GalleryObserveImage extends StatelessWidget {
  const _GalleryObserveImage();

  static const double _aspectRatio = 480 / 410;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.80;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Image.asset(
          'assets/images/gallery_observe_static.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
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
