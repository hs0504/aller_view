import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/language_data.dart';
import '../../core/storage/user_prefs.dart';
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
  String _departureLanguage = 'ja';
  String? _errorMessage;

  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadLanguageSettings();
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
      debugPrint('카메라 초기화 오류: ${error.code} ${error.description}');
      setState(() {
        _errorMessage =
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

  Future<void> _loadLanguageSettings() async {
    final settings = await UserPrefs.loadLanguageSettings();
    if (!mounted) return;
    setState(() {
      _departureLanguage = settings.departure;
    });
  }

  Future<void> _saveDepartureLanguage(String code) async {
    await UserPrefs.saveLanguageSettings(departureLanguage: code);
    if (!mounted) return;
    setState(() {
      _departureLanguage = code;
    });
  }

  Future<void> _showLanguagePicker() async {
    if (_isTakingPicture) return;

    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CameraLanguageSheet(selectedCode: _departureLanguage),
    );

    if (!mounted || selectedCode == null) return;
    await _saveDepartureLanguage(selectedCode);
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
      debugPrint('사진 촬영 오류: ${error.code} ${error.description}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uc0ac\uc9c4\uc744 \ucd2c\uc601\ud560 \uc218 \uc5c6\uc5b4\uc694. \ub2e4\uc2dc \uc2dc\ub3c4\ud574 \uc8fc\uc138\uc694.',
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
    const dockHeight = 158.0;
    final frameTop = topPad + 82;
    final frameBottom = bottomPad + dockHeight;
    final availableFrameHeight = mediaSize.height - frameTop - frameBottom;
    final frameHeight = math.max(0.0, availableFrameHeight);

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
              child: _CameraTopBar(
                departureCode: _departureLanguage,
                onClose: () => Navigator.pop(context),
                onLanguageTap: _showLanguagePicker,
              ),
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
  const _CameraTopBar({
    required this.departureCode,
    required this.onClose,
    required this.onLanguageTap,
  });

  final String departureCode;
  final VoidCallback onClose;
  final VoidCallback onLanguageTap;

  LanguageOption _findOption(String code) {
    return departureLanguageOptions.firstWhere(
      (option) => option.code == code,
      orElse: () => departureLanguageOptions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final departure = _findOption(departureCode);

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _GlassIconButton(
              icon: Icons.close_rounded,
              onPressed: onClose,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
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
          Align(
            alignment: Alignment.centerRight,
            child: _TopLanguageChip(departure: departure, onTap: onLanguageTap),
          ),
        ],
      ),
    );
  }
}

class _TopLanguageChip extends StatelessWidget {
  const _TopLanguageChip({required this.departure, required this.onTap});

  final LanguageOption departure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 122),
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(departure.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    departure.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: GestureDetector(
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
              width: 84,
              height: 84,
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
      ),
    );
  }
}

class _CameraLanguageSheet extends StatelessWidget {
  const _CameraLanguageSheet({required this.selectedCode});

  final String selectedCode;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '메뉴판 언어 변경',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '촬영할 메뉴판의 언어를 선택해 주세요. 결과는 한국어로 표시돼요.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.48,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.92,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: departureLanguageOptions.length,
              itemBuilder: (_, index) {
                final option = departureLanguageOptions[index];
                return _CameraLanguageOption(
                  option: option,
                  isSelected: option.code == selectedCode,
                  onTap: () => Navigator.pop(context, option.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraLanguageOption extends StatelessWidget {
  const _CameraLanguageOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF06292) : const Color(0xFFFFF8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(color: const Color(0xFFFCE4EC)),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFF06292).withValues(alpha: 0.24)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(option.flag, style: const TextStyle(fontSize: 25)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        option.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.76)
                              : Colors.black38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFFF06292),
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
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
