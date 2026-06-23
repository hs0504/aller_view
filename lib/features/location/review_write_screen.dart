import 'package:flutter/material.dart';

import '../../core/network/dio_client.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String placeId;
  final int? userId;

  const ReviewWriteScreen({
    super.key,
    required this.placeId,
    this.userId,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final _contentController = TextEditingController();
  final _menuNameController = TextEditingController();
  final DioClient _dioClient = DioClient();

  final List<Map<String, dynamic>> _menuItems = [];
  bool? _pendingIsSafe;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _menuNameController.dispose();
    super.dispose();
  }

  void _addMenuItem() {
    final name = _menuNameController.text.trim();
    if (name.isEmpty || _pendingIsSafe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴 이름과 안전 여부를 모두 입력해주세요')),
      );
      return;
    }
    setState(() {
      _menuItems.add({'menu_name': name, 'is_safe': _pendingIsSafe});
      _menuNameController.clear();
      _pendingIsSafe = null;
    });
  }

  Future<void> _submit() async {
    if (_menuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴를 1개 이상 추가해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{'menu_items': _menuItems};
      final content = _contentController.text.trim();
      if (content.isNotEmpty) data['content'] = content;

      final response = await _dioClient.post(
        '/restaurants/${widget.placeId}/reviews',
        data: data,
      );

      if (!mounted) return;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 등록되었습니다')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 등록에 실패했습니다')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 등록에 실패했습니다')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메뉴별 평가
            const Text(
              '메뉴별 평가',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // 메뉴 입력 행
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _menuNameController,
                    decoration: _inputDecoration('메뉴 이름 입력'),
                  ),
                ),
                const SizedBox(width: 8),
                _SafeToggle(
                  value: _pendingIsSafe,
                  onChanged: (v) => setState(() => _pendingIsSafe = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addMenuItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('메뉴 추가'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink[300],
                  side: BorderSide(color: Colors.pink[200]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // 추가된 메뉴 목록
            if (_menuItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._menuItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isSafe = item['is_safe'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSafe
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSafe
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSafe ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isSafe ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['menu_name'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        isSafe ? '안전' : '위험',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSafe ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.grey,
                        onPressed: () =>
                            setState(() => _menuItems.removeAt(idx)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // 코멘트 (선택)
            const Text(
              '한마디 (선택)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: _inputDecoration(
                '- 식당의 알레르기 대응은 어땠나요?\n- 직원이 친절하게 안내해줬나요?',
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  '등록하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _SafeToggle extends StatelessWidget {
  const _SafeToggle({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Btn(
          label: '안전',
          color: Colors.green,
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 6),
        _Btn(
          label: '위험',
          color: Colors.red,
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Colors.black54,
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
//
// import '../../core/network/dio_client.dart';
//
// class ReviewWriteScreen extends StatefulWidget {
//   final String placeId;
//   final int? userId;
//
//   const ReviewWriteScreen({
//     super.key,
//     required this.placeId,
//     this.userId,
//   });
//
//   @override
//   State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
// }
//
// class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _contentController = TextEditingController();
//   final DioClient _dioClient = DioClient();
//
//   bool? _positive;
//   bool _isSubmitting = false;
//
//   @override
//   void dispose() {
//     _contentController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _submit() async {
//     if (_positive == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('괜찮았어요 또는 안좋았어요를 선택해주세요')),
//       );
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//     try {
//       final content = _contentController.text.trim();
//       final data = <String, dynamic>{'positive': _positive};
//       if (content.isNotEmpty) data['content'] = content;
//
//       final response = await _dioClient.post(
//         '/restaurants/${widget.placeId}/reviews',
//         data: data,
//       );
//
//       if (!mounted) return;
//
//       if (response != null &&
//           (response.statusCode == 200 || response.statusCode == 201)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('리뷰가 등록되었습니다')),
//         );
//         Navigator.pop(context, true);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('리뷰 등록에 실패했습니다')),
//         );
//       }
//     } catch (_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('리뷰 등록에 실패했습니다')),
//       );
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('리뷰 작성'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 '알레르기 괜찮았나요?',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _PositiveButton(
//                       label: '괜찮았어요',
//                       emoji: '❤️',
//                       selected: _positive == true,
//                       color: Colors.blue[400]!,
//                       onTap: () => setState(() => _positive = true),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _PositiveButton(
//                       label: '안좋았어요',
//                       emoji: '💔',
//                       selected: _positive == false,
//                       color: Colors.red[300]!,
//                       onTap: () => setState(() => _positive = false),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//
//               const Text(
//                 '리뷰 내용 (선택)',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: _contentController,
//                 maxLines: 5,
//                 decoration: _inputDecoration(
//                   '- 먹고 괜찮았던 메뉴를 알려주세요\n- 식당의 알레르기 대응은 어땠나요?',
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.pink[300],
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: _isSubmitting
//                       ? const SizedBox(
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           '등록하기',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   InputDecoration _inputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(color: Colors.grey[400]),
//       filled: true,
//       fillColor: Colors.grey[100],
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//     );
//   }
// }
//
// class _PositiveButton extends StatelessWidget {
//   final String label;
//   final String emoji;
//   final bool selected;
//   final Color color;
//   final VoidCallback onTap;
//
//   const _PositiveButton({
//     required this.label,
//     required this.emoji,
//     required this.selected,
//     required this.color,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           color: selected ? color.withValues(alpha: 0.15) : Colors.grey[100],
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: selected ? color : Colors.grey[300]!,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(emoji, style: const TextStyle(fontSize: 18)),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: selected ? FontWeight.bold : FontWeight.normal,
//                 color: selected ? color : Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }