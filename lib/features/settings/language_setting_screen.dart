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

  void _showDistinctLanguageMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '\ucd9c\ubc1c\u0020\uc5b8\uc5b4\uc640\u0020\ub3c4\ucc29\u0020\uc5b8\uc5b4\ub294\u0020\ub2e4\ub974\uac8c\u0020\uc124\uc815\ud574\u0020\uc8fc\uc138\uc694\u002e',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _swap() {
    final departureCodes = departureLanguageOptions.map((e) => e.code).toSet();
    final arrivalCodes = arrivalLanguageOptions.map((e) => e.code).toSet();
    if (!departureCodes.contains(_arrival) || !arrivalCodes.contains(_departure)) return;
    setState(() {
      final temp = _departure;
      _departure = _arrival;
      _arrival = temp;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await UserPrefs.loadLanguageSettings();
    if (!mounted) return;
    setState(() {
      _departure = settings.departure;
      _arrival = settings.arrival;
      _isLoading = false;
    });
  }

  Future<void> _onSave() async {
    if (_departure == _arrival) {
      _showDistinctLanguageMessage();
      return;
    }

    await UserPrefs.saveLanguageSettings(
      departureLanguage: _departure,
      arrivalLanguage: _arrival,
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
                            _arrival,
                          ),
                          onSwap: _swap,
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
                          disabledCodes: {_arrival},
                          onSelect: (code) {
                            setState(() => _departure = code);
                          },
                          onDisabledTap: _showDistinctLanguageMessage,
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: '\ub3c4\ucc29\u0020\uc5b8\uc5b4',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\ubc88\uc5ed\u0020\uacb0\uacfc\ub97c\u0020\ud45c\uc2dc\ud560\u0020\uc5b8\uc5b4\ub97c\u0020\uc120\ud0dd\ud574\u0020\uc8fc\uc138\uc694\u002e',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LanguageGrid(
                          options: arrivalLanguageOptions,
                          selectedCode: _arrival,
                          disabledCodes: {_departure},
                          onSelect: (code) {
                            setState(() => _arrival = code);
                          },
                          onDisabledTap: _showDistinctLanguageMessage,
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
    this.onSwap,
  });

  final LanguageOption departure;
  final LanguageOption arrival;
  final VoidCallback? onSwap;

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
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onSwap,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFFF06292),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\uad50\ud658',
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
              label: '\ub3c4\ucc29',
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
