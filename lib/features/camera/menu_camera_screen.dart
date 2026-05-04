import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'menu_photo_preview_screen.dart';

class MenuCameraScreen extends StatefulWidget {
  const MenuCameraScreen({super.key});

  @override
  State<MenuCameraScreen> createState() => _MenuCameraScreenState();
}

class _MenuCameraScreenState extends State<MenuCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  bool _isPressingShutter = false;
  String? _errorMessage;

  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = '사용 가능한 카메라를 찾을 수 없어요.';
          _isInitializing = false;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.description ?? '카메라를 시작할 수 없어요.';
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '카메라를 시작할 수 없어요.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MenuPhotoPreviewScreen(photo: photo),
        ),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.description ?? '사진을 촬영할 수 없어요.')),
      );
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  void _setShutterPressed(bool isPressed) {
    if (_isTakingPicture || _isPressingShutter == isPressed) {
      return;
    }
    setState(() => _isPressingShutter = isPressed);
  }

  Future<void> _onShutterTap() async {
    _setShutterPressed(false);
    await HapticFeedback.selectionClick();
    await _takePicture();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────────────
          Positioned.fill(
            child: _isInitializing
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : controller == null || !controller.value.isInitialized
                ? _CameraError(message: _errorMessage)
                : CameraPreview(controller),
          ),

          // ── Top gradient overlay ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topPad + 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom gradient overlay ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomPad + 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar: close + title ───────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: topPad + 4,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                  iconSize: 26,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '메뉴판 촬영',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance close button
              ],
            ),
          ),

          // ── Viewfinder brackets ──────────────────────────────────────
          Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.82,
              height: MediaQuery.sizeOf(context).width * 0.82 * 0.62,
              child: Stack(
                children: [
                  // Scan line
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (_, __) => Positioned(
                      left: 12,
                      right: 12,
                      top: _scanAnim.value *
                          (MediaQuery.sizeOf(context).width * 0.82 * 0.62 -
                              24),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFF06292),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                  // Corners
                  const _Corner(top: true, left: true),
                  const _Corner(top: true, left: false),
                  const _Corner(top: false, left: true),
                  const _Corner(top: false, left: false),
                ],
              ),
            ),
          ),

          // ── Hint text below viewfinder ───────────────────────────────
          Align(
            alignment: const Alignment(0, 0.38),
            child: Text(
              '메뉴판 전체가 프레임 안에 들어오게 맞춰주세요',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),

          // ── Bottom: shutter button ───────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '글자가 선명하게 보일 때 촬영하세요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTapDown: _isTakingPicture
                      ? null
                      : (_) => _setShutterPressed(true),
                  onTapCancel: _isTakingPicture
                      ? null
                      : () => _setShutterPressed(false),
                  onTapUp: _isTakingPicture
                      ? null
                      : (_) => _setShutterPressed(false),
                  onTap: _isTakingPicture ? null : _onShutterTap,
                  child: AnimatedScale(
                    scale: _isTakingPicture
                        ? 0.88
                        : _isPressingShutter
                        ? 0.94
                        : 1.0,
                    duration: const Duration(milliseconds: 140),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF06292),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF06292)
                                .withValues(alpha: _isPressingShutter ? 0.58 : 0.40),
                            blurRadius: _isPressingShutter ? 24 : 18,
                            spreadRadius: _isPressingShutter ? 4 : 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isTakingPicture
                              ? Colors.white54
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner bracket widget ──────────────────────────────────────────────────
class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const double len = 22;
    const double thick = 3.0;
    const Color color = Color(0xFFF06292);
    const radius = BorderRadius.all(Radius.circular(2));

    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: SizedBox(
        width: len,
        height: len,
        child: Stack(
          children: [
            // Horizontal arm
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: len,
                height: thick,
                decoration: const BoxDecoration(
                  color: color,
                  borderRadius: radius,
                ),
              ),
            ),
            // Vertical arm
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: thick,
                height: len,
                decoration: const BoxDecoration(
                  color: color,
                  borderRadius: radius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message ?? '카메라를 사용할 수 없어요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
