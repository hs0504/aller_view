import 'dart:math' as math;

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
          _errorMessage =
              '\uc0ac\uc6a9 \uac00\ub2a5\ud55c \uce74\uba54\ub77c\ub97c \ucc3e\uc744 \uc218 \uc5c6\uc5b4\uc694';
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
        _errorMessage =
            error.description ??
            '\uce74\uba54\ub77c\ub97c \uc2dc\uc791\ud560 \uc218 \uc5c6\uc5b4\uc694';
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            '\uce74\uba54\ub77c\ub97c \uc2dc\uc791\ud560 \uc218 \uc5c6\uc5b4\uc694';
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
        MaterialPageRoute(builder: (_) => MenuPhotoPreviewScreen(photo: photo)),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.description ??
                '\uc0ac\uc9c4\uc744 \ucd2c\uc601\ud560 \uc218 \uc5c6\uc5b4\uc694',
          ),
        ),
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
    final mediaSize = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hasPreview =
        !_isInitializing &&
        controller != null &&
        controller.value.isInitialized;
    final topPad = padding.top;
    final bottomPad = padding.bottom;
    const horizontalInset = 18.0;
    const dockHeight = 168.0;
    final frameTop = topPad + 82;
    final frameBottom = bottomPad + dockHeight;
    final frameHeight = math.max(
      260.0,
      mediaSize.height - frameTop - frameBottom,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isInitializing
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : hasPreview
                ? CameraPreview(controller)
                : _CameraError(message: _errorMessage),
          ),
          if (hasPreview) ...[
            const Positioned.fill(
              child: IgnorePointer(child: _CameraAtmosphere()),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: topPad + 8,
              child: _CameraTopBar(onClose: () => Navigator.pop(context)),
            ),
            Positioned(
              left: horizontalInset,
              right: horizontalInset,
              top: frameTop,
              height: frameHeight,
              child: _GuideFrame(scanAnimation: _scanAnim),
            ),
            Positioned(
              left: horizontalInset + 12,
              right: horizontalInset + 12,
              top: frameTop + 18,
              child: const _GuideBanner(),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomPad + 20,
              child: _CaptureDock(
                isTakingPicture: _isTakingPicture,
                isPressingShutter: _isPressingShutter,
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CameraAtmosphere extends StatelessWidget {
  const _CameraAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.14, 0.34, 0.74, 1.0],
          colors: [
            const Color(0x660B1017),
            const Color(0x1C0B1017),
            Colors.transparent,
            const Color(0x140B1017),
            const Color(0x700B1017),
          ],
        ),
      ),
    );
  }
}

class _CameraTopBar extends StatelessWidget {
  const _CameraTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(icon: Icons.close_rounded, onPressed: onClose),
        Expanded(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Text(
                  '\uba54\ub274\ud310 \ucd2c\uc601',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _GuideFrame extends StatelessWidget {
  const _GuideFrame({required this.scanAnimation});

  final Animation<double> scanAnimation;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.015),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final travel = math.max(0.0, constraints.maxHeight - 132);
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.2, 0.74, 1.0],
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: scanAnimation,
                  builder: (_, __) => Positioned(
                    left: 18,
                    right: 18,
                    top: 72 + scanAnimation.value * travel,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFFF8FB1),
                            Color(0xFFFFD1DE),
                            Color(0xFFFF8FB1),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF06292,
                            ).withValues(alpha: 0.32),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const _FrameCorner(top: true, left: true),
                const _FrameCorner(top: true, left: false),
                const _FrameCorner(top: false, left: true),
                const _FrameCorner(top: false, left: false),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const double len = 28;
    const double thick = 3.5;
    const Color color = Color(0xFFFF8FB1);
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

class _GuideBanner extends StatelessWidget {
  const _GuideBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101822).withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF06292).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFFFFB6C9),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\uba54\ub274\ud310\uc774 \ud654\uba74 \uc548\uc5d0 \ud06c\uac8c \ubcf4\uc774\ub3c4\ub85d \ub9de\ucdb0\uc8fc\uc138\uc694',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\ud754\ub4e4\ub9bc \uc5c6\uc774 \uc7a0\uc2dc \uba48\ucd98 \ub4a4 \ucd2c\uc601\ud574\uc8fc\uc138\uc694.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.45,
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

class _CaptureDock extends StatelessWidget {
  const _CaptureDock({
    required this.isTakingPicture,
    required this.isPressingShutter,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTapUp,
    required this.onTap,
  });

  final bool isTakingPicture;
  final bool isPressingShutter;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback? onTapCancel;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1219).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\uae00\uc790\uac00 \uc120\uba85\ud558\uac8c \ubcf4\uc77c \ub54c \uc7a0\uc2dc \uba48\ucd98 \ub4a4 \ucd2c\uc601\ud574\uc8fc\uc138\uc694.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: onTapDown,
              onTapCancel: onTapCancel,
              onTapUp: onTapUp,
              onTap: onTap,
              child: AnimatedScale(
                scale: isTakingPicture
                    ? 0.9
                    : isPressingShutter
                    ? 0.95
                    : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.white30, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFF06292,
                        ).withValues(alpha: isPressingShutter ? 0.46 : 0.28),
                        blurRadius: isPressingShutter ? 28 : 20,
                        spreadRadius: isPressingShutter ? 5 : 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isTakingPicture ? Colors.white70 : Colors.white,
                          isTakingPicture
                              ? Colors.white54
                              : const Color(0xFFFFF4F7),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFF06292).withValues(alpha: 0.26),
                        width: 3,
                      ),
                    ),
                  ),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message ??
                  '\uce74\uba54\ub77c\ub97c \uc0ac\uc6a9\ud560 \uc218 \uc5c6\uc5b4\uc694',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
