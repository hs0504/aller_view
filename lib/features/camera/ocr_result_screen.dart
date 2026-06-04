import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/analyze_menu_client.dart';
import '../../core/api/analyze_menu_result.dart';
import '../../core/ocr/ocr_result.dart';
import '../../core/ocr/vision_api_client.dart';
import '../../core/storage/user_prefs.dart';
import 'overlay_result_screen.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    this.previewOnly = false,
  });

  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  final bool previewOnly;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen>
    with SingleTickerProviderStateMixin {
  static const _minimumStepOneDuration = Duration(milliseconds: 600);
  static const _minimumStepTwoDuration = Duration(milliseconds: 850);
  static const _minimumStepThreeDuration = Duration(milliseconds: 1200);
  static const _minimumStepFourDuration = Duration(milliseconds: 700);
  static const _completeHoldDuration = Duration(milliseconds: 450);
  static const _analysisTimeout = Duration(seconds: 30);

  late final AnimationController _loadingAnimation;
  late DateTime _activeStepStartedAt;
  String? _errorMessage;
  bool _returnToCameraOnError = false;
  bool _isPreviewComplete = false;
  int _currentStep = 1;
  String _statusMessage = '촬영한 이미지를 선명하게 정리하고 있어요.';

  @override
  void initState() {
    super.initState();
    _activeStepStartedAt = DateTime.now();
    _loadingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _startFlow();
  }

  @override
  void dispose() {
    _loadingAnimation.dispose();
    super.dispose();
  }

  Future<void> _startFlow() async {
    if (widget.previewOnly) {
      await _startPreviewFlow();
      return;
    }

    final stepOneStartedAt = DateTime.now();

    try {
      await _waitForMinimum(stepOneStartedAt, _minimumStepOneDuration);
      if (!mounted) return;
      _moveToStep(2, '사진 속 메뉴 이름과 설명을 읽고 있어요.');

      final stepTwoStartedAt = DateTime.now();
      final OcrResult ocrResult;
      try {
        ocrResult = await VisionApiClient.extractText(widget.imageBytes);
      } on VisionApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.userMessage;
          _returnToCameraOnError = error.returnToCamera;
        });
        return;
      }

      if (ocrResult.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = '텍스트를 인식하지 못했습니다. 메뉴가 잘 보이도록 다시 촬영해 주세요.';
          _returnToCameraOnError = true;
        });
        return;
      }

      final settings = await UserPrefs.loadLanguageSettings();
      final allergyIndices = await UserPrefs.loadAllergyIndices();
      final preferenceScores = await UserPrefs.loadPreferenceScores();
      final userAllergies = UserPrefs.allergyNamesFromIndices(allergyIndices);
      final userPreferences = UserPrefs.preferenceScoresToEn(preferenceScores);
      final blocks = ocrResult.blocks;

      await _waitForMinimum(stepTwoStartedAt, _minimumStepTwoDuration);
      if (!mounted) return;
      _moveToStep(3, '알레르기와 취향 설정을 반영하고 있어요.');
      final stepThreeStartedAt = DateTime.now();

      final AnalyzeMenuResponse response;

      try {
        response =
            await AnalyzeMenuClient.analyzeMenu(
              blocks,
              departureLanguage: settings.departure,
              arrivalLanguage: settings.arrival,
              userAllergies: userAllergies,
              userPreferences: userPreferences,
            ).timeout(
              _analysisTimeout,
              onTimeout: () => throw const AnalyzeMenuException(
                '\ubd84\uc11d \uc694\uccad\uc774 30\ucd08 \uc548\uc5d0 \uc644\ub8cc\ub418\uc9c0 \uc54a\uc558\uc2b5\ub2c8\ub2e4. \uba54\uc778 \ud654\uba74\uc73c\ub85c \ub3cc\uc544\uac00 \ub2e4\uc2dc \uc2dc\ub3c4\ud574 \uc8fc\uc138\uc694.',
                userMessage: '분석이 예상보다 오래 걸리고 있어요. 잠시 후 다시 시도해 주세요.',
              ),
            );
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = _errorMessageFrom(error);
          _returnToCameraOnError =
              error is AnalyzeMenuException && error.returnToCamera;
        });
        return;
      }

      await _waitForMinimum(stepThreeStartedAt, _minimumStepThreeDuration);
      if (!mounted) return;

      _moveToStep(4, '메뉴판 위에 분석 결과를 배치하고 있어요.');

      final stepFourStartedAt = DateTime.now();
      await _waitForMinimum(stepFourStartedAt, _minimumStepFourDuration);
      if (!mounted) return;

      _moveToStep(5, '분석이 완료되었습니다.');
      await Future<void>.delayed(_completeHoldDuration);
      if (!mounted) return;

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OverlayResultScreen(
            imageBytes: widget.imageBytes,
            displayImageWidth: widget.imageWidth,
            displayImageHeight: widget.imageHeight,
            ocrResult: ocrResult,
            response: response,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '분석을 준비하는 중 문제가 발생했습니다. 이전 화면으로 돌아가 다시 시도해 주세요.';
        _returnToCameraOnError = false;
      });
    }
  }

  Future<void> _startPreviewFlow() async {
    final stepOneStartedAt = DateTime.now();
    await _waitForMinimum(stepOneStartedAt, _minimumStepOneDuration);
    if (!mounted) return;

    _moveToStep(2, '사진 속 메뉴 이름과 설명을 읽고 있어요.');

    final stepTwoStartedAt = DateTime.now();
    await _waitForMinimum(stepTwoStartedAt, _minimumStepTwoDuration);
    if (!mounted) return;

    _moveToStep(3, '알레르기와 취향 설정을 반영하고 있어요.');

    final stepThreeStartedAt = DateTime.now();
    await _waitForMinimum(stepThreeStartedAt, _minimumStepThreeDuration);
    if (!mounted) return;

    _moveToStep(4, '메뉴판 위에 분석 결과를 배치하고 있어요.');

    final stepFourStartedAt = DateTime.now();
    await _waitForMinimum(stepFourStartedAt, _minimumStepFourDuration);
    if (!mounted) return;

    setState(() {
      _currentStep = 5;
      _activeStepStartedAt = DateTime.now();
      _isPreviewComplete = true;
      _statusMessage = '로딩 화면 테스트가 완료되었습니다.';
    });
  }

  void _moveToStep(int step, String message) {
    setState(() {
      _currentStep = step;
      _activeStepStartedAt = DateTime.now();
      _statusMessage = message;
    });
  }

  Future<void> _waitForMinimum(DateTime startedAt, Duration minimum) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = minimum - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  String _errorMessageFrom(Object error) {
    if (error is AnalyzeMenuException) {
      return error.userMessage;
    }
    return '분석 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
  }

  void _handleErrorAction() {
    final navigator = Navigator.of(context);
    if (_returnToCameraOnError) {
      var pops = 0;
      navigator.popUntil((route) {
        pops++;
        return pops > 2 || route.isFirst;
      });
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  double _loadingProgress() {
    if (_currentStep >= 5) return 1;

    final range = switch (_currentStep) {
      1 => (start: 0.04, end: 0.18, duration: _minimumStepOneDuration),
      2 => (
        start: 0.18,
        end: 0.45,
        duration: const Duration(milliseconds: 4500),
      ),
      3 => (
        start: 0.45,
        end: 0.90,
        duration: const Duration(milliseconds: 18000),
      ),
      4 => (start: 0.90, end: 0.98, duration: _minimumStepFourDuration),
      _ => (start: 0.04, end: 0.18, duration: _minimumStepOneDuration),
    };

    final elapsed = DateTime.now().difference(_activeStepStartedAt);
    final rawLocal =
        elapsed.inMilliseconds /
        range.duration.inMilliseconds.clamp(1, 1 << 31);
    final local = _heldProgress(rawLocal.clamp(0.0, 1.0));
    return range.start + (range.end - range.start) * local;
  }

  double _activeStepProgress() {
    if (_currentStep >= 5) return 1;

    final duration = switch (_currentStep) {
      1 => _minimumStepOneDuration,
      2 => const Duration(milliseconds: 4500),
      3 => const Duration(milliseconds: 18000),
      4 => _minimumStepFourDuration,
      _ => _minimumStepOneDuration,
    };
    final elapsed = DateTime.now().difference(_activeStepStartedAt);
    final rawLocal =
        elapsed.inMilliseconds / duration.inMilliseconds.clamp(1, 1 << 31);
    return _heldProgress(rawLocal.clamp(0.0, 1.0)).clamp(0.08, 0.96);
  }

  double _heldProgress(double value) {
    final eased = Curves.easeOutCubic.transform(value.clamp(0.0, 1.0));
    if (eased < 0.34) return eased;
    if (eased < 0.42) return 0.34 + (eased - 0.34) * 0.18;
    if (eased < 0.67) return eased - 0.065;
    if (eased < 0.76) return 0.605 + (eased - 0.67) * 0.20;
    return (eased - 0.135).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF25272D).withValues(alpha: 0.52),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE84A4D55),
                    Color(0xEF34363C),
                    Color(0xF426282E),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: _errorMessage == null
                    ? AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, _) => _LoadingBody(
                          currentStep: _currentStep,
                          statusMessage: _statusMessage,
                          isPreviewComplete: _isPreviewComplete,
                          progress: _loadingProgress(),
                          activeStepProgress: _activeStepProgress(),
                          flowValue: _loadingAnimation.value,
                          onPreviewClose: widget.previewOnly
                              ? () => Navigator.pop(context)
                              : null,
                        ),
                      )
                    : _ErrorBody(
                        message: _errorMessage!,
                        buttonLabel: _returnToCameraOnError
                            ? '다시 촬영'
                            : '이전 화면으로',
                        onPressed: _handleErrorAction,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    required this.currentStep,
    required this.statusMessage,
    required this.isPreviewComplete,
    required this.progress,
    required this.activeStepProgress,
    required this.flowValue,
    this.onPreviewClose,
  });

  final int currentStep;
  final String statusMessage;
  final bool isPreviewComplete;
  final double progress;
  final double activeStepProgress;
  final double flowValue;
  final VoidCallback? onPreviewClose;

  static const _steps = [
    _LoadingStep(icon: Icons.image_search_rounded, title: '사진을 정리하고 있어요'),
    _LoadingStep(icon: Icons.text_fields_rounded, title: '메뉴 글자를 읽고 있어요'),
    _LoadingStep(icon: Icons.health_and_safety_rounded, title: '알레르기 정보를 확인해요'),
    _LoadingStep(icon: Icons.auto_awesome_rounded, title: '결과 표시를 준비해요'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = currentStep >= 5 ? _steps.length - 1 : currentStep - 1;
    final boundedActiveIndex = activeIndex.clamp(0, _steps.length - 1);
    final activeStep = _steps[boundedActiveIndex];
    final mascotLift = math.sin(flowValue * math.pi * 2) * 4.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3D45).withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, mascotLift),
                  child: const _GalleryMascotImage(),
                ),
                const SizedBox(height: 12),
                const Text(
                  '메뉴판을 분석하고 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPreviewComplete ? '분석 결과를 확인할 준비가 끝났어요.' : statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _ProgressSummary(
                  progress: progress,
                  activeStep: activeStep,
                  flowValue: flowValue,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _steps.length; i++) ...[
                  _LoadingStepTile(
                    step: _steps[i],
                    state: _stateFor(i),
                    localProgress: i == boundedActiveIndex
                        ? activeStepProgress
                        : i < boundedActiveIndex || currentStep >= 5
                        ? 1
                        : 0,
                  ),
                  if (i != _steps.length - 1) const SizedBox(height: 7),
                ],
                if (onPreviewClose != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isPreviewComplete ? onPreviewClose : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                        side: BorderSide(
                          color: isPreviewComplete
                              ? Colors.white54
                              : Colors.white24,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('미리보기 닫기'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StepState _stateFor(int index) {
    if (currentStep >= 5 || index < currentStep - 1) {
      return _StepState.completed;
    }
    if (index == currentStep - 1) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { completed, active, pending }

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.progress,
    required this.activeStep,
    required this.flowValue,
  });

  final double progress;
  final _LoadingStep activeStep;
  final double flowValue;

  @override
  Widget build(BuildContext context) {
    final displayProgress = progress.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activeStep.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(displayProgress * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFFF06292),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _FlowingProgressBar(progress: displayProgress, flowValue: flowValue),
      ],
    );
  }
}

class _FlowingProgressBar extends StatelessWidget {
  const _FlowingProgressBar({required this.progress, required this.flowValue});

  final double progress;
  final double flowValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = math.max(
                0.0,
                constraints.maxWidth * progress.clamp(0.0, 1.0),
              );
              final waveWidth = math.max(54.0, fillWidth * 0.72);
              final waveLeft = -waveWidth + (fillWidth + waveWidth) * flowValue;

              return Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: fillWidth,
                      height: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFFFE4EC),
                                    Color(0xFFFFB8CC),
                                    Color(0xFFF48FB1),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: waveLeft,
                              top: 0,
                              bottom: 0,
                              width: waveWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.00),
                                      Colors.white.withValues(alpha: 0.36),
                                      Colors.white.withValues(alpha: 0.00),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingStepTile extends StatelessWidget {
  const _LoadingStepTile({
    required this.step,
    required this.state,
    required this.localProgress,
  });

  final _LoadingStep step;
  final _StepState state;
  final double localProgress;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _StepState.completed;
    final isActive = state == _StepState.active;
    final accent = isCompleted
        ? const Color(0xFF81C784)
        : isActive
        ? const Color(0xFFF06292)
        : Colors.white38;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFF06292).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF06292).withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF81C784),
                    )
                  : isActive
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: localProgress.clamp(0.08, 0.96),
                        strokeWidth: 2.4,
                        color: const Color(0xFFF06292),
                        backgroundColor: const Color(
                          0xFFF06292,
                        ).withValues(alpha: 0.16),
                      ),
                    )
                  : Icon(step.icon, size: 18, color: Colors.white38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive || isCompleted
                      ? Colors.white
                      : Colors.white54,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StepStateBadge(state: state, color: accent),
          ],
        ),
      ),
    );
  }
}

class _StepStateBadge extends StatelessWidget {
  const _StepStateBadge({required this.state, required this.color});

  final _StepState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      _StepState.completed => '완료',
      _StepState.active => '진행 중',
      _StepState.pending => '대기',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GalleryMascotImage extends StatelessWidget {
  const _GalleryMascotImage();

  static const double _aspectRatio = 480 / 410;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 168),
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

class _LoadingStep {
  const _LoadingStep({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF5350),
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(160, 48),
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
