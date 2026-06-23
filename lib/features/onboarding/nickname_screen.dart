import 'package:flutter/material.dart';

import '../../core/storage/user_prefs.dart';
import 'allergy_selection_screen.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await UserPrefs.saveNickname(_nicknameController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const AllergySelectionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOut);
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
        title: const Text(
          "Aller-View",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _StepIndicator(current: 1, total: 3),
                const SizedBox(height: 24),
                const Text(
                  "안녕하세요!\n사용하실 닉네임을 알려주세요",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "닉네임은 나중에 변경할 수 있어요.",
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nicknameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onNext(),
                  decoration: InputDecoration(
                    hintText: "닉네임 입력",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFF06292), width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요';
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF06292),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "다음",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
    return Row(
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
    );
  }
}