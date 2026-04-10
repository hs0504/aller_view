import 'package:flutter/material.dart';
import 'preference_selection_screen.dart';

class AllergySelectionScreen extends StatefulWidget {
  const AllergySelectionScreen({super.key});

  @override
  State<AllergySelectionScreen> createState() =>
      _AllergySelectionScreenState();
}

class _AllergySelectionScreenState
    extends State<AllergySelectionScreen> {
  final List<Map<String, String>> allergyItems = [
    {"name": "계란", "icon": "🥚"},
    {"name": "우유", "icon": "🥛"},
    {"name": "메밀", "icon": "🌾"},
    {"name": "땅콩", "icon": "🥜"},
    {"name": "대두", "icon": "🫘"},
    {"name": "밀", "icon": "🍞"},
    {"name": "고등어", "icon": "🐟"},
    {"name": "게", "icon": "🦀"},
    {"name": "새우", "icon": "🦐"},
    {"name": "돼지고기", "icon": "🐖"},
    {"name": "복숭아", "icon": "🍑"},
    {"name": "토마토", "icon": "🍅"},
    {"name": "아황산류", "icon": "🧪"},
    {"name": "호두", "icon": "🌰"},
    {"name": "닭고기", "icon": "🍗"},
    {"name": "쇠고기", "icon": "🥩"},
    {"name": "오징어", "icon": "🦑"},
    {"name": "굴", "icon": "🦪"},
    {"name": "전복", "icon": "🐚"},
    {"name": "홍합", "icon": "🦪"},
    {"name": "잣", "icon": "🌰"},
    {"name": "추출성분", "icon": "⚗️"},
  ];

  final Set<int> selectedItems = {};

  // 🔥 클릭 애니메이션용
  final Map<int, double> scaleValues = {};

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
          "알레르기 정보 설정",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "보유하고 계신 알레르기 항목을 선택해주세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                SizedBox(height: 3),
                Text(
                  "맞춤형 식품 안전 정보를 제공해 드립니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allergyItems.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = allergyItems[index];
                final isSelected = selectedItems.contains(index);

                return GestureDetector(
                  onTap: () {
                    // 🔥 눌림 효과
                    setState(() {
                      scaleValues[index] = 0.95;
                    });

                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {
                        scaleValues[index] = 1.0;

                        if (isSelected) {
                          selectedItems.remove(index);
                        } else {
                          selectedItems.add(index);
                        }
                      });
                    });
                  },
                  child: AnimatedScale(
                    scale: (scaleValues[index] ?? 1.0) *
                        (isSelected ? 1.03 : 1.0), // 선택 시 살짝 확대
                    duration: const Duration(milliseconds: 120),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF06292)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 🔹 내용
                          Center(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  item["icon"]!,
                                  style:
                                  const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item["name"]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // ✅ 체크 아이콘 (페이드 효과)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: AnimatedOpacity(
                              opacity: isSelected ? 1 : 0,
                              duration:
                              const Duration(milliseconds: 200),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Color(0xFFF06292),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔻 하단 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedItems.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration:
                      const Duration(milliseconds: 350),
                      reverseTransitionDuration:
                      const Duration(milliseconds: 300),
                      pageBuilder: (_, __, ___) =>
                      const PreferenceSelectionScreen(),
                      transitionsBuilder:
                          (_, animation, __, child) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                          reverseCurve: Curves.easeIn,
                        );

                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
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
                  selectedItems.isEmpty
                      ? "1가지 이상의 항목을 선택해주세요"
                      : "선택 완료 (${selectedItems.length}개 항목)",
                  style: const TextStyle(
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
    );
  }
}