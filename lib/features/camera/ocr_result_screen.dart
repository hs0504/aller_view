import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/analyze_menu_client.dart';
import '../../core/api/analyze_menu_result.dart';
import '../../core/ocr/ocr_result.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.imageBytes,
    required this.ocrResult,
  });

  final Uint8List imageBytes;
  final OcrResult ocrResult;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  bool _isLoading = false;

  void _showRequestPreview({
    required List<String> lines,
    required String title,
    String? rawText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestPreviewBottomSheet(
        title: title,
        requestUrl: AnalyzeMenuClient.requestUrl,
        requestJson: AnalyzeMenuClient.buildPrettyRequestJson(lines),
        lines: lines,
        rawText: rawText,
      ),
    );
  }

  Future<void> _onAnalyzeTap() async {
    setState(() => _isLoading = true);

    try {
      final response = await AnalyzeMenuClient.analyzeMenu(widget.ocrResult.lines);
      if (!mounted) return;
      _showDebugBottomSheet(response: response);
    } on AnalyzeMenuException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDebugBottomSheet({required AnalyzeMenuResponse response}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DebugBottomSheet(response: response),
    );
  }

  void _showPasteTextDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('텍스트 붙여넣기'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              minLines: 8,
              maxLines: 16,
              decoration: const InputDecoration(
                hintText: 'OCR 원본 텍스트를 붙여넣어 주세요',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final rawText = controller.text.trim();
                if (rawText.isEmpty) return;

                Navigator.pop(dialogContext);
                final lines = AnalyzeMenuClient.buildLinesFromRawText(rawText);
                _showRequestPreview(
                  lines: lines,
                  title: '붙여넣은 텍스트 기준 요청 JSON',
                  rawText: rawText,
                );
              },
              child: const Text('JSON 만들기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded, color: Colors.black87),
            onPressed: _showPasteTextDialog,
            tooltip: '텍스트 붙여넣기',
          ),
        ],
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
                  _PhotoThumbnail(imageBytes: widget.imageBytes),
                  const SizedBox(height: 24),
                  _ExtractedTextSection(ocrResult: widget.ocrResult),
                ],
              ),
            ),
          ),
          _BottomAction(
            ocrResult: widget.ocrResult,
            isLoading: _isLoading,
            onAnalyzeTap: _onAnalyzeTap,
            onPreviewTap: () => _showRequestPreview(
              lines: widget.ocrResult.lines,
              title: 'OCR 추출 결과 기준 요청 JSON',
              rawText: widget.ocrResult.fullText,
            ),
            onPasteTap: _showPasteTextDialog,
          ),
        ],
      ),
    );
  }
}

class _DebugBottomSheet extends StatefulWidget {
  const _DebugBottomSheet({required this.response});

  final AnalyzeMenuResponse response;

  @override
  State<_DebugBottomSheet> createState() => _DebugBottomSheetState();
}

class _DebugBottomSheetState extends State<_DebugBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _requestSummary => [
        'POST ${widget.response.requestUrl}',
        '',
        widget.response.requestJson,
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'API 응답 결과  ·  ${widget.response.items.length}개 항목',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4CAF50),
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '파싱된 결과'),
                Tab(text: '요청 JSON'),
                Tab(text: '응답 Raw'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.response.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _ParsedItemCard(item: widget.response.items[i]),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _requestSummary,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF9CDCFE),
                        height: 1.6,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      widget.response.rawResponseBody,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF9CDCFE),
                        height: 1.6,
                      ),
                    ),
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

class _RequestPreviewBottomSheet extends StatefulWidget {
  const _RequestPreviewBottomSheet({
    required this.title,
    required this.requestUrl,
    required this.requestJson,
    required this.lines,
    this.rawText,
  });

  final String title;
  final String requestUrl;
  final String requestJson;
  final List<String> lines;
  final String? rawText;

  @override
  State<_RequestPreviewBottomSheet> createState() =>
      _RequestPreviewBottomSheetState();
}

class _RequestPreviewBottomSheetState extends State<_RequestPreviewBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _requestSummary => [
        'POST ${widget.requestUrl}',
        '',
        widget.requestJson,
      ].join('\n');

  String get _rawTextSummary {
    return [
      widget.rawText?.isEmpty ?? true ? '(empty)' : widget.rawText!,
    ].join('\n');
  }

  Future<void> _copyRequestJson() async {
    await Clipboard.setData(ClipboardData(text: widget.requestJson));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('요청 JSON을 클립보드에 복사했습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.title}  ·  ${widget.lines.length}개 항목',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copyRequestJson,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('JSON 복사'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4CAF50),
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '항목 목록'),
                Tab(text: '요청 JSON'),
                Tab(text: '원본 텍스트'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RequestItemCard(
                      itemId: 'box_${(i + 1).toString().padLeft(3, '0')}',
                      rawText: widget.lines[i],
                    ),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _copyRequestJson,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('실제 전송 JSON 복사'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _requestSummary,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF9CDCFE),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _rawTextSummary,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF9CDCFE),
                        height: 1.6,
                      ),
                    ),
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

class _ParsedItemCard extends StatelessWidget {
  const _ParsedItemCard({required this.item});

  final AnalyzedMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.itemId,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'original   ',
            value: item.originalText,
            color: const Color(0xFFCE9178),
          ),
          const SizedBox(height: 4),
          _DebugRow(
            label: 'translated ',
            value: item.translatedText,
            color: const Color(0xFF9CDCFE),
          ),
          const SizedBox(height: 4),
          _DebugRow(
            label: 'normalized ',
            value: item.normalizedText,
            color: const Color(0xFFDCDCAA),
          ),
        ],
      ),
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  const _RequestItemCard({
    required this.itemId,
    required this.rawText,
  });

  final String itemId;
  final String rawText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              itemId,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'raw_text',
            value: rawText,
            color: const Color(0xFFCE9178),
          ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      ],
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
        const SizedBox(height: 10),
        _ExtractionStrategyBadge(label: ocrResult.strategyLabel),
        const SizedBox(height: 12),
        if (ocrResult.isEmpty)
          const _EmptyTextCard()
        else
          _TextCard(lines: ocrResult.lines),
      ],
    );
  }
}

class _ExtractionStrategyBadge extends StatelessWidget {
  const _ExtractionStrategyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'OCR 경로: $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF06292),
          ),
        ),
      ),
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
  const _BottomAction({
    required this.ocrResult,
    required this.isLoading,
    required this.onAnalyzeTap,
    required this.onPreviewTap,
    required this.onPasteTap,
  });

  final OcrResult ocrResult;
  final bool isLoading;
  final VoidCallback onAnalyzeTap;
  final VoidCallback onPreviewTap;
  final VoidCallback onPasteTap;

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
                onPressed: (ocrResult.isEmpty || isLoading) ? null : onAnalyzeTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'AI 서버로 분석 요청',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: ocrResult.isEmpty ? null : onPreviewTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF06292),
                  side: const BorderSide(color: Color(0xFFF06292)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '요청 JSON 미리보기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onPasteTap,
                child: const Text(
                  '텍스트 붙여넣어 JSON 만들기',
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
