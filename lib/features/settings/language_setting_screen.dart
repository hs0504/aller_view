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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await UserPrefs.loadLanguageSettings();
    if (!mounted) return;
    setState(() {
      _departure = settings.departure;
      _isLoading = false;
    });
  }

  Future<void> _onSave() async {
    await UserPrefs.saveLanguageSettings(
      departureLanguage: _departure,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '\uc5b8\uc5b4\u0020\uc124\uc815\uc774\u0020\uc800\uc7a5\ub418\uc5c8\uc5b4\uc694\u002e',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  LanguageOption _findOption(List<LanguageOption> options, String code) {
    return options.firstWhere(
      (option) => option.code == code,
      orElse: () => options.first,
    );
  }

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
          '\uc5b8\uc5b4\u0020\uc124\uc815',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF06292)),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCard(
                          departure: _findOption(
                            departureLanguageOptions,
                            _departure,
                          ),
                          arrival: _findOption(
                            arrivalLanguageOptions,
                            'ko',
                          ),
                          isSameLanguage: _departure == 'ko',
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: '\ucd9c\ubc1c\u0020\uc5b8\uc5b4',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\ubd84\uc11d\ud560\u0020\uba54\ub274\ud310\uc758\u0020\uc5b8\uc5b4\ub97c\u0020\uc120\ud0dd\ud574\u0020\uc8fc\uc138\uc694\u002e',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
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
                        _SectionHeader(
                          title: '\ubc88\uc5ed\u0020\uacb0\uacfc',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\ucd5c\uc885\u0020\uc2dc\uc5f0\u0020\ubc84\uc804\uc5d0\uc11c\ub294\u0020\ud55c\uad6d\uc5b4\u0020\uc0ac\uc6a9\uc790\uc5d0\uac8c\u0020\ub9de\ucdb0\u0020\uacb0\uacfc\ub97c\u0020\uc81c\uacf5\ud569\ub2c8\ub2e4\u002e',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FixedArrivalCard(
                          option: _findOption(arrivalLanguageOptions, 'ko'),
                          isSameLanguage: _departure == 'ko',
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
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
                          '\uc800\uc7a5\ud558\uae30',
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.departure,
    required this.arrival,
    required this.isSameLanguage,
  });

  final LanguageOption departure;
  final LanguageOption arrival;
  final bool isSameLanguage;

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
          Expanded(
            child: _SummaryLanguageItem(
              option: departure,
              label: '\ucd9c\ubc1c',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSameLanguage
                        ? Icons.analytics_rounded
                        : Icons.arrow_forward_rounded,
                    color: const Color(0xFFF06292),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSameLanguage ? '\ubd84\uc11d' : '\ubc88\uc5ed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _SummaryLanguageItem(
              option: arrival,
              label: '\uacb0\uacfc',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLanguageItem extends StatelessWidget {
  const _SummaryLanguageItem({
    required this.option,
    required this.label,
  });

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          option.nativeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FixedArrivalCard extends StatelessWidget {
  const _FixedArrivalCard({
    required this.option,
    required this.isSameLanguage,
  });

  final LanguageOption option;
  final bool isSameLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCE4EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(option.flag, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isSameLanguage
                            ? '\ud55c\uad6d\uc5b4\u0020\uba54\ub274\ud310\u0020\ubd84\uc11d'
                            : '\ud55c\uad6d\uc5b4\u0020\ubc88\uc5ed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06292).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '\uace0\uc815',
                        style: TextStyle(
                          color: Color(0xFFF06292),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  isSameLanguage
                      ? '\ubc88\uc5ed\u0020\uc5c6\uc774\u0020\uba54\ub274\u0020\uc815\ubcf4\uc640\u0020\uc54c\ub808\ub974\uae30\u0020\uc704\ud5d8\uc744\u0020\ud55c\uad6d\uc5b4\ub85c\u0020\uc815\ub9ac\ud569\ub2c8\ub2e4\u002e'
                      : '\ubd84\uc11d\u0020\uacb0\uacfc\uc640\u0020\uba54\ub274\u0020\uc124\uba85\uc740\u0020\ud55c\uad6d\uc5b4\ub85c\u0020\uc81c\uacf5\ub429\ub2c8\ub2e4\u002e',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.lock_rounded,
            color: Color(0xFFF06292),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({
    required this.options,
    required this.selectedCode,
    required this.onSelect,
    this.disabledCodes = const {},
    this.onDisabledTap,
  });

  final List<LanguageOption> options;
  final String selectedCode;
  final ValueChanged<String> onSelect;
  final Set<String> disabledCodes;
  final VoidCallback? onDisabledTap;

  @override
  Widget build(BuildContext context) {
    final childAspectRatio =
        MediaQuery.sizeOf(context).width < 380 ? 0.78 : 0.88;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: options.length,
      itemBuilder: (_, index) => _LanguageCard(
        option: options[index],
        isSelected: options[index].code == selectedCode,
        isDisabled: disabledCodes.contains(options[index].code),
        onTap: () => onSelect(options[index].code),
        onDisabledTap: onDisabledTap,
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    this.onDisabledTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  final VoidCallback? onDisabledTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? onDisabledTap : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF6F6F6)
              : isSelected
                  ? const Color(0xFFF06292)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: isDisabled
                      ? const Color(0xFFE7E7E7)
                      : const Color(0xFFEEEEEE),
                ),
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.black.withValues(alpha: 0.01)
                  : isSelected
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? Colors.black38
                          : isSelected
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.nativeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDisabled
                          ? Colors.black26
                          : isSelected
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
            if (isDisabled)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.block_rounded,
                  size: 14,
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
