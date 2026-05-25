import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/data/allergy_data.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/user_prefs.dart';
import '../../service/auth_service.dart';
import 'review_write_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String placeId;
  final String name;
  final String address;
  final String businessType;

  const RestaurantDetailScreen({
    super.key,
    required this.placeId,
    required this.name,
    required this.address,
    required this.businessType,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final DioClient _dioClient = DioClient();
  final AuthService _authService = AuthService();

  List<dynamic> _reviews = [];
  bool _isLoading = true;
  Set<String> _myAllergies = {};
  String? _selectedAllergyFilter; // null = 전체

  static final List<String> _allergyNames =
      allergyItems.map((e) => e['name']!).toList();

  @override
  void initState() {
    super.initState();
    _loadMyAllergiesAndFetch();
  }

  Future<void> _loadMyAllergiesAndFetch() async {
    final indices = await UserPrefs.loadAllergyIndices();
    _myAllergies = Set<String>.from(UserPrefs.allergyNamesFromIndices(indices));
    await _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dioClient.get(
        '/restaurants/${widget.placeId}/reviews',
        queryParams: {
          'name': widget.name,
          'address': widget.address,
          'business_type': widget.businessType,
        },
      );
      if (response != null && response.statusCode == 200) {
        final raw = (response.data['reviews'] as List<dynamic>?) ?? [];
        setState(() {
          _reviews = _sortReviews(raw);
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 내 알레르기와 겹치는 리뷰를 상단에 배치
  List<dynamic> _sortReviews(List<dynamic> raw) {
    final overlapping = <dynamic>[];
    final others = <dynamic>[];
    for (final r in raw) {
      final reviewAllergies = _reviewAllergySet(r);
      if (reviewAllergies.intersection(_myAllergies).isNotEmpty) {
        overlapping.add(r);
      } else {
        others.add(r);
      }
    }
    return [...overlapping, ...others];
  }

  Set<String> _reviewAllergySet(dynamic review) {
    final list = review['allergies'] as List<dynamic>? ?? [];
    return list.cast<String>().toSet();
  }

  List<dynamic> get _filteredReviews {
    if (_selectedAllergyFilter == null) return _reviews;
    return _reviews
        .where((r) => _reviewAllergySet(r).contains(_selectedAllergyFilter))
        .toList();
  }

  Future<void> _onReviewButtonPressed() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final userId = await _authService.getUserId();
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewWriteScreen(
          placeId: widget.placeId,
          userId: userId,
        ),
      ),
    );
    if (result == true) {
      _fetchReviews();
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("로그인 필요"),
        content: const Text("리뷰 작성은 로그인이 필요합니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "로그인하기",
              style: TextStyle(color: Color(0xFFF06292)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주소
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.address,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // 알레르기 필터 드롭다운
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedAllergyFilter,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text(
                        '알레르기 필터 선택',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('전체 보기',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ..._allergyNames.map((name) {
                          final icon = allergyItems
                              .firstWhere((e) => e['name'] == name)['icon']!;
                          return DropdownMenuItem<String?>(
                            value: name,
                            child: Text('$icon $name',
                                style: const TextStyle(fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedAllergyFilter = value),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 리뷰 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReviews.isEmpty
                    ? Center(
                        child: Text(
                          _selectedAllergyFilter == null
                              ? '아직 리뷰가 없습니다'
                              : "'$_selectedAllergyFilter' 알레르기 리뷰가 없습니다",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _filteredReviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _ReviewCard(
                              review: _filteredReviews[index],
                              myAllergies: _myAllergies,
                            ),
                      ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton(
            onPressed: _onReviewButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[300],
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "리뷰 작성",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.myAllergies,
  });

  final dynamic review;
  final Set<String> myAllergies;

  @override
  Widget build(BuildContext context) {
    final username = review['username'] as String? ?? '익명';
    final avatarUrl = review['avatar_url'] as String?;
    final content = review['content'] as String?;
    final menuItems = (review['menu_items'] as List<dynamic>?) ?? [];
    final reviewAllergies =
        ((review['allergies'] as List<dynamic>?) ?? []).cast<String>();
    final overlapping =
        reviewAllergies.where((a) => myAllergies.contains(a)).toSet();
    final hasOverlap = overlapping.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 + 알레르기 배지
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarIcon(url: avatarUrl),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (hasOverlap) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '내 알레르기 일치',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF06292),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 리뷰어 알레르기 태그
          if (reviewAllergies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: reviewAllergies.map((allergyName) {
                final idx =
                    allergyItems.indexWhere((e) => e['name'] == allergyName);
                final icon = idx >= 0 ? allergyItems[idx]['icon']! : '⚠️';
                final isMatch = myAllergies.contains(allergyName);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? const Color(0xFFF06292).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatch
                          ? const Color(0xFFF06292).withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$icon $allergyName',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMatch
                          ? const Color(0xFFD81B60)
                          : Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 메뉴 안전 여부
          if (menuItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: menuItems.map((item) {
                final isSafe = item['is_safe'] as bool? ?? true;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSafe
                        ? Colors.green.withValues(alpha: 0.10)
                        : Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSafe ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: isSafe ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['menu_name'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSafe ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // 리뷰 본문
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const Icon(Icons.person, size: 28, color: Colors.grey);
    }
    return ClipOval(
      child: SvgPicture.network(
        url!,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        placeholderBuilder: (_) =>
            const Icon(Icons.person, size: 28, color: Colors.grey),
      ),
    );
  }
}
