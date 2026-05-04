import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/analyze_menu_result.dart';
import '../../core/api/menu_detail_client.dart';
import '../../core/ocr/ocr_result.dart';

Color _allergyColor(AllergyRisk risk) => switch (risk) {
      AllergyRisk.danger => const Color(0xFFE53935),
      AllergyRisk.caution => const Color(0xFFFB8C00),
      AllergyRisk.safe => const Color(0xFF43A047),
      AllergyRisk.unknown => const Color(0xFF757575),
    };

IconData _allergyIcon(AllergyRisk risk) => switch (risk) {
      AllergyRisk.danger => Icons.dangerous_rounded,
      AllergyRisk.caution => Icons.warning_amber_rounded,
      AllergyRisk.safe => Icons.check_circle_rounded,
      AllergyRisk.unknown => Icons.help_outline_rounded,
    };

const double _overlayBadgeRowHeight = 24.0;
const double _overlayBadgeHeight = 20.0;
const double _overlayBadgeHorizontalPadding = 8.0;
const double _overlayBadgeIconSize = 11.0;
const double _overlayBadgeIconGap = 3.0;
const double _overlayBadgeFontSize = 10.0;
const double _overlayBadgeSpacing = 4.0;
const double _overlayTextRightSafetyPadding = 6.0;
const double _overlayTextWidthSafetyBuffer = 2.0;

class OverlayDebugInfo {
  const OverlayDebugInfo({
    required this.requestUrl,
    required this.requestJson,
    required this.ocrLines,
    this.failureMessage,
  });

  final String requestUrl;
  final String requestJson;
  final List<String> ocrLines;
  final String? failureMessage;
}

class OverlayResultScreen extends StatelessWidget {
  const OverlayResultScreen({
    super.key,
    required this.imageBytes,
    required this.displayImageWidth,
    required this.displayImageHeight,
    required this.ocrResult,
    required this.response,
    this.isDummy = false,
    this.debugInfo,
  });

  final Uint8List imageBytes;
  final double displayImageWidth;
  final double displayImageHeight;
  final OcrResult ocrResult;
  final AnalyzeMenuResponse response;
  final bool isDummy;
  final OverlayDebugInfo? debugInfo;

  Map<String, AnalyzedMenuItem> get _itemMap => {
        for (final item in response.items) item.itemId: item,
      };

  Set<String> get _recommendedItemIds => {
        for (final item in response.recommendations) item.itemId,
      };

  void _showDebugInfo(BuildContext context) {
    final info = debugInfo;
    if (info == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OverlayDebugSheet(debugInfo: info),
    );
  }

  void _showApiDebugInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ApiDebugSheet(
        response: response,
        ocrLines: ocrResult.lines,
        failureMessage: debugInfo?.failureMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '오버레이 결과',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _showApiDebugInfo(context),
            tooltip: '디버그',
          ),
        ],
      ),
      body: Column(
        children: [
          if (isDummy)
            _DummyBanner(
              onPressed: debugInfo == null ? null : () => _showDebugInfo(context),
            ),
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
              isDummy: isDummy,
            ),
          ),
        ],
      ),
    );
  }
}

class _DummyBanner extends StatelessWidget {
  const _DummyBanner({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, color: Color(0xFFFFC107), size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '테스트용 더미 결과입니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onPressed != null)
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('테스트 정보'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    required this.isDummy,
  });

  final Uint8List imageBytes;
  final double ocrImageWidth;
  final double ocrImageHeight;
  final double displayImageWidth;
  final double displayImageHeight;
  final OcrResult ocrResult;
  final Map<String, AnalyzedMenuItem> itemMap;
  final Set<String> recommendedItemIds;
  final bool isDummy;

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
                '오버레이 좌표 정보를 불러오지 못했습니다.\n다시 촬영해 주세요.',
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
              clipBehavior: Clip.none,
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
                      isDummy: isDummy,
                      canvasWidth: canvasWidth,
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

class _OverlayBox extends StatelessWidget {
  const _OverlayBox({
    required this.block,
    required this.item,
    required this.isRecommended,
    required this.isDummy,
    required this.canvasWidth,
    required this.scaleX,
    required this.scaleY,
  });

  final OcrTextBlock block;
  final AnalyzedMenuItem? item;
  final bool isRecommended;
  final bool isDummy;
  final double canvasWidth;
  final double scaleX;
  final double scaleY;

  AllergyRisk get _risk => item?.allergyRisk ?? AllergyRisk.unknown;

  TextPainter _measureText(
    String text,
    TextStyle style,
    TextDirection textDirection, {
    double maxWidth = double.infinity,
    int maxLines = 1,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
  }

  double _measureBadgeWidth(String label, TextDirection textDirection) {
    final badgePainter = _measureText(
      label,
      GoogleFonts.blackHanSans(
        fontSize: _overlayBadgeFontSize,
        height: 1.0,
      ),
      textDirection,
    );

    return _overlayBadgeHorizontalPadding * 2 +
        _overlayBadgeIconSize +
        _overlayBadgeIconGap +
        badgePainter.width;
  }

  double _fitFontSize(
    String text,
    TextDirection textDirection, {
    required double maxWidth,
    required double maxHeight,
    required int maxLines,
  }) {
    var low = 12.0;
    var high = 28.0;
    var best = 12.0;

    while (high - low > 0.25) {
      final mid = (low + high) / 2;
      final painter = _measureText(
        text,
        GoogleFonts.blackHanSans(
          color: Colors.white,
          fontSize: mid,
          height: 1.1,
        ),
        textDirection,
        maxWidth: maxWidth,
        maxLines: maxLines,
      );
      final fits =
          !painter.didExceedMaxLines &&
          painter.width <= maxWidth + 0.1 &&
          painter.height <= maxHeight + 0.1;

      if (fits) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    return best;
  }

  void _showDetail(BuildContext context) {
    if (item == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => isDummy
          ? LegacyMenuDetailSheet(item: item!)
          : _MenuDetailSheet(item: item!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final box = block.boundingBox;
    final originalLeft = box.left * scaleX;
    final top = box.top * scaleY;
    final originalWidth = math.max(box.width * scaleX, 44.0);
    final originalHeight = math.max(box.height * scaleY, 24.0);
    final label = item?.translatedText ?? block.rawText;
    final color = _allergyColor(_risk);
    const recommendedColor = Color(0xFFFFC107);
    final isUnknown = _risk == AllergyRisk.unknown;
    const badgeRowHeight = _overlayBadgeRowHeight;
    final horizontalPadding = originalWidth < 64 ? 4.0 : 6.0;
    final rightTextPadding = horizontalPadding + _overlayTextRightSafetyPadding;
    final verticalPadding = originalHeight < 32 ? 3.0 : 4.0;
    final badgeWidth = isUnknown
        ? 0.0
        : _measureBadgeWidth(_risk.label, textDirection) +
            (isRecommended
                ? _overlayBadgeSpacing +
                    _measureBadgeWidth('추천 메뉴', textDirection)
                : 0.0);
    final probeTextStyle = GoogleFonts.blackHanSans(
      color: Colors.white,
      fontSize: (originalHeight * 0.72).clamp(12.0, 24.0).toDouble(),
      height: 1.1,
    );
    final singleLinePainter = _measureText(
      label,
      probeTextStyle,
      textDirection,
    );
    final desiredWidth = math.max(
      math.max(
        originalWidth,
        singleLinePainter.width +
            horizontalPadding +
            rightTextPadding +
            _overlayTextWidthSafetyBuffer,
      ),
      badgeWidth,
    );
    final overlayWidth = math.min(desiredWidth, canvasWidth);
    final overlayLeft = originalLeft
        .clamp(0.0, math.max(0.0, canvasWidth - overlayWidth))
        .toDouble();
    final wrapsToTwoLines = desiredWidth > canvasWidth;
    final availableTextWidth = math.max(
      1.0,
      overlayWidth - horizontalPadding - rightTextPadding,
    );
    final wrappedPainter = wrapsToTwoLines
        ? _measureText(
            label,
            probeTextStyle,
            textDirection,
            maxWidth: availableTextWidth,
            maxLines: 2,
          )
        : null;
    final overlayHeight = wrapsToTwoLines
        ? math.max(
            originalHeight,
            wrappedPainter!.height + verticalPadding * 2,
          )
        : originalHeight;
    final widthExpansion = math.max(0.0, overlayWidth - originalWidth);
    final textHeightBudget = math.max(
      1.0,
      overlayHeight -
          verticalPadding * 2 +
          (wrapsToTwoLines ? 0.0 : math.min(8.0, widthExpansion * 0.12)),
    );
    final fittedFontSize = _fitFontSize(
      label,
      textDirection,
      maxWidth: availableTextWidth,
      maxHeight: textHeightBudget,
      maxLines: wrapsToTwoLines ? 2 : 1,
    );
    final textStyle = GoogleFonts.blackHanSans(
      color: Colors.white,
      fontSize: fittedFontSize,
      height: 1.1,
    );
    final finalTextPainter = _measureText(
      label,
      textStyle,
      textDirection,
      maxWidth: availableTextWidth,
      maxLines: wrapsToTwoLines ? 2 : 1,
    );
    final resolvedOverlayHeight = math.max(
      overlayHeight,
      finalTextPainter.height + verticalPadding * 2 + 2.0,
    );

    return Positioned(
      left: overlayLeft,
      top: isUnknown ? top : top - badgeRowHeight,
      width: overlayWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUnknown)
                SizedBox(
                  height: badgeRowHeight,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _InfoBadge(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            icon: _allergyIcon(_risk),
                            label: _risk.label,
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: _overlayBadgeSpacing),
                            _InfoBadge(
                              backgroundColor: const Color(0xFFFFD54F),
                              foregroundColor: Colors.black,
                              icon: Icons.star_rounded,
                              label: '추천 메뉴',
                              shadowColor: recommendedColor.withValues(alpha: 0.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: overlayWidth,
                  height: resolvedOverlayHeight,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    rightTextPadding,
                    verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isUnknown ? Colors.white24 : color,
                      width: 2.0,
                    ),
                    boxShadow: isRecommended
                        ? [
                            BoxShadow(
                              color: recommendedColor.withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: wrapsToTwoLines ? 2 : 1,
                      softWrap: wrapsToTwoLines,
                      overflow: TextOverflow.visible,
                      textScaler: TextScaler.noScaling,
                      style: textStyle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.shadowColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadowColor == null
            ? null
            : [
                BoxShadow(
                  color: shadowColor!,
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: SizedBox(
        height: _overlayBadgeHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _overlayBadgeHorizontalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _overlayBadgeIconSize,
                height: _overlayBadgeIconSize,
                child: Icon(icon, color: foregroundColor, size: _overlayBadgeIconSize),
              ),
              const SizedBox(width: _overlayBadgeIconGap),
              Text(
                label,
                style: GoogleFonts.blackHanSans(
                  color: foregroundColor,
                  fontSize: _overlayBadgeFontSize,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDetailSheet extends StatefulWidget {
  const _MenuDetailSheet({required this.item});

  final AnalyzedMenuItem item;

  @override
  State<_MenuDetailSheet> createState() => _MenuDetailSheetState();
}

class _MenuDetailSheetState extends State<_MenuDetailSheet> {
  late Future<MenuDetail> _detailFuture;

  AnalyzedMenuItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<MenuDetail> _loadDetail() async {
    final dishId = _item.dishId;
    if (dishId == null) {
      throw const MenuDetailException('Dish ID가 없어 메뉴 상세 정보를 불러올 수 없습니다.');
    }

    final details = await MenuDetailClient.fetchMenuDetails([dishId]);
    for (final detail in details) {
      if (detail.dishId == dishId) {
        return detail;
      }
    }

    throw const MenuDetailException('해당 메뉴의 상세 정보를 찾지 못했습니다.');
  }

  void _retry() {
    setState(() {
      _detailFuture = _loadDetail();
    });
  }

  Widget _buildImagePlaceholder(String label) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: Colors.white24, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(MenuDetail? detail) {
    if (detail != null && detail.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 160,
          color: const Color(0xFF2C2C2E),
          child: Image.network(
            detail.imageUrl!,
            width: double.infinity,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder('이미지를 불러오지 못했습니다.'),
          ),
        ),
      );
    }

    return _buildImagePlaceholder(
      detail == null ? '이미지 정보를 불러오는 중입니다.' : '등록된 이미지가 없습니다.',
    );
  }

  String _titleText(MenuDetail? detail) {
    if (detail != null && detail.koreanName.trim().isNotEmpty) {
      return detail.koreanName;
    }
    return _item.translatedText;
  }

  @override
  Widget build(BuildContext context) {
    final color = _allergyColor(_item.allergyRisk);
    final icon = _allergyIcon(_item.allergyRisk);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<MenuDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final detail = snapshot.data;
            final error = snapshot.error;
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final errorMessage = error is MenuDetailException
                ? error.message
                : error != null
                    ? '메뉴 상세 정보를 불러오지 못했습니다.'
                    : null;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageSection(detail),
                  const SizedBox(height: 16),
                  _InfoBadge(
                    backgroundColor: color.withValues(alpha: 0.18),
                    foregroundColor: color,
                    icon: icon,
                    label: _item.allergyRisk.label,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _titleText(detail),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _item.originalText,
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLoading
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '메뉴 상세 정보를 불러오는 중입니다.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        : errorMessage != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFFF8A80),
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '상세 정보를 불러오지 못했습니다.',
                                        style: TextStyle(
                                          color: Color(0xFFFF8A80),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _retry,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white24),
                                    ),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('다시 시도'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFFFFB74D),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      detail?.calorieLabel ?? '칼로리 정보 없음',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                  if (_item.detectedAllergens.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      '포함 알레르겐',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _item.detectedAllergens
                          .map(
                            (allergen) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Text(
                                allergen,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LegacyMenuDetailSheet extends StatelessWidget {
  const LegacyMenuDetailSheet({required this.item});

  final AnalyzedMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = _allergyColor(item.allergyRisk);
    final icon = _allergyIcon(item.allergyRisk);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    Text(
                      '메뉴 이미지',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoBadge(
                backgroundColor: color.withValues(alpha: 0.18),
                foregroundColor: color,
                icon: icon,
                label: item.allergyRisk.label,
              ),
              const SizedBox(height: 16),
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
              Text(
                item.originalText,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.local_fire_department_rounded, color: Colors.white24, size: 14),
                  SizedBox(width: 5),
                  Text(
                    '칼로리 정보 준비 중',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
              if (item.detectedAllergens.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '포함 알레르겐',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.detectedAllergens
                      .map(
                        (allergen) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Text(
                            allergen,
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
            ],
          ),
        ),
      ),
    );
  }
}


class _OverlayDebugSheet extends StatelessWidget {
  const _OverlayDebugSheet({required this.debugInfo});

  final OverlayDebugInfo debugInfo;

  String get _ocrSummary {
    if (debugInfo.ocrLines.isEmpty) {
      return '(empty)';
    }

    return List<String>.generate(
      debugInfo.ocrLines.length,
      (index) => '${index + 1}. ${debugInfo.ocrLines[index]}',
    ).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '테스트 정보',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (debugInfo.failureMessage != null) ...[
              const SizedBox(height: 16),
              _DebugSection(
                title: '더미 결과 전환 사유',
                child: SelectableText(
                  debugInfo.failureMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFFCC80),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _DebugSection(
              title: 'OCR 추출 결과',
              child: SelectableText(
                _ocrSummary,
                style: const TextStyle(
                  color: Color(0xFFCE9178),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DebugSection(
              title: '요청 URL',
              child: SelectableText(
                debugInfo.requestUrl,
                style: const TextStyle(
                  color: Color(0xFF9CDCFE),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DebugSection(
              title: '요청 JSON',
              child: SelectableText(
                debugInfo.requestJson,
                style: const TextStyle(
                  color: Color(0xFF9CDCFE),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({
    required this.title,
    required this.child,
    this.copyText,
  });

  final String title;
  final Widget child;
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (copyText != null)
                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: copyText!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('복사됐어요.'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.copy_rounded, size: 16, color: Colors.white38),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ApiDebugSheet extends StatelessWidget {
  const _ApiDebugSheet({
    required this.response,
    required this.ocrLines,
    this.failureMessage,
  });

  final AnalyzeMenuResponse response;
  final List<String> ocrLines;
  final String? failureMessage;

  String get _ocrSummary => ocrLines.isEmpty
      ? '(empty)'
      : ocrLines.indexed.map((e) => '${e.$1 + 1}. ${e.$2}').join('\n');

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'API 디버그 정보',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (failureMessage != null) ...[
              const SizedBox(height: 16),
              _DebugSection(
                title: '오류 메시지',
                copyText: failureMessage,
                child: SelectableText(
                  failureMessage!,
                  style: const TextStyle(color: Color(0xFFFFCC80), fontSize: 13, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _DebugSection(
              title: 'OCR 추출 결과',
              copyText: _ocrSummary,
              child: SelectableText(
                _ocrSummary,
                style: const TextStyle(
                  color: Color(0xFFCE9178),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DebugSection(
              title: '요청 JSON',
              copyText: response.requestJson,
              child: SelectableText(
                response.requestJson,
                style: const TextStyle(
                  color: Color(0xFF9CDCFE),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DebugSection(
              title: '응답 JSON',
              copyText: response.rawResponseBody,
              child: SelectableText(
                response.rawResponseBody,
                style: const TextStyle(
                  color: Color(0xFFB5CEA8),
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
