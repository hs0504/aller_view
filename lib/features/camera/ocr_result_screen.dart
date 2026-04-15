import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ocr/ocr_result.dart';

class OcrResultScreen extends StatelessWidget {
  const OcrResultScreen({
    super.key,
    required this.imageBytes,
    required this.ocrResult,
  });

  final Uint8List imageBytes;
  final OcrResult ocrResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '메뉴판 인식 결과',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoThumbnail(imageBytes: imageBytes),
                  const SizedBox(height: 24),
                  _ExtractedTextSection(ocrResult: ocrResult),
                ],
              ),
            ),
          ),
          _BottomAction(ocrResult: ocrResult),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.memory(imageBytes, fit: BoxFit.cover),
      ),
    );
  }
}

class _ExtractedTextSection extends StatelessWidget {
  const _ExtractedTextSection({required this.ocrResult});

  final OcrResult ocrResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_fields, size: 18, color: Color(0xFFF06292)),
            const SizedBox(width: 6),
            const Text(
              '추출된 텍스트',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${ocrResult.lines.length}줄',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ocrResult.isEmpty)
          const _EmptyTextCard()
        else
          _TextCard(lines: ocrResult.lines),
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lines.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            lines[index],
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _EmptyTextCard extends StatelessWidget {
  const _EmptyTextCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            '텍스트를 인식하지 못했습니다.\n메뉴판이 잘 보이도록 다시 촬영해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.ocrResult});

  final OcrResult ocrResult;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ocrResult.isEmpty
                    ? null
                    : () {
                        // TODO: 백엔드 연결 시 ocrResult.fullText 전달
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('백엔드 연결은 다음 단계에서 구현됩니다.'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '백엔드로 분석 요청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '다시 촬영하기',
                  style: TextStyle(color: Colors.black45, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
