import 'package:flutter/material.dart';

import '../../core/data/allergy_data.dart';
import '../../core/storage/user_prefs.dart';
import '../../service/auth_service.dart';
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
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

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

  void _showAllergyInfoSheet(BuildContext context, int index) {
    final item = allergyItems[index];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllergyInfoSheet(
        item: item,
        isSelected: selectedItems.contains(index),
        onRegister: () {
          setState(() => selectedItems.add(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _onComplete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await UserPrefs.saveAllergyIndices(selectedItems);
      await UserPrefs.saveAllergyIds(
        selectedItems.map((i) => i + 1).toList(),
      );

      final allergyNames =
          selectedItems.map((i) => allergyItems[i]['name']!).toList();
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _authService.updateProfile(allergies: allergyNames);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

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
                if (!widget.isEditMode) _StepIndicator(current: 2, total: 3),
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
                                if (item['description'] != null)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: GestureDetector(
                                      onTap: () => _showAllergyInfoSheet(
                                        context,
                                        index,
                                      ),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                                  .withValues(alpha: 0.28)
                                              : const Color(0xFFF06292)
                                                  .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFF06292),
                                            height: 1,
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
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (selectedItems.isEmpty || _isSaving)
                          ? null
                          : _onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
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

class _AllergyInfoSheet extends StatelessWidget {
  const _AllergyInfoSheet({
    required this.item,
    required this.isSelected,
    required this.onRegister,
  });

  final Map<String, String?> item;
  final bool isSelected;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final foodExamples = (item['foodExamples'] ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCE4EC)),
                    ),
                    child: Center(
                      child: Text(
                        item['icon']!,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D2D),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F7),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFFFCE4EC),
                            ),
                          ),
                          child: const Text(
                            '알레르기 유발 물질',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 20),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF06292),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '설명',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Description card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      item['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.85,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (foodExamples.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF06292),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '주로 포함된 식품',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: foodExamples
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F7),
                                border: Border.all(
                                  color: const Color(0xFFFCE4EC),
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF06292),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isSelected
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCE4EC)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFF06292),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '이미 등록된 항목이에요',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF06292),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '이 항목 알레르기로 등록하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
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
