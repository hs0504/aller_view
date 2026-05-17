import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/analyze_menu_client.dart';
import '../../core/api/analyze_menu_result.dart';
import '../../core/ocr/ocr_result.dart';
import '../../core/storage/user_prefs.dart';
import 'overlay_result_screen.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.ocrResult,
  });

  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  final OcrResult ocrResult;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  static const _minimumStepOneDuration = Duration(milliseconds: 850);
  static const _minimumStepTwoDuration = Duration(milliseconds: 1200);
  static const _minimumStepThreeDuration = Duration(milliseconds: 800);
  static const _analysisTimeout = Duration(seconds: 30);

  String? _errorMessage;
  int _currentStep = 1;
  String _statusMessage = '추출된 텍스트와 사용자 설정을 정리하고 있습니다.';

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    final stepOneStartedAt = DateTime.now();

    if (widget.ocrResult.isEmpty) {
      setState(() {
        _errorMessage = '텍스트를 인식하지 못했습니다. 메뉴가 잘 보이도록 다시 촬영해 주세요.';
      });
      return;
    }

    try {
      final settings = await UserPrefs.loadLanguageSettings();
      final allergyIndices = await UserPrefs.loadAllergyIndices();
      final preferenceScores = await UserPrefs.loadPreferenceScores();
      final userAllergies = UserPrefs.allergyNamesFromIndices(allergyIndices);
      final userPreferences = UserPrefs.preferenceScoresToEn(preferenceScores);
      final blocks = widget.ocrResult.blocks;

      await _waitForMinimum(stepOneStartedAt, _minimumStepOneDuration);
      if (!mounted) return;
      setState(() {
        _currentStep = 2;
        _statusMessage = '추천 메뉴와 알레르기 위험 분석을 요청하고 있습니다.';
      });
      final stepTwoStartedAt = DateTime.now();

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
        });
        return;
      }

      await _waitForMinimum(stepTwoStartedAt, _minimumStepTwoDuration);
      if (!mounted) return;

      setState(() {
        _currentStep = 3;
        _statusMessage = '오버레이 화면을 준비하고 있습니다.';
      });

      final stepThreeStartedAt = DateTime.now();
      await _waitForMinimum(stepThreeStartedAt, _minimumStepThreeDuration);
      if (!mounted) return;

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OverlayResultScreen(
            imageBytes: widget.imageBytes,
            displayImageWidth: widget.imageWidth,
            displayImageHeight: widget.imageHeight,
            ocrResult: widget.ocrResult,
            response: response,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '분석을 준비하는 중 문제가 발생했습니다. 이전 화면으로 돌아가 다시 시도해 주세요.';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _errorMessage == null
                  ? _LoadingBody(
                      currentStep: _currentStep,
                      statusMessage: _statusMessage,
                    )
                  : _ErrorBody(
                      message: _errorMessage!,
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.currentStep, required this.statusMessage});

  final int currentStep;
  final String statusMessage;

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
                child: const SizedBox(
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
                label: '결과 정리',
                description: '추출된 텍스트와 사용자 설정을 준비합니다.',
                state: currentStep > 1
                    ? _StepState.completed
                    : _StepState.active,
              ),
              const SizedBox(height: 12),
              _StepTile(
                label: '서버 분석 요청',
                description: '추천 메뉴와 알레르기 정보를 조회합니다.',
                state: currentStep > 2
                    ? _StepState.completed
                    : currentStep == 2
                    ? _StepState.active
                    : _StepState.pending,
              ),
              const SizedBox(height: 12),
              _StepTile(
                label: '오버레이 준비',
                description: '분석 결과를 화면 위에 표시할 준비를 합니다.',
                state: currentStep == 3
                    ? _StepState.active
                    : _StepState.pending,
              ),
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
  const _ErrorBody({required this.message, required this.onPressed});

  final String message;
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
                child: const Text('이전 화면으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
