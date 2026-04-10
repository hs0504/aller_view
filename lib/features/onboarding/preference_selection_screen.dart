import 'package:flutter/material.dart';
import '../home/main_home_screen.dart';

class PreferenceSelectionScreen extends StatefulWidget {
  const PreferenceSelectionScreen({super.key});

  @override
  State<PreferenceSelectionScreen> createState() =>
      _PreferenceSelectionScreenState();
}

class _PreferenceSelectionScreenState
    extends State<PreferenceSelectionScreen> {

  // 🔥 카테고리별 데이터
  final Map<String, List<Map<String, String>>> preferenceSections = {
    "맛 선호": [
      {"name": "매운맛", "icon": "🌶"},
      {"name": "짠맛", "icon": "🧂"},
      {"name": "단맛", "icon": "🍯"},
    ],
    "식단 성향": [
      {"name": "육식", "icon": "🥩"},
      {"name": "해산물", "icon": "🦐"},
      {"name": "채식", "icon": "🥗"},
    ],
  };

  final Map<String, int> selectedScores = {};

  // 🔥 애니메이션 상태
  double opacity = 0;
  double offsetY = 30;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        opacity = 1;
        offsetY = 0;
      });
    });
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
        title: const Text(
          "식성 정보 설정",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),

      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          transform: Matrix4.translationValues(0, offsetY, 0),
          curve: Curves.easeOut,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      "선호하는 음식 성향을 선택해주세요.",
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "선택된 정보를 바탕으로 맞춤형 메뉴를 추천해드립니다.",
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  children:
                  preferenceSections.entries.map((section) {
                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // 🔥 섹션 타이틀
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: Text(
                            section.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ),

                        // 🔹 카드 리스트
                        ...section.value.map((item) {
                          final key = item["name"]!;
                          final score =
                              selectedScores[key] ?? 3;

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 4,
                                  offset:
                                  const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item["icon"]!,
                                  style: const TextStyle(
                                      fontSize: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item["name"]!,
                                    style:
                                    const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // ⭐ 별점 UI (애니메이션 추가)
                                Row(
                                  children: List.generate(5,
                                          (index) {
                                        final starIndex =
                                            index + 1;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedScores[
                                              key] =
                                                  starIndex;
                                            });
                                          },
                                          child: AnimatedScale(
                                            scale: starIndex <=
                                                score
                                                ? 1.15
                                                : 1.0,
                                            duration:
                                            const Duration(
                                                milliseconds:
                                                150),
                                            child: Icon(
                                              Icons.star,
                                              size: 22,
                                              color: starIndex <=
                                                  score
                                                  ? const Color(
                                                  0xFFF06292)
                                                  : Colors
                                                  .grey[300],
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // 🔻 하단 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) => const MainHomeScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            );

                            return FadeTransition(
                              opacity: curved,
                              child: child,
                            );
                          },
                        ),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFF06292),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "설정 완료",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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