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

class _OcrResultScreenState extends State<OcrResultScreen> {
  static const _minimumStepOneDuration = Duration(milliseconds: 600);
  static const _minimumStepTwoDuration = Duration(milliseconds: 850);
  static const _minimumStepThreeDuration = Duration(milliseconds: 1200);
  static const _minimumStepFourDuration = Duration(milliseconds: 700);
  static const _analysisTimeout = Duration(seconds: 30);

  String? _errorMessage;
  bool _returnToCameraOnError = false;
  bool _isPreviewComplete = false;
  int _currentStep = 1;
  String _statusMessage = '촬영한 이미지를 선명하게 정리하고 있어요.';

  @override
  void initState() {
    super.initState();
    _startFlow();
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
      setState(() {
        _currentStep = 2;
        _statusMessage = '사진 속 메뉴 이름과 설명을 읽고 있어요.';
      });

      final stepTwoStartedAt = DateTime.now();
      final OcrResult ocrResult;
      try {
        ocrResult = await VisionApiClient.extractText(widget.imageBytes);
      } on VisionApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.message;
          _returnToCameraOnError = true;
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
      setState(() {
        _currentStep = 3;
        _statusMessage = '알레르기와 취향 설정을 반영하고 있어요.';
      });
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

      setState(() {
        _currentStep = 4;
        _statusMessage = '메뉴판 위에 분석 결과를 배치하고 있어요.';
      });

      final stepFourStartedAt = DateTime.now();
      await _waitForMinimum(stepFourStartedAt, _minimumStepFourDuration);
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

    setState(() {
      _currentStep = 2;
      _statusMessage = '사진 속 메뉴 이름과 설명을 읽고 있어요.';
    });

    final stepTwoStartedAt = DateTime.now();
    await _waitForMinimum(stepTwoStartedAt, _minimumStepTwoDuration);
    if (!mounted) return;

    setState(() {
      _currentStep = 3;
      _statusMessage = '알레르기와 취향 설정을 반영하고 있어요.';
    });

    final stepThreeStartedAt = DateTime.now();
    await _waitForMinimum(stepThreeStartedAt, _minimumStepThreeDuration);
    if (!mounted) return;

    setState(() {
      _currentStep = 4;
      _statusMessage = '메뉴판 위에 분석 결과를 배치하고 있어요.';
    });

    final stepFourStartedAt = DateTime.now();
    await _waitForMinimum(stepFourStartedAt, _minimumStepFourDuration);
    if (!mounted) return;

    setState(() {
      _currentStep = 5;
      _isPreviewComplete = true;
      _statusMessage = '로딩 화면 테스트가 완료되었습니다.';
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
      return error.message;
    }
    return error.toString();
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
                color: Colors.black.withValues(alpha: 0.64),
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
                    Color(0x66121212),
                    Color(0xE6121212),
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
                    ? _LoadingBody(
                        currentStep: _currentStep,
                        statusMessage: _statusMessage,
                        isPreviewComplete: _isPreviewComplete,
                        onPreviewClose: widget.previewOnly
                            ? () => Navigator.pop(context)
                            : null,
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
    this.onPreviewClose,
  });

  final int currentStep;
  final String statusMessage;
  final bool isPreviewComplete;
  final VoidCallback? onPreviewClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
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
                child: isPreviewComplete
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFFF06292),
                        size: 34,
                      )
                    : const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF06292),
                          strokeWidth: 3,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Text(
                '메뉴를 분석하고 있습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                statusMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _StepTile(
                label: '메뉴판 확인',
                description: '촬영한 이미지를 선명하게 정리하고 있어요.',
                state: currentStep > 1
                    ? _StepState.completed
                    : _StepState.active,
              ),
              const SizedBox(height: 12),
              _StepTile(
                label: '메뉴 글자 인식',
                description: '사진 속 메뉴 이름과 설명을 읽고 있어요.',
                state: currentStep > 2
                    ? _StepState.completed
                    : currentStep == 2
                    ? _StepState.active
                    : _StepState.pending,
              ),
              const SizedBox(height: 12),
              _StepTile(
                label: '맞춤 분석',
                description: '알레르기와 취향 설정을 반영하고 있어요.',
                state: currentStep > 3
                    ? _StepState.completed
                    : currentStep == 3
                    ? _StepState.active
                    : _StepState.pending,
              ),
              const SizedBox(height: 12),
              _StepTile(
                label: '결과 표시 준비',
                description: '메뉴판 위에 분석 결과를 배치하고 있어요.',
                state: currentStep > 4
                    ? _StepState.completed
                    : currentStep == 4
                    ? _StepState.active
                    : _StepState.pending,
              ),
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
    );
  }
}

enum _StepState { completed, active, pending }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.label,
    required this.description,
    required this.state,
  });

  final String label;
  final String description;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _StepState.completed;
    final isActive = state == _StepState.active;
    final accent = isCompleted
        ? const Color(0xFF81C784)
        : isActive
        ? const Color(0xFFF06292)
        : Colors.white24;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? accent : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accent.withValues(
                  alpha: isCompleted || isActive ? 0.18 : 0.12,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Color(0xFF81C784),
                    )
                  : isActive
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF06292),
                      ),
                    )
                  : const Icon(
                      Icons.more_horiz_rounded,
                      size: 15,
                      color: Colors.white38,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
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
