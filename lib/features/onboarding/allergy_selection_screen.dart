import 'package:flutter/material.dart';

import '../../core/data/allergy_data.dart';
import '../../core/storage/user_prefs.dart';
import 'preference_selection_screen.dart';

class AllergySelectionScreen extends StatefulWidget {
  const AllergySelectionScreen({super.key, this.isEditMode = false});

  /// true: 홈에서 편집 목적으로 진입, false: 최초 온보딩
  final bool isEditMode;

  @override
  State<AllergySelectionScreen> createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  final Set<int> selectedItems = {};
  final Map<int, double> scaleValues = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    if (widget.isEditMode) {
      final saved = await UserPrefs.loadAllergyIndices();
      setState(() {
        selectedItems.addAll(saved);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _onComplete() async {
    await UserPrefs.saveAllergyIndices(selectedItems);

    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.pop(context);
      return;
    }

    // 최초 온보딩: 식성 선택 화면으로 이동
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const PreferenceSelectionScreen(),
        transitionsBuilder: (_, animation, __, child) {
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
          widget.isEditMode ? '알레르기 정보 수정' : '알레르기 정보 설정',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!widget.isEditMode) _StepIndicator(current: 1, total: 2),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    '보유하고 계신 알레르기 항목을 선택해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allergyItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio:
                          MediaQuery.sizeOf(context).width < 380 ? 0.82 : 0.9,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final item = allergyItems[index];
                      final isSelected = selectedItems.contains(index);

                      return GestureDetector(
                        onTap: () {
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
                              (isSelected ? 1.03 : 1.0),
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
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
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
                                      Text(
                                        item['icon']!,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['name']!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: AnimatedOpacity(
                                    opacity: isSelected ? 1 : 0,
                                    duration: const Duration(milliseconds: 200),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : _onComplete,
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
                            ? '1가지 이상의 항목을 선택해주세요'
                            : widget.isEditMode
                            ? '수정 완료 (${selectedItems.length}개 항목)'
                            : '선택 완료 (${selectedItems.length}개 항목)',
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
