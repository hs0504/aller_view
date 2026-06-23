import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/storage/user_prefs.dart';
import '../../service/auth_service.dart';

const String _kBaseUrl =
    'https://aller-view-s3-bucket.s3.us-east-1.amazonaws.com/proifle/';

const List<String> kAvatarUrls = [
  '${_kBaseUrl}thumbs-1779640623693.svg',
  '${_kBaseUrl}thumbs-1779640638755.svg',
  '${_kBaseUrl}thumbs-1779640640700.svg',
  '${_kBaseUrl}thumbs-1779640642543.svg',
  '${_kBaseUrl}thumbs-1779640649201.svg',
  '${_kBaseUrl}thumbs-1779640651401.svg',
  '${_kBaseUrl}thumbs-1779640653148.svg',
  '${_kBaseUrl}thumbs-1779640654210.svg',
  '${_kBaseUrl}thumbs-1779640656571.svg',
  '${_kBaseUrl}thumbs-1779640658728.svg',
  '${_kBaseUrl}thumbs-1779640660262.svg',
  '${_kBaseUrl}thumbs-1779640662003.svg',
  '${_kBaseUrl}thumbs-1779640663860.svg',
  '${_kBaseUrl}thumbs-1779640665379.svg',
  '${_kBaseUrl}thumbs-1779640666717.svg',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  String _nickname = '';
  String? _selectedAvatarUrl;
  List<String> _allergies = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final nickname = await UserPrefs.loadNickname() ?? '';
    final avatarUrl = await UserPrefs.loadAvatarUrl();
    final allergyIndices = await UserPrefs.loadAllergyIndices();
    final allergies = UserPrefs.allergyNamesFromIndices(allergyIndices);
    if (mounted) {
      setState(() {
        _nickname = nickname;
        _selectedAvatarUrl = avatarUrl;
        _allergies = allergies;
      });
    }
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _nickname);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 닉네임 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              '저장',
              style: TextStyle(color: Color(0xFFF06292)),
            ),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == _nickname) return;
    setState(() => _nickname = result);
    await UserPrefs.saveNickname(result);
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await _authService.updateProfile(nickname: result, allergies: _allergies);
    }
  }

  Future<void> _onAvatarSelected(String url) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _selectedAvatarUrl = url;
    });
    try {
      await UserPrefs.saveAvatarUrl(url);
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _authService.updateProfile(allergies: _allergies, avatarUrl: url);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          '내 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCurrentAvatar(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _editNickname,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _nickname.isEmpty ? '닉네임 없음' : _nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 24),
            _buildAvatarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAvatar() {
    return Stack(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: const BoxDecoration(
            color: Color(0xFFFCE4EC),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedAvatarUrl != null
              ? SvgPicture.network(
                  _selectedAvatarUrl!,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.person, size: 52, color: Color(0xFFF06292)),
        ),
        if (_isSaving)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '아바타 선택',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: kAvatarUrls.length,
          itemBuilder: (context, index) {
            final url = kAvatarUrls[index];
            final isSelected = url == _selectedAvatarUrl;
            return GestureDetector(
              onTap: _isSaving ? null : () => _onAvatarSelected(url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFCE4EC),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF06292)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SvgPicture.network(
                  url,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}