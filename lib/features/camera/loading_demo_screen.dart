import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LoadingDemoScreen extends StatefulWidget {
  const LoadingDemoScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<LoadingDemoScreen> createState() => _LoadingDemoScreenState();
}

class _LoadingDemoScreenState extends State<LoadingDemoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _LoadingDemoTheme _theme = _LoadingDemoTheme.dark;

  static const _steps = [
    _LoadingStep(
      icon: Icons.image_search_rounded,
      title: '사진을 정리하고 있어요',
      description: '메뉴판이 잘 보이도록 이미지를 확인해요.',
      duration: Duration(milliseconds: 1800),
    ),
    _LoadingStep(
      icon: Icons.text_fields_rounded,
      title: '메뉴 글자를 읽고 있어요',
      description: '메뉴명과 가격 정보를 차례대로 찾고 있어요.',
      duration: Duration(milliseconds: 2300),
    ),
    _LoadingStep(
      icon: Icons.health_and_safety_rounded,
      title: '알레르기 정보를 확인해요',
      description: '내 알레르기와 메뉴 정보를 비교하고 있어요.',
      duration: Duration(milliseconds: 2400),
    ),
    _LoadingStep(
      icon: Icons.auto_awesome_rounded,
      title: '결과 표시를 준비해요',
      description: '분석 결과를 메뉴판 위에 맞춰 보고 있어요.',
      duration: Duration(milliseconds: 2100),
    ),
  ];

  static final int _totalDurationMs = _steps.fold<int>(
    0,
    (sum, step) => sum + step.duration.inMilliseconds,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalDurationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _TimelineSnapshot _snapshotFor(double value) {
    final elapsed = value * _totalDurationMs;
    var cursor = 0.0;

    for (var i = 0; i < _steps.length; i++) {
      final stepDuration = _steps[i].duration.inMilliseconds.toDouble();
      final nextCursor = cursor + stepDuration;
      if (elapsed <= nextCursor || i == _steps.length - 1) {
        final localProgress = ((elapsed - cursor) / stepDuration).clamp(
          0.0,
          1.0,
        );
        final rawOverall =
            (cursor + stepDuration * localProgress) / _totalDurationMs;
        return _TimelineSnapshot(
          activeIndex: i,
          overallProgress: _heldProgress(rawOverall),
          localProgress: _heldLocalProgress(localProgress),
        );
      }
      cursor = nextCursor;
    }

    return const _TimelineSnapshot(
      activeIndex: 0,
      overallProgress: 0,
      localProgress: 0,
    );
  }

  double _heldProgress(double value) {
    final capped = value.clamp(0.0, 0.92);
    final eased = Curves.easeOutCubic.transform(capped / 0.92) * 0.92;
    return _applyHold(eased).clamp(0.0, 0.92);
  }

  double _heldLocalProgress(double value) {
    final eased = Curves.easeOutCubic.transform(value.clamp(0.0, 1.0));
    return _applyHold(eased).clamp(0.06, 0.94);
  }

  double _applyHold(double value) {
    if (value < 0.34) return value;
    if (value < 0.42) return 0.34 + (value - 0.34) * 0.18;
    if (value < 0.67) return value - 0.065;
    if (value < 0.76) return 0.605 + (value - 0.67) * 0.20;
    return value - 0.135;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _theme == _LoadingDemoTheme.light;
    final isSoft = _theme == _LoadingDemoTheme.soft;
    return Scaffold(
      backgroundColor: switch (_theme) {
        _LoadingDemoTheme.light => const Color(0xFFFFF5F7),
        _LoadingDemoTheme.soft => const Color(0xFF34363C),
        _LoadingDemoTheme.dark => const Color(0xFF101010),
      },
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.76)
                    : isSoft
                    ? const Color(0xFF25272D).withValues(alpha: 0.52)
                    : Colors.black.withValues(alpha: 0.70),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: switch (_theme) {
                    _LoadingDemoTheme.light => const [
                      Color(0xF8FFF5F7),
                      Color(0xEFFFFBFD),
                      Color(0xF2FFFFFF),
                    ],
                    _LoadingDemoTheme.soft => const [
                      Color(0xE84A4D55),
                      Color(0xEF34363C),
                      Color(0xF426282E),
                    ],
                    _LoadingDemoTheme.dark => const [
                      Color(0xCC121212),
                      Color(0xE6121212),
                      Color(0xF9080808),
                    ],
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: isLight
                              ? Colors.white.withValues(alpha: 0.86)
                              : isSoft
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.14),
                          foregroundColor: isLight
                              ? const Color(0xFFF06292)
                              : Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '로딩화면 데모',
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF222222)
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '실제 분석 화면에는 아직 적용되지 않습니다',
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF777777)
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: _ThemeSelector(
                    selectedTheme: _theme,
                    onChanged: (theme) => setState(() => _theme = theme),
                    theme: _theme,
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final snapshot = _snapshotFor(_controller.value);
                      return _AnalysisLoadingPreview(
                        steps: _steps,
                        snapshot: snapshot,
                        animationValue: _controller.value,
                        theme: _theme,
                      );
                    },
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

enum _LoadingDemoTheme { dark, soft, light }

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selectedTheme,
    required this.onChanged,
    required this.theme,
  });

  final _LoadingDemoTheme selectedTheme;
  final ValueChanged<_LoadingDemoTheme> onChanged;
  final _LoadingDemoTheme theme;

  @override
  Widget build(BuildContext context) {
    Widget buildButton({
      required _LoadingDemoTheme theme,
      required String label,
      required IconData icon,
    }) {
      final selected = selectedTheme == theme;
      final lightSurface = this.theme == _LoadingDemoTheme.light;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(theme),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF06292)
                  : lightSurface
                  ? Colors.white.withValues(alpha: 0.80)
                  : Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? const Color(0xFFF06292)
                    : lightSurface
                    ? const Color(0xFFFCE4EC)
                    : Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : lightSurface
                      ? const Color(0xFFF06292)
                      : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : lightSurface
                        ? const Color(0xFF555555)
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildButton(
          theme: _LoadingDemoTheme.dark,
          label: '어두운 테마',
          icon: Icons.dark_mode_rounded,
        ),
        const SizedBox(width: 8),
        buildButton(
          theme: _LoadingDemoTheme.soft,
          label: '중간 톤',
          icon: Icons.contrast_rounded,
        ),
        const SizedBox(width: 8),
        buildButton(
          theme: _LoadingDemoTheme.light,
          label: '밝은 테마',
          icon: Icons.light_mode_rounded,
        ),
      ],
    );
  }
}

class _AnalysisLoadingPreview extends StatelessWidget {
  const _AnalysisLoadingPreview({
    required this.steps,
    required this.snapshot,
    required this.animationValue,
    required this.theme,
  });

  final List<_LoadingStep> steps;
  final _TimelineSnapshot snapshot;
  final double animationValue;
  final _LoadingDemoTheme theme;

  @override
  Widget build(BuildContext context) {
    final activeStep = steps[snapshot.activeIndex];
    final mascotLift = math.sin(animationValue * math.pi * 2) * 4.0;
    final isLight = theme == _LoadingDemoTheme.light;
    final isSoft = theme == _LoadingDemoTheme.soft;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.94)
                    : isSoft
                    ? const Color(0xFF3A3D45).withValues(alpha: 0.84)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFFCE4EC)
                      : isSoft
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isLight
                          ? 0.10
                          : isSoft
                          ? 0.20
                          : 0.25,
                    ),
                    blurRadius: isLight ? 24 : 20,
                    spreadRadius: isLight ? 0 : 2,
                    offset: isLight ? const Offset(0, 10) : Offset.zero,
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
                    Text(
                      '메뉴판을 분석하고 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF222222) : Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '메뉴와 알레르기 정보를 차례대로 확인할게요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF777777)
                            : Colors.white70,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProgressSummary(
                      progress: snapshot.overallProgress,
                      activeStep: activeStep,
                      flowValue: animationValue,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < steps.length; i++) ...[
                      _LoadingStepTile(
                        step: steps[i],
                        state: _stateFor(i, snapshot.activeIndex),
                        theme: theme,
                        localProgress: i == snapshot.activeIndex
                            ? snapshot.localProgress
                            : i < snapshot.activeIndex
                            ? 1
                            : 0,
                      ),
                      if (i != steps.length - 1) const SizedBox(height: 7),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _LoadingStepState _stateFor(int index, int activeIndex) {
    if (index < activeIndex) return _LoadingStepState.completed;
    if (index == activeIndex) return _LoadingStepState.active;
    return _LoadingStepState.pending;
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.progress,
    required this.activeStep,
    required this.flowValue,
    required this.theme,
  });

  final double progress;
  final _LoadingStep activeStep;
  final double flowValue;
  final _LoadingDemoTheme theme;

  @override
  Widget build(BuildContext context) {
    final displayProgress = progress.clamp(0.0, 0.98);
    final isLight = theme == _LoadingDemoTheme.light;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activeStep.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isLight ? const Color(0xFF333333) : Colors.white,
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
        _FlowingProgressBar(
          progress: displayProgress,
          flowValue: flowValue,
          theme: theme,
        ),
      ],
    );
  }
}

class _FlowingProgressBar extends StatelessWidget {
  const _FlowingProgressBar({
    required this.progress,
    required this.flowValue,
    required this.theme,
  });

  final double progress;
  final double flowValue;
  final _LoadingDemoTheme theme;

  @override
  Widget build(BuildContext context) {
    final isLight = theme == _LoadingDemoTheme.light;
    final isSoft = theme == _LoadingDemoTheme.soft;
    return SizedBox(
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isLight
                ? const Color(0xFFFFE4EC).withValues(alpha: 0.68)
                : isSoft
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.12),
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
                    child: SizedBox(
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
    required this.theme,
  });

  final _LoadingStep step;
  final _LoadingStepState state;
  final double localProgress;
  final _LoadingDemoTheme theme;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _LoadingStepState.completed;
    final isActive = state == _LoadingStepState.active;
    final isLight = theme == _LoadingDemoTheme.light;
    final isSoft = theme == _LoadingDemoTheme.soft;
    final showDescription = !isSoft;
    final color = isCompleted
        ? (isLight ? const Color(0xFF43A047) : const Color(0xFF81C784))
        : isActive
        ? const Color(0xFFF06292)
        : (isLight ? const Color(0xFFBDBDBD) : Colors.white38);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFF06292).withValues(alpha: 0.14)
            : isLight
            ? const Color(0xFFFFF8FA)
            : isSoft
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF06292).withValues(alpha: 0.70)
              : isLight
              ? const Color(0xFFFCE4EC)
              : isSoft
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white10,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: showDescription
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: isActive
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: localProgress.clamp(0.08, 0.96),
                          strokeWidth: 2.4,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.16),
                        ),
                      )
                    : Icon(
                        isCompleted ? Icons.check_rounded : step.icon,
                        color: color,
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: showDescription
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Text(
                    step.title,
                    maxLines: isSoft ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? (isLight ? const Color(0xFF222222) : Colors.white)
                          : (isLight
                                ? const Color(0xFF8C8C8C)
                                : Colors.white54),
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (showDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF777777)
                            : Colors.white60,
                        fontSize: 11.1,
                        height: 1.36,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StepStateBadge(state: state, color: color),
          ],
        ),
      ),
    );
  }
}

class _StepStateBadge extends StatelessWidget {
  const _StepStateBadge({required this.state, required this.color});

  final _LoadingStepState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      _LoadingStepState.completed => '완료',
      _LoadingStepState.active => '진행 중',
      _LoadingStepState.pending => '대기',
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
  const _LoadingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
  });

  final IconData icon;
  final String title;
  final String description;
  final Duration duration;
}

class _TimelineSnapshot {
  const _TimelineSnapshot({
    required this.activeIndex,
    required this.overallProgress,
    required this.localProgress,
  });

  final int activeIndex;
  final double overallProgress;
  final double localProgress;
}

enum _LoadingStepState { completed, active, pending }
