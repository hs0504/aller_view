import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/data/allergy_data.dart';
import '../../core/data/language_data.dart';
import '../../core/storage/user_prefs.dart';
import '../camera/menu_camera_screen.dart';
import '../camera/menu_photo_preview_screen.dart';
import '../location/location_screen.dart';
import '../onboarding/allergy_selection_screen.dart';
import '../onboarding/preference_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/language_setting_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  List<int> _allergyIndices = [];
  String _departureLanguage = 'ja';
  String _arrivalLanguage = 'ko';
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _handleAnalyzeCardPressed() async {
    final source = await showModalBottomSheet<_MenuImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnalysisFlowSheet(
        currentLanguageCode: _departureLanguage,
        onLanguageChanged: (code) async {
          await UserPrefs.saveLanguageSettings(departureLanguage: code);
          if (mounted) setState(() => _departureLanguage = code);
        },
      ),
    );

    if (!mounted || source == null) return;

    switch (source) {
      case _MenuImageSource.camera:
        await _openCameraWithPermission();
      case _MenuImageSource.gallery:
        await _pickFromGallery();
    }
  }

  Future<void> _openCameraWithPermission() async {
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

  Future<void> _pickFromGallery() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted || photo == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MenuPhotoPreviewScreen(
            photo: photo,
            source: MenuPhotoSource.gallery,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to pick gallery image: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('갤러리에서 사진을 불러오지 못했어요. 다시 시도해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCameraPermissionDialog({required bool canOpenSettings}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('카메라 권한이 필요해요'),
          content: const Text('메뉴판을 촬영하려면 카메라 접근을 허용해 주세요.'),
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
    final quickMenuAspectRatio = screenWidth < 380 || textScale > 1.1
        ? 0.88
        : 1.2;

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
                onCameraTap: _handleAnalyzeCardPressed,
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
                    desc:
                        '\ub0b4\u0020\uc54c\ub808\ub974\uae30\u0020\ud56d\ubaa9\u0020\ud3b8\uc9d1',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AllergySelectionScreen(isEditMode: true),
                        ),
                      );
                      _loadAllergyData(); // ??轅붽틓????獄쏅챸???????????????????ル늉????
                    },
                  ),
                  _QuickMenuCard(
                    icon: Icons.restaurant_menu_outlined,
                    title: '\ucde8\ud5a5\u0020\uad00\ub9ac',
                    desc:
                        '\uc74c\uc2dd\u0020\uc120\ud638\ub3c4\u0020\ud3b8\uc9d1',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PreferenceSelectionScreen(isEditMode: true),
                      ),
                    ),
                  ),
                  _QuickMenuCard(
                    icon: Icons.location_on,
                    title: '\uc8fc\ubcc0\u0020\uc2dd\ub2f9\u0020\ucc3e\uae30',
                    desc:
                        '\ud604\uc7ac\u0020\uc704\uce58\u0020\uae30\ubc18\u0020\uc8fc\ubcc0\u0020\uc2dd\ub2f9\u0020\ud0d0\uc0c9',
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
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 1) {
            setState(() => _currentIndex = 1);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() => _currentIndex = 0));
          } else {
            setState(() => _currentIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '\ud648'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '\ub0b4\u0020\uc815\ubcf4',
          ),
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
  const _AllergyChip({required this.label, required this.dotColor, this.onTap});

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
                      builder: (_) =>
                          const AllergySelectionScreen(isEditMode: true),
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

enum _MenuImageSource { camera, gallery }

// ──────────────────────────────────────────────────────────────────────────
// 언어 확인 + 촬영 방법 선택 멀티스텝 바텀시트
// ──────────────────────────────────────────────────────────────────────────

enum _AnalysisFlowStep { languageConfirm, languageSelect, sourceSelect }

class _AnalysisFlowSheet extends StatefulWidget {
  const _AnalysisFlowSheet({
    required this.currentLanguageCode,
    required this.onLanguageChanged,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<_AnalysisFlowSheet> createState() => _AnalysisFlowSheetState();
}

class _AnalysisFlowSheetState extends State<_AnalysisFlowSheet> {
  late String _selectedCode;
  _AnalysisFlowStep _step = _AnalysisFlowStep.languageConfirm;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentLanguageCode;
  }

  LanguageOption get _currentOption => departureLanguageOptions.firstWhere(
    (opt) => opt.code == _selectedCode,
    orElse: () => departureLanguageOptions.first,
  );

  void _onLanguageSelected(String code) {
    setState(() {
      _selectedCode = code;
      _step = _AnalysisFlowStep.languageConfirm;
    });
  }

  void _onConfirmLanguage() {
    if (_selectedCode != widget.currentLanguageCode) {
      widget.onLanguageChanged(_selectedCode);
    }
    setState(() => _step = _AnalysisFlowStep.sourceSelect);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (_step) {
            _AnalysisFlowStep.languageConfirm => _LanguageConfirmView(
              key: const ValueKey('confirm'),
              option: _currentOption,
              bottomPad: bottomPad,
              onConfirm: _onConfirmLanguage,
              onChangeLanguage: () =>
                  setState(() => _step = _AnalysisFlowStep.languageSelect),
            ),
            _AnalysisFlowStep.languageSelect => _LanguageSelectView(
              key: const ValueKey('select'),
              selectedCode: _selectedCode,
              bottomPad: bottomPad,
              onBack: () =>
                  setState(() => _step = _AnalysisFlowStep.languageConfirm),
              onSelect: _onLanguageSelected,
            ),
            _AnalysisFlowStep.sourceSelect => _SourceSelectView(
              key: const ValueKey('source'),
              option: _currentOption,
              bottomPad: bottomPad,
            ),
          },
        ),
      ),
    );
  }
}

class _LanguageConfirmView extends StatelessWidget {
  const _LanguageConfirmView({
    super.key,
    required this.option,
    required this.bottomPad,
    required this.onConfirm,
    required this.onChangeLanguage,
  });

  final LanguageOption option;
  final double bottomPad;
  final VoidCallback onConfirm;
  final VoidCallback onChangeLanguage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '메뉴판 언어 확인',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '분석할 메뉴판의 언어를 확인해 주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCE4EC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFF06292),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '메뉴판 언어가 실제 사진과 다르면 번역이나 알레르기 분석 결과가 부정확할 수 있어요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B6B6B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF06292).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(option.flag, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                Text(
                  option.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.nativeName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onChangeLanguage,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF06292),
                side: BorderSide(
                  color: const Color(0xFFF06292).withValues(alpha: 0.55),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text(
                '다른 언어로 변경하기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF06292),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                '이 언어로 분석 시작',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelectView extends StatelessWidget {
  const _LanguageSelectView({
    super.key,
    required this.selectedCode,
    required this.bottomPad,
    required this.onBack,
    required this.onSelect,
  });

  final String selectedCode;
  final double bottomPad;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final childAspectRatio = MediaQuery.sizeOf(context).width < 380
        ? 0.78
        : 0.88;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '메뉴판 언어 변경',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 4),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: departureLanguageOptions.length,
                itemBuilder: (_, index) {
                  final opt = departureLanguageOptions[index];
                  final isSelected = opt.code == selectedCode;
                  return GestureDetector(
                    onTap: () => onSelect(opt.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF06292)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(
                                    0xFFF06292,
                                  ).withValues(alpha: 0.30)
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
                                Text(
                                  opt.flag,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  opt.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.nativeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceSelectView extends StatelessWidget {
  const _SourceSelectView({
    super.key,
    required this.option,
    required this.bottomPad,
  });

  final LanguageOption option;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '촬영 방법 선택',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(option.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${option.name} 메뉴판을 분석합니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            title: '카메라로 촬영',
            description: '지금 바로 메뉴판을 촬영해서 분석해요.',
            onTap: () => Navigator.pop(context, _MenuImageSource.camera),
          ),
          const SizedBox(height: 12),
          _SourceOption(
            icon: Icons.photo_library_rounded,
            title: '갤러리에서 선택',
            description: '저장된 메뉴판 사진을 불러와 분석해요.',
            onTap: () => Navigator.pop(context, _MenuImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF5F7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF06292).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFF06292), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFF06292),
              ),
            ],
          ),
        ),
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
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 25,
                    bottom: -25,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
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
                                '메뉴판 분석하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '메뉴판을 찍거나 갤러리에서 사진을 불러와 분석을 시작해요',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '분석 시작',
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
            Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
            GestureDetector(
              onTap: onLanguageTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
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
