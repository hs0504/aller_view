import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/language_data.dart';
import '../../core/storage/user_prefs.dart';

class LanguageSettingScreen extends StatefulWidget {
  const LanguageSettingScreen({super.key});

  @override
  State<LanguageSettingScreen> createState() => _LanguageSettingScreenState();
}

class _LanguageSettingScreenState extends State<LanguageSettingScreen> {
  String _departure = 'ja';
  String _arrival = 'ko';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await UserPrefs.loadLanguageSettings();
    setState(() {
      _departure = settings.departure;
      _arrival = settings.arrival;
      _isLoading = false;
    });
  }

  Future<void> _onSave() async {
    await UserPrefs.saveLanguageSettings(
      departureLanguage: _departure,
      arrivalLanguage: _arrival,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('언어 설정이 저장되었습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  LanguageOption _findOption(
    List<LanguageOption> options,
    String code,
  ) =>
      options.firstWhere(
        (o) => o.code == code,
        orElse: () => options.first,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFFCE4EC), height: 1),
        ),
        title: Text(
          '언어 설정',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 현재 설정 요약 카드 ──────────────────────────
                        _SummaryCard(
                          departure: _findOption(departureLanguageOptions, _departure),
                          arrival: _findOption(arrivalLanguageOptions, _arrival),
                        ),
                        const SizedBox(height: 28),

                        // ── 출발 언어 ────────────────────────────────────
                        _SectionHeader(title: '출발 언어'),
                        const SizedBox(height: 6),
                        Text(
                          '분석할 메뉴판의 언어를 선택하세요',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 14),
                        _LanguageGrid(
                          options: departureLanguageOptions,
                          selectedCode: _departure,
                          onSelect: (code) {
                            setState(() => _departure = code);
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── 도착 언어 ────────────────────────────────────
                        _SectionHeader(title: '도착 언어'),
                        const SizedBox(height: 6),
                        Text(
                          '번역 결과를 표시할 언어를 선택하세요',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 14),
                        _LanguageGrid(
                          options: arrivalLanguageOptions,
                          selectedCode: _arrival,
                          onSelect: (code) {
                            setState(() => _arrival = code);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── 저장 버튼 ─────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSave,
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
                          '저장하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

// ── 현재 설정 요약 카드 ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.departure,
    required this.arrival,
  });

  final LanguageOption departure;
  final LanguageOption arrival;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFFF8A80)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SummaryLanguageItem(option: departure, label: '출발'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  '번역',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _SummaryLanguageItem(option: arrival, label: '도착'),
        ],
      ),
    );
  }
}

class _SummaryLanguageItem extends StatelessWidget {
  const _SummaryLanguageItem({required this.option, required this.label});

  final LanguageOption option;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(option.flag, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text(
          option.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          option.nativeName,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── 언어 그리드 ──────────────────────────────────────────────────────────────

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({
    required this.options,
    required this.selectedCode,
    required this.onSelect,
  });

  final List<LanguageOption> options;
  final String selectedCode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) => _LanguageCard(
        option: options[i],
        isSelected: options[i].code == selectedCode,
        onTap: () => onSelect(options[i].code),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF06292) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFF06292).withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 10 : 4,
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
                  Text(option.flag, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    option.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.nativeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Color(0xFFF06292),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 섹션 헤더 ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF06292), Color(0xFFFF8A80)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
