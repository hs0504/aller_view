import 'package:flutter/material.dart';

import '../../core/storage/user_prefs.dart';
import '../home/main_home_screen.dart';

class PreferenceSelectionScreen extends StatefulWidget {
  const PreferenceSelectionScreen({super.key, this.isEditMode = false});

  /// true: 홈에서 편집 목적으로 진입, false: 최초 온보딩
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
      {'name': '단맛', 'icon': '🍯'},
    ],
    '식단 성향': [
      {'name': '육식', 'icon': '🥩'},
      {'name': '해산물', 'icon': '🦐'},
      {'name': '채식', 'icon': '🥗'},
    ],
  };

  // 기본값 0: 아무것도 선택하지 않은 상태
  Map<String, int> selectedScores = {};

  double _opacity = 0;
  double _offsetY = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await UserPrefs.loadPreferenceScores();
    setState(() {
      selectedScores = saved;
      _isLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _opacity = 1;
      _offsetY = 0;
    });
  }

  Future<void> _onComplete() async {
    await UserPrefs.savePreferenceScores(selectedScores);

    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.pop(context);
      return;
    }

    // 최초 온보딩 완료: 설정 저장 후 홈으로
    await UserPrefs.markSetupComplete();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const MainHomeScreen(),
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
                      _StepIndicator(current: 2, total: 2),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        '선호하는 음식 성향을 선택해주세요.\n선택된 정보를 바탕으로 맞춤형 메뉴를 추천해드립니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
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
                                final score = selectedScores[key] ?? 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        item['icon']!,
                                        style:
                                            const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          key,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // 별점: 미선택은 star_border, 터치 영역 44px 확보
                                      Row(
                                        children: List.generate(5, (index) {
                                          final starIndex = index + 1;
                                          final isActive = starIndex <= score;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                // 같은 별 다시 누르면 해제
                                                selectedScores[key] =
                                                    score == starIndex
                                                        ? 0
                                                        : starIndex;
                                              });
                                            },
                                            child: SizedBox(
                                              width: 36,
                                              height: 44,
                                              child: Center(
                                                child: AnimatedScale(
                                                  scale: isActive ? 1.15 : 1.0,
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  child: Icon(
                                                    isActive
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 24,
                                                    color: isActive
                                                        ? const Color(
                                                            0xFFF06292,
                                                          )
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
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
                          onPressed: _onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF06292),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.isEditMode ? '수정 완료' : '설정 완료',
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
