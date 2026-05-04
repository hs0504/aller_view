import 'package:flutter/material.dart';

import '../../core/storage/user_prefs.dart';
import '../auth/auth_screen.dart';

class PreferenceSelectionScreen extends StatefulWidget {
  const PreferenceSelectionScreen({super.key, this.isEditMode = false});

  final bool isEditMode;

  @override
  State<PreferenceSelectionScreen> createState() =>
      _PreferenceSelectionScreenState();
}

class _PreferenceSelectionScreenState extends State<PreferenceSelectionScreen> {
  final Map<String, List<Map<String, String>>> preferenceSections = {
    '맛 선호': [
      {'name': '매운맛', 'icon': '🌶'},
      {'name': '짠맛', 'icon': '🧂'},
      {'name': '단맛', 'icon': '🍬'},
    ],
    '식단 성향': [
      {'name': '육식', 'icon': '🍖'},
      {'name': '해산물', 'icon': '🦐'},
      {'name': '채식', 'icon': '🥗'},
    ],
  };

  Map<String, int> selectedScores = {};
  double _opacity = 0;
  double _offsetY = 30;
  bool _isLoading = true;

  List<String> get _requiredPreferenceKeys => preferenceSections.values
      .expand((items) => items.map((item) => item['name']!))
      .toList(growable: false);

  bool _isValidScore(int? score) => score != null && score >= 1 && score <= 5;

  Map<String, int> _filterSavedScores(Map<String, int> scores) {
    final filtered = <String, int>{};
    for (final key in _requiredPreferenceKeys) {
      final score = scores[key];
      if (_isValidScore(score)) {
        filtered[key] = score!;
      }
    }
    return filtered;
  }

  Map<String, int> get _normalizedScores => _filterSavedScores(selectedScores);

  int get _completedCount => _requiredPreferenceKeys
      .where((key) => _isValidScore(selectedScores[key]))
      .length;

  int get _remainingCount => _requiredPreferenceKeys.length - _completedCount;

  bool get _isSelectionComplete => _remainingCount == 0;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await UserPrefs.loadPreferenceScores();
    if (!mounted) return;

    setState(() {
      selectedScores = _filterSavedScores(saved);
      _isLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    setState(() {
      _opacity = 1;
      _offsetY = 0;
    });
  }

  Future<void> _onComplete() async {
    if (!_isSelectionComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '모든 식성 항목에 1점부터 5점까지 점수를 선택해 주세요. 남은 항목 $_remainingCount개',
          ),
        ),
      );
      return;
    }

    await UserPrefs.savePreferenceScores(_normalizedScores);

    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.pop(context);
      return;
    }

    await UserPrefs.markSetupComplete();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _requiredPreferenceKeys.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F7),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.isEditMode ? '식성 정보 수정' : '식성 정보 설정',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _opacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                transform: Matrix4.translationValues(0, _offsetY, 0),
                curve: Curves.easeOut,
                child: Column(
                  children: [
                    if (!widget.isEditMode)
                      const _StepIndicator(current: 2, total: 2),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        '각 식성 항목을 1점부터 5점까지 선택해 주세요.\n선택한 점수는 나중에 맞춤 메뉴 추천에 활용돼요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SelectionStatusCard(
                        completedCount: _completedCount,
                        totalCount: totalCount,
                        remainingCount: _remainingCount,
                        isComplete: _isSelectionComplete,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: preferenceSections.entries.map((section) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  section.key,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF06292),
                                  ),
                                ),
                              ),
                              ...section.value.map((item) {
                                final key = item['name']!;
                                final score = selectedScores[key];
                                final hasScore = _isValidScore(score);

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: hasScore
                                          ? const Color(0xFFF8BBD0)
                                          : const Color(0xFFF06292),
                                      width: hasScore ? 1 : 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['icon']!,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  key,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  hasScore
                                                      ? '현재 선택: ${score!}점'
                                                      : '필수 항목이에요. 1점부터 5점까지 선택해 주세요',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    height: 1.35,
                                                    color: hasScore
                                                        ? Colors.grey.shade600
                                                        : const Color(
                                                            0xFFD81B60,
                                                          ),
                                                    fontWeight: hasScore
                                                        ? FontWeight.w500
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!hasScore)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFFFE4EC,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                '필수',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFD81B60),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            '낮음',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(5, (
                                                index,
                                              ) {
                                                final starIndex = index + 1;
                                                final isActive =
                                                    starIndex <= (score ?? 0);

                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedScores[key] =
                                                          starIndex;
                                                    });
                                                  },
                                                  child: SizedBox(
                                                    width: 36,
                                                    height: 44,
                                                    child: Center(
                                                      child: AnimatedScale(
                                                        scale: isActive
                                                            ? 1.15
                                                            : 1.0,
                                                        duration:
                                                            const Duration(
                                                              milliseconds:
                                                                  150,
                                                            ),
                                                        child: Icon(
                                                          isActive
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                          size: 24,
                                                          color: isActive
                                                              ? const Color(
                                                                  0xFFF06292,
                                                                )
                                                              : Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '높음',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSelectionComplete ? _onComplete : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF06292),
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _isSelectionComplete
                                ? (widget.isEditMode ? '수정 완료' : '설정 완료')
                                : '남은 항목 $_remainingCount개 선택해 주세요',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
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

class _SelectionStatusCard extends StatelessWidget {
  const _SelectionStatusCard({
    required this.completedCount,
    required this.totalCount,
    required this.remainingCount,
    required this.isComplete,
  });

  final int completedCount;
  final int totalCount;
  final int remainingCount;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final accentColor = isComplete
        ? const Color(0xFFF06292)
        : const Color(0xFFD81B60);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFFFE4EC) : const Color(0xFFFFF1F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? const Color(0xFFF8BBD0)
              : const Color(0xFFF48FB1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isComplete ? Icons.check_circle : Icons.info_outline,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? '모든 식성 항목 선택 완료' : '아직 선택하지 않은 항목이 있어요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isComplete
                      ? '각 항목의 점수가 저장될 준비가 완료됐어요.'
                      : '남은 $remainingCount개 항목에 1점부터 5점까지 점수를 선택해 주세요.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(total, (index) {
          final isActive = index + 1 == current;
          final isDone = index + 1 < current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: (isActive || isDone)
                    ? const Color(0xFFF06292)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
