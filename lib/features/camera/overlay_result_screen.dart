import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/analyze_menu_result.dart';
import '../../core/ocr/ocr_result.dart';

// ── 공통 헬퍼 ────────────────────────────────────────────────────────────────

Color _allergyColor(AllergyRisk risk) => switch (risk) {
      AllergyRisk.danger  => const Color(0xFFE53935),
      AllergyRisk.caution => const Color(0xFFFB8C00),
      AllergyRisk.safe    => const Color(0xFF43A047),
      AllergyRisk.unknown => const Color(0xFF757575),
    };

IconData _allergyIcon(AllergyRisk risk) => switch (risk) {
      AllergyRisk.danger  => Icons.dangerous_rounded,
      AllergyRisk.caution => Icons.warning_amber_rounded,
      AllergyRisk.safe    => Icons.check_circle_rounded,
      AllergyRisk.unknown => Icons.help_outline_rounded,
    };

// ── Root Screen ───────────────────────────────────────────────────────────────

/// Renders allergy overlays on top of OCR blocks.
///
/// The image and overlay boxes share the same pixel canvas so the rendered
/// image and its OCR coordinates stay aligned.
class OverlayResultScreen extends StatelessWidget {
  const OverlayResultScreen({
    super.key,
    required this.imageBytes,
    required this.displayImageWidth,
    required this.displayImageHeight,
    required this.ocrResult,
    required this.response,
    this.isDummy = false,
  });

  final Uint8List imageBytes;
  final double displayImageWidth;
  final double displayImageHeight;
  final OcrResult ocrResult;
  final AnalyzeMenuResponse response;
  final bool isDummy;

  Map<String, AnalyzedMenuItem> get _itemMap => {
        for (final item in response.items) item.itemId: item,
      };
  Set<String> get _recommendedItemIds => {
        for (final item in response.recommendations) item.itemId,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '오버레이 결과',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isDummy) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DUMMY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _OverlayImageView(
              imageBytes: imageBytes,
              ocrImageWidth: ocrResult.imageWidth,
              ocrImageHeight: ocrResult.imageHeight,
              displayImageWidth: displayImageWidth,
              displayImageHeight: displayImageHeight,
              ocrResult: ocrResult,
              itemMap: _itemMap,
              recommendedItemIds: _recommendedItemIds,
            ),
          ),
          _BottomSummaryPanel(response: response),
        ],
      ),
    );
  }
}

// ── Overlay Image View ────────────────────────────────────────────────────────

class _OverlayImageView extends StatelessWidget {
  const _OverlayImageView({
    required this.imageBytes,
    required this.ocrImageWidth,
    required this.ocrImageHeight,
    required this.displayImageWidth,
    required this.displayImageHeight,
    required this.ocrResult,
    required this.itemMap,
    required this.recommendedItemIds,
  });

  final Uint8List imageBytes;
  final double ocrImageWidth;
  final double ocrImageHeight;
  final double displayImageWidth;
  final double displayImageHeight;
  final OcrResult ocrResult;
  final Map<String, AnalyzedMenuItem> itemMap;
  final Set<String> recommendedItemIds;

  bool _shouldRenderOverlay(AnalyzedMenuItem? item) {
    return item != null && item.translatedText.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (ocrImageWidth <= 0 || ocrImageHeight <= 0) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.memory(imageBytes, fit: BoxFit.contain),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '오버레이 좌표 정보를 불러오지 못했어요.\n다시 촬영해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    final canvasWidth = displayImageWidth > 0 ? displayImageWidth : ocrImageWidth;
    final canvasHeight =
        displayImageHeight > 0 ? displayImageHeight : ocrImageHeight;
    final scaleX = canvasWidth / ocrImageWidth;
    final scaleY = canvasHeight / ocrImageHeight;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(imageBytes, fit: BoxFit.fill),
                ),
                for (final block in ocrResult.blocks)
                  if (_shouldRenderOverlay(itemMap[block.itemId]))
                    _OverlayBox(
                      block: block,
                      item: itemMap[block.itemId],
                      isRecommended: recommendedItemIds.contains(block.itemId),
                      scaleX: scaleX,
                      scaleY: scaleY,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay Box ───────────────────────────────────────────────────────────────

class _OverlayBox extends StatelessWidget {
  const _OverlayBox({
    required this.block,
    required this.item,
    required this.isRecommended,
    required this.scaleX,
    required this.scaleY,
  });

  final OcrTextBlock block;
  final AnalyzedMenuItem? item;
  final bool isRecommended;
  final double scaleX;
  final double scaleY;

  AllergyRisk get _risk => item?.allergyRisk ?? AllergyRisk.unknown;

  void _showDetail(BuildContext context) {
    if (item == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MenuDetailSheet(item: item!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box   = block.boundingBox;
    final left  = box.left * scaleX;
    final top   = box.top  * scaleY;
    final w     = math.max(box.width  * scaleX, 44.0);
    final h     = math.max(box.height * scaleY, 22.0);
    final label = item?.translatedText ?? block.rawText;
    final color = _allergyColor(_risk);
    final fontSize = (h * 0.48).clamp(11.0, 36.0);

    return Positioned(
      left: left, top: top, width: w, height: h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () => _showDetail(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 메인 박스 — 번역 텍스트 전용
              Container(
                width: w,
                height: h,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color, width: 2.0),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: GoogleFonts.blackHanSans(
                    color: Colors.white,
                    fontSize: fontSize,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              // 위험도 배지 — 좌측 상단 경계에 걸치게 배치
              Positioned(
                top: -14,
                left: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_allergyIcon(_risk), color: Colors.white, size: 8),
                          const SizedBox(width: 2),
                          Text(
                            _risk.label,
                            style: GoogleFonts.blackHanSans(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF06292),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '추천',
                          style: GoogleFonts.blackHanSans(
                            color: Colors.white,
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Detail Sheet ─────────────────────────────────────────────────────────

class _MenuDetailSheet extends StatelessWidget {
  const _MenuDetailSheet({required this.item});

  final AnalyzedMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = _allergyColor(item.allergyRisk);
    final icon  = _allergyIcon(item.allergyRisk);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 음식 이미지 (TODO: 실제 이미지로 교체)
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, color: Colors.white24, size: 36),
                SizedBox(height: 8),
                Text('음식 이미지', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 위험도 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(
                  item.allergyRisk.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 번역된 메뉴명 (메인)
          Text(
            item.translatedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),

          // 원문
          Text(
            item.originalText,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          if (item.dishId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dish ID ${item.dishId}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),

          // 칼로리 (TODO: 실제 데이터 연결)
          Row(
            children: const [
              Icon(Icons.local_fire_department_rounded, color: Colors.white24, size: 14),
              SizedBox(width: 5),
              Text('칼로리 정보 준비 중', style: TextStyle(color: Colors.white24, fontSize: 13)),
            ],
          ),

          // 알러젠 목록
          if (item.detectedAllergens.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '포함 알러젠',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: item.detectedAllergens
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: color.withValues(alpha: 0.40)),
                      ),
                      child: Text(
                        a,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Bottom Summary Panel ──────────────────────────────────────────────────────

class _BottomSummaryPanel extends StatelessWidget {
  const _BottomSummaryPanel({required this.response});

  final AnalyzeMenuResponse response;

  Map<AllergyRisk, int> _countByRisk() {
    final counts = <AllergyRisk, int>{};
    for (final item in response.items) {
      counts[item.allergyRisk] = (counts[item.allergyRisk] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countByRisk();
    final recommendationCount = response.recommendations.length;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 ${response.items.length}개 항목 분석됨',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (recommendationCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '추천 메뉴 $recommendationCount개',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              for (final risk in AllergyRisk.values)
                if ((counts[risk] ?? 0) > 0)
                  _RiskChip(risk: risk, count: counts[risk]!),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.risk, required this.count});

  final AllergyRisk risk;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = _allergyColor(risk);
    final icon  = _allergyIcon(risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            '${risk.label}  $count건',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
