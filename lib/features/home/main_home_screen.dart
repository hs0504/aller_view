import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/data/allergy_data.dart';
import '../../core/data/language_data.dart';
import '../../core/storage/user_prefs.dart';
import '../camera/menu_camera_screen.dart';
import '../location/location_screen.dart';
import '../onboarding/allergy_selection_screen.dart';
import '../onboarding/preference_selection_screen.dart';
import '../settings/language_setting_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  List<int> _allergyIndices = [];
  String _departureLanguage = 'ja';
  String _arrivalLanguage = 'ko';

  @override
  void initState() {
    super.initState();
    _loadAllergyData();
    _loadLanguageSettings();
  }

  Future<void> _loadAllergyData() async {
    final indices = await UserPrefs.loadAllergyIndices();
    if (!mounted) return;
    setState(() {
      _allergyIndices = indices.where((i) => i < allergyItems.length).toList();
    });
  }

  Future<void> _loadLanguageSettings() async {
    final settings = await UserPrefs.loadLanguageSettings();
    if (!mounted) return;
    setState(() {
      _departureLanguage = settings.departure;
      _arrivalLanguage = settings.arrival;
    });
  }

  Future<void> _handleCameraCardPressed() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;

    if (status.isGranted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MenuCameraScreen()),
      );
      return;
    }

    await _showCameraPermissionDialog(
      canOpenSettings: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  Future<void> _showCameraPermissionDialog({required bool canOpenSettings}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('카메라 권한이 필요해요'),
          content: const Text(
            '메뉴판을 촬영하려면 카메라 접근을 허용해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
            if (canOpenSettings)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  openAppSettings();
                },
                child: const Text('설정 열기'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final quickMenuAspectRatio =
        screenWidth < 380 || textScale > 1.1 ? 0.88 : 1.2;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFFCE4EC), height: 1),
        ),
        title: Stack(
          children: [
            Text(
              'AllerView',
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.5
                  ..color = const Color(0xFFF06292),
              ),
            ),
            Text(
              'AllerView',
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllergyData,
        color: const Color(0xFFF06292),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _AllergyHeaderCard(
                allergyIndices: _allergyIndices,
                onAllergyChanged: _loadAllergyData,
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: '\uba54\ub274\ud310\u0020\ubd84\uc11d'),
              const SizedBox(height: 10),
              _CameraCard(
                onCameraTap: _handleCameraCardPressed,
                onLanguageTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSettingScreen(),
                    ),
                  );
                  _loadLanguageSettings();
                },
                departureCode: _departureLanguage,
                arrivalCode: _arrivalLanguage,
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: '\ube60\ub978\u0020\uba54\ub274'),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: quickMenuAspectRatio,
                children: [
                  _QuickMenuCard(
                    icon: Icons.medical_information_outlined,
                    title: '\uc54c\ub808\ub974\uae30\u0020\uad00\ub9ac',
                    desc: '\ub0b4\u0020\uc54c\ub808\ub974\uae30\u0020\ud56d\ubaa9\u0020\ud3b8\uc9d1',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllergySelectionScreen(
                            isEditMode: true,
                          ),
                        ),
                      );
                      _loadAllergyData(); // ??轅붽틓????獄쏅챸???????????????????ル늉????
                    },
                  ),
                  _QuickMenuCard(
                    icon: Icons.restaurant_menu_outlined,
                    title: '\ucde8\ud5a5\u0020\uad00\ub9ac',
                    desc: '\uc74c\uc2dd\u0020\uc120\ud638\ub3c4\u0020\ud3b8\uc9d1',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PreferenceSelectionScreen(
                          isEditMode: true,
                        ),
                      ),
                    ),
                  ),
                  _QuickMenuCard(
                    icon: Icons.location_on,
                    title: '\uc8fc\ubcc0\u0020\uc2dd\ub2f9\u0020\ucc3e\uae30',
                    desc: '\ud604\uc7ac\u0020\uc704\uce58\u0020\uae30\ubc18\u0020\uc8fc\ubcc0\u0020\uc2dd\ub2f9\u0020\ud0d0\uc0c9',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocationScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickMenuCard(
                    icon: Icons.translate_outlined,
                    title: '\uc5b8\uc5b4\u0020\uc124\uc815',
                    desc: '\ubc88\uc5ed\u0020\uc5b8\uc5b4\u0020\ubcc0\uacbd',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSettingScreen(),
                        ),
                      );
                      _loadLanguageSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFFF06292),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '\ud648'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '\ub0b4\u0020\uc815\ubcf4'),
        ],
      ),
    );
  }
}

class _AllergyHeaderCard extends StatelessWidget {
  const _AllergyHeaderCard({
    required this.allergyIndices,
    required this.onAllergyChanged,
  });

  final List<int> allergyIndices;
  final VoidCallback onAllergyChanged;

  void _showAllAllergies(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllergyBottomSheet(
        allergyIndices: allergyIndices,
        onAllergyChanged: onAllergyChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int maxVisible = 3;
    final visible = allergyIndices.take(maxVisible).toList();
    final remaining = allergyIndices.length - maxVisible;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFFF8A80)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\uc624\ub298\ub3c4\u0020\uc548\uc804\ud55c\u0020\uc2dd\uc0ac\ub97c\u0020\ub3c4\uc640\ub4dc\ub9b4\uac8c\uc694',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '\ub4f1\ub85d\ub41c\u0020\uc54c\ub808\ub974\uae30\u0020\ud56d\ubaa9',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          allergyIndices.isEmpty
              ? const Text(
                  '\ud56d\ubaa9\u0020\uc5c6\uc74c',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...visible.map(
                      (i) => _AllergyChip(
                        label: allergyItems[i]['name']!,
                        dotColor: allergyColors[i],
                        onTap: () => _showAllAllergies(context),
                      ),
                    ),
                    if (remaining > 0)
                      _AllergyChip(
                        label: '+$remaining\uac1c',
                        dotColor: Colors.white54,
                        onTap: () => _showAllAllergies(context),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _AllergyChip extends StatelessWidget {
  const _AllergyChip({
    required this.label,
    required this.dotColor,
    this.onTap,
  });

  final String label;
  final Color dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyBottomSheet extends StatelessWidget {
  const _AllergyBottomSheet({
    required this.allergyIndices,
    required this.onAllergyChanged,
  });

  final List<int> allergyIndices;
  final VoidCallback onAllergyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '등록된 알레르기 항목',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: allergyIndices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '\ub4f1\ub85d\ub41c\u0020\uc54c\ub808\ub974\uae30\u0020\ud56d\ubaa9\uc774\u0020\uc5c6\uc5b4\uc694\u002e',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: allergyIndices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final i = allergyIndices[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: allergyColors[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              allergyItems[i]['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                allergyItems[i]['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllergySelectionScreen(
                        isEditMode: true,
                      ),
                    ),
                  );
                  onAllergyChanged();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '알레르기 수정하기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.onCameraTap,
    required this.onLanguageTap,
    required this.departureCode,
    required this.arrivalCode,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onLanguageTap;
  final String departureCode;
  final String arrivalCode;

  LanguageOption _findOption(List<LanguageOption> options, String code) {
    return options.firstWhere(
      (option) => option.code == code,
      orElse: () => options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Camera CTA area
            GestureDetector(
              onTap: onCameraTap,
              child: Stack(
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 25, bottom: -25,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '\uba54\ub274\ud310\u0020\ucd2c\uc601\ud558\uae30',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\u0041\u0049\uac00\u0020\uc54c\ub808\ub974\uae30\u0020\uc131\ubd84\uc744\u0020\uc790\ub3d9\uc73c\ub85c\u0020\ubd84\uc11d\ud574\uc694',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '탭하여 시작',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            GestureDetector(
              onTap: onLanguageTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${_findOption(departureLanguageOptions, departureCode).flag} '
                        '${_findOption(departureLanguageOptions, departureCode).name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${_findOption(arrivalLanguageOptions, arrivalCode).flag} '
                        '${_findOption(arrivalLanguageOptions, arrivalCode).name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\ubcc0\uacbd',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFF06292)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
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
