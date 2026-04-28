import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../network/dio_client.dart';
import '../../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchReviews();
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
        final data = response.data;
        setState(() {
          _reviews = (data['reviews'] as List<dynamic>?) ?? [];
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 로그인 화면으로 이동
            },
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? const Center(
                        child: Text(
                          "아직 리뷰가 없습니다",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final bool positive =
                              review['positive'] as bool? ?? true;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  positive ? '' : '',
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    review['content'] as String? ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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