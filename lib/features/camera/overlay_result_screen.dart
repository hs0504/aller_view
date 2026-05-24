import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/allergy_data.dart';
import '../../core/data/order_assistant_data.dart';
import '../../core/api/analyze_menu_result.dart';
import '../../core/api/menu_detail_client.dart';
import '../../core/ocr/ocr_result.dart';
import '../../core/storage/user_prefs.dart';

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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
              onPressed: debugInfo == null
                  ? null
                  : () => _showDebugInfo(context),
            ),
          Expanded(
            child: _OverlayImageView(
              imageBytes: imageBytes,
              ocrImageWidth: ocrResult.imageWidth,
              ocrImageHeight: ocrResult.imageHeight,
              displayImageWidth: displayImageWidth,
              displayImageHeight: displayImageHeight,
              ocrResult: ocrResult,
              items: response.items,
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
          border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: Color(0xFFFFC107),
                size: 18,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
    required this.items,
    required this.recommendedItemIds,
    required this.isDummy,
  });

  final Uint8List imageBytes;
  final double ocrImageWidth;
  final double ocrImageHeight;
  final double displayImageWidth;
  final double displayImageHeight;
  final OcrResult ocrResult;
  final List<AnalyzedMenuItem> items;
  final Set<String> recommendedItemIds;
  final bool isDummy;

  String? _displayTextFor(AnalyzedMenuItem item) {
    String? firstNonEmpty(List<String?> values) {
      for (final value in values) {
        if (value != null && value.trim().isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    return switch (item.itemType) {
      'menu_name' => firstNonEmpty([
        item.content.translatedText,
        item.content.normalizedText,
        item.content.rawText,
      ]),
      'price' => firstNonEmpty([
        item.content.translatedText,
        item.content.rawText,
      ]),
      'description' => firstNonEmpty([item.content.translatedText]),
      _ => null,
    };
  }

  Rect? _rectForSourceBoxes(
    List<String> sourceBoxIds,
    Map<String, OcrTextBlock> blockMap,
    double scaleX,
    double scaleY,
  ) {
    Rect? rect;
    for (final boxId in sourceBoxIds) {
      final block = blockMap[boxId];
      if (block == null) continue;

      final box = block.boundingBox;
      final scaled = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );
      rect = rect == null ? scaled : rect.expandToInclude(scaled);
    }
    return rect;
  }

  List<double> _normalizedRatios(List<AnalyzedMenuItem> group) {
    final ratios = group.map((item) => item.layoutRatio).toList();
    if (ratios.any((ratio) => ratio == null || ratio <= 0)) {
      return List<double>.filled(group.length, 1 / group.length);
    }

    final total = ratios.fold<double>(0, (sum, ratio) => sum + ratio!);
    if (total <= 0) {
      return List<double>.filled(group.length, 1 / group.length);
    }

    return ratios.map((ratio) => ratio! / total).toList();
  }

  List<_ResolvedOverlayItem> _resolveOverlayItems({
    required Map<String, OcrTextBlock> blockMap,
    required double scaleX,
    required double scaleY,
  }) {
    final renderable = <_PendingOverlayItem>[];
    for (final item in items) {
      final text = _displayTextFor(item);
      if (text == null) continue;

      final sourceBoxIds = item.sourceBoxIds.isNotEmpty
          ? item.sourceBoxIds
          : <String>[item.itemId];
      final rect = _rectForSourceBoxes(sourceBoxIds, blockMap, scaleX, scaleY);
      if (rect == null || rect.isEmpty) continue;

      renderable.add(
        _PendingOverlayItem(
          item: item,
          text: text,
          sourceBoxIds: sourceBoxIds,
          sourceRect: rect,
        ),
      );
    }

    final groupedBySingleSource = <String, List<_PendingOverlayItem>>{};
    final resolved = <_ResolvedOverlayItem>[];

    for (final pending in renderable) {
      if (pending.sourceBoxIds.length == 1) {
        groupedBySingleSource
            .putIfAbsent(pending.sourceBoxIds.single, () => [])
            .add(pending);
      } else {
        resolved.add(pending.resolve(pending.sourceRect));
      }
    }

    for (final group in groupedBySingleSource.values) {
      if (group.length == 1) {
        resolved.add(group.single.resolve(group.single.sourceRect));
        continue;
      }

      final direction = group
          .map((item) => item.item.layoutDirection)
          .firstWhere(
            (direction) => direction == 'horizontal' || direction == 'vertical',
            orElse: () => 'horizontal',
          );
      final ratios = _normalizedRatios(group.map((item) => item.item).toList());
      var offset = 0.0;

      for (var i = 0; i < group.length; i++) {
        final pending = group[i];
        final ratio = ratios[i];
        final rect = pending.sourceRect;
        final splitRect = direction == 'vertical'
            ? Rect.fromLTWH(
                rect.left,
                rect.top + rect.height * offset,
                rect.width,
                rect.height * ratio,
              )
            : Rect.fromLTWH(
                rect.left + rect.width * offset,
                rect.top,
                rect.width * ratio,
                rect.height,
              );
        resolved.add(pending.resolve(splitRect, splitDirection: direction));
        offset += ratio;
      }
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    if (ocrImageWidth <= 0 || ocrImageHeight <= 0) {
      return Stack(
        children: [
          Positioned.fill(child: Image.memory(imageBytes, fit: BoxFit.contain)),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final canvasWidth = displayImageWidth > 0
        ? displayImageWidth
        : ocrImageWidth;
    final canvasHeight = displayImageHeight > 0
        ? displayImageHeight
        : ocrImageHeight;
    final scaleX = canvasWidth / ocrImageWidth;
    final scaleY = canvasHeight / ocrImageHeight;
    final blockMap = {
      for (final block in ocrResult.blocks) block.itemId: block,
    };
    final overlayItems = _resolveOverlayItems(
      blockMap: blockMap,
      scaleX: scaleX,
      scaleY: scaleY,
    );
    final guideItems = _OverlayGuideItem.fromOverlayItems(
      overlayItems,
      recommendedItemIds,
      canvasWidth,
    );

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
                for (final overlayItem in overlayItems)
                  _OverlayBox(
                    overlayItem: overlayItem,
                    isRecommended: recommendedItemIds.contains(
                      overlayItem.item.itemId,
                    ),
                    isDummy: isDummy,
                    canvasWidth: canvasWidth,
                  ),
                if (guideItems.isNotEmpty)
                  _OverlayGuideLayer(
                    items: guideItems,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingOverlayItem {
  const _PendingOverlayItem({
    required this.item,
    required this.text,
    required this.sourceBoxIds,
    required this.sourceRect,
  });

  final AnalyzedMenuItem item;
  final String text;
  final List<String> sourceBoxIds;
  final Rect sourceRect;

  _ResolvedOverlayItem resolve(Rect rect, {String? splitDirection}) {
    return _ResolvedOverlayItem(
      item: item,
      text: text,
      rect: rect,
      splitDirection: splitDirection,
    );
  }
}

class _ResolvedOverlayItem {
  const _ResolvedOverlayItem({
    required this.item,
    required this.text,
    required this.rect,
    this.splitDirection,
  });

  final AnalyzedMenuItem item;
  final String text;
  final Rect rect;
  final String? splitDirection;
}

class _OverlayGuideItem {
  const _OverlayGuideItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.targetRect,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Rect targetRect;

  static List<_OverlayGuideItem> fromOverlayItems(
    List<_ResolvedOverlayItem> overlayItems,
    Set<String> recommendedItemIds,
    double canvasWidth,
  ) {
    _ResolvedOverlayItem? firstWhere(bool Function(_ResolvedOverlayItem) test) {
      for (final item in overlayItems) {
        if (test(item)) return item;
      }
      return null;
    }

    final menuItem = firstWhere((item) => item.item.itemType == 'menu_name');
    final riskItem = firstWhere(_hasVisibleRiskBadge);
    final recommendedItem = firstWhere(
      (item) => _hasVisibleRecommendationBadge(item, recommendedItemIds),
    );
    final priceItem = firstWhere(
      (item) =>
          item.item.itemType == 'price' &&
          item.item.convertedPrice != null &&
          item.item.convertedPrice!.trim().isNotEmpty,
    );

    return [
      if (menuItem != null)
        _OverlayGuideItem(
          title: '메뉴 상세정보',
          message: '라벨을 터치하면 메뉴 상세정보를 볼 수 있어요.',
          icon: Icons.touch_app_rounded,
          color: const Color(0xFFFF6F91),
          targetRect: menuItem.rect,
        ),
      if (riskItem != null)
        _OverlayGuideItem(
          title: '알레르기 위험도',
          message: '위험도 라벨로 내 알레르기와 관련된 위험을 확인하세요.',
          icon: Icons.health_and_safety_rounded,
          color: _allergyColor(riskItem.item.allergyRisk),
          targetRect: _riskBadgeRect(riskItem, canvasWidth),
        ),
      if (recommendedItem != null)
        _OverlayGuideItem(
          title: '추천 메뉴',
          message: '추천 라벨은 비교적 선택하기 좋은 메뉴를 뜻해요.',
          icon: Icons.star_rounded,
          color: const Color(0xFFFFC107),
          targetRect: _recommendationBadgeRect(recommendedItem, canvasWidth),
        ),
      if (priceItem != null)
        _OverlayGuideItem(
          title: '가격 환산',
          message: '가격 라벨을 터치하면 대략적인 환산 금액을 볼 수 있어요.',
          icon: Icons.currency_exchange_rounded,
          color: const Color(0xFF42A5F5),
          targetRect: priceItem.rect,
        ),
    ];
  }

  static bool _isVerticalSplit(_ResolvedOverlayItem item) =>
      item.splitDirection == 'vertical';

  static bool _hasVisibleRiskBadge(_ResolvedOverlayItem item) {
    if (!item.item.hasRiskAnalysis) return false;
    return true;
  }

  static bool _hasVisibleRecommendationBadge(
    _ResolvedOverlayItem item,
    Set<String> recommendedItemIds,
  ) {
    if (!recommendedItemIds.contains(item.item.itemId)) return false;
    return item.item.hasRiskAnalysis || _isVerticalSplit(item);
  }

  static Rect _sideBadgeRect(_ResolvedOverlayItem item, double canvasWidth) {
    const sideBadgeWidth = 24.0;
    const sideBadgeGap = 4.0;
    final left = math.max(0.0, item.rect.left - sideBadgeWidth - sideBadgeGap);
    final right = math.min(canvasWidth, item.rect.right);
    return Rect.fromLTRB(left, item.rect.top, right, item.rect.bottom);
  }

  static Rect _topBadgeRect({
    required _ResolvedOverlayItem item,
    required double canvasWidth,
    required double leftOffset,
    required double width,
  }) {
    final left = math.min(
      canvasWidth,
      math.max(0.0, item.rect.left + leftOffset),
    );
    final right = math.min(canvasWidth, left + width);
    return Rect.fromLTWH(
      left,
      math.max(0.0, item.rect.top - _overlayBadgeHeight),
      math.max(1.0, right - left),
      _overlayBadgeHeight,
    );
  }

  static Rect _riskBadgeRect(_ResolvedOverlayItem item, double canvasWidth) {
    if (_isVerticalSplit(item)) {
      return _sideBadgeRect(item, canvasWidth);
    }

    return _topBadgeRect(
      item: item,
      canvasWidth: canvasWidth,
      leftOffset: 0,
      width: 56,
    );
  }

  static Rect _recommendationBadgeRect(
    _ResolvedOverlayItem item,
    double canvasWidth,
  ) {
    if (_isVerticalSplit(item)) {
      return _sideBadgeRect(item, canvasWidth);
    }

    return _topBadgeRect(
      item: item,
      canvasWidth: canvasWidth,
      leftOffset: item.item.hasRiskAnalysis ? 56 + _overlayBadgeSpacing : 0,
      width: 76,
    );
  }
}

class _OverlayGuideLayer extends StatefulWidget {
  const _OverlayGuideLayer({
    required this.items,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final List<_OverlayGuideItem> items;
  final double canvasWidth;
  final double canvasHeight;

  @override
  State<_OverlayGuideLayer> createState() => _OverlayGuideLayerState();
}

class _OverlayGuideLayerState extends State<_OverlayGuideLayer> {
  late final PageController _pageController;
  var _pageIndex = 0;
  var _guideStarted = false;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get _scale => math.max(1.0, widget.canvasWidth / 360.0);

  void _dismiss() {
    setState(() => _dismissed = true);
  }

  void _movePage(int offset) {
    final next = (_pageIndex + offset)
        .clamp(0, widget.items.length - 1)
        .toInt();
    if (next == _pageIndex) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Rect _highlightRect(_OverlayGuideItem item) {
    final padding = 7.0 * _scale;
    return Rect.fromLTRB(
      math.max(0.0, item.targetRect.left - padding),
      math.max(0.0, item.targetRect.top - padding),
      math.min(widget.canvasWidth, item.targetRect.right + padding),
      math.min(widget.canvasHeight, item.targetRect.bottom + padding),
    );
  }

  Widget _buildHighlight(_OverlayGuideItem item) {
    final rect = _highlightRect(item);
    final iconSize = 28.0 * _scale;
    final iconLeft = (rect.center.dx - iconSize / 2).clamp(
      8.0 * _scale,
      math.max(8.0 * _scale, widget.canvasWidth - iconSize - 8.0 * _scale),
    );
    final iconTop = (rect.bottom + 8.0 * _scale).clamp(
      8.0 * _scale,
      math.max(8.0 * _scale, widget.canvasHeight - iconSize - 8.0 * _scale),
    );

    return Stack(
      children: [
        Positioned.fromRect(
          rect: rect,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * _scale),
                border: Border.all(color: item.color, width: 3.0 * _scale),
                color: item.color.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.45),
                    blurRadius: 18 * _scale,
                    spreadRadius: 2 * _scale,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: iconLeft.toDouble(),
          top: iconTop.toDouble(),
          child: IgnorePointer(
            child: _PulsingTouchIcon(
              color: item.color,
              size: iconSize,
              iconSize: 18 * _scale,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(_OverlayGuideItem item) {
    final panelWidth = math.min(widget.canvasWidth - 28 * _scale, 330 * _scale);
    final panelHeight = 190.0 * _scale;
    final left = ((widget.canvasWidth - panelWidth) / 2).clamp(
      14.0 * _scale,
      math.max(14.0 * _scale, widget.canvasWidth - panelWidth - 14.0 * _scale),
    );
    final top = math.max(
      18.0 * _scale,
      widget.canvasHeight - panelHeight - 18.0 * _scale,
    );

    return Positioned(
      left: left.toDouble(),
      top: top,
      width: panelWidth,
      height: panelHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(14 * _scale),
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18 * _scale),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2 * _scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24 * _scale,
                offset: Offset(0, 8 * _scale),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34 * _scale,
                    height: 34 * _scale,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10 * _scale),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 20 * _scale,
                    ),
                  ),
                  SizedBox(width: 10 * _scale),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * _scale,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 30 * _scale,
                      height: 30 * _scale,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20 * _scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * _scale),
              Expanded(
                child: Text(
                  item.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14 * _scale,
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_pageIndex + 1}/${widget.items.length}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12 * _scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _pageIndex == 0 ? null : () => _movePage(-1),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 34 * _scale,
                      height: 34 * _scale,
                    ),
                    icon: Icon(Icons.chevron_left_rounded, size: 26 * _scale),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                  ),
                  SizedBox(width: 4 * _scale),
                  FilledButton(
                    onPressed: _pageIndex == widget.items.length - 1
                        ? _dismiss
                        : () => _movePage(1),
                    style: FilledButton.styleFrom(
                      backgroundColor: item.color,
                      foregroundColor: item.color.computeLuminance() > 0.55
                          ? Colors.black
                          : Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 14 * _scale),
                      minimumSize: Size(0, 34 * _scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _pageIndex == widget.items.length - 1 ? '시작하기' : '다음',
                      style: TextStyle(
                        fontSize: 12 * _scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt() {
    final panelWidth = math.min(widget.canvasWidth - 28 * _scale, 330 * _scale);
    final panelHeight = 174.0 * _scale;
    final left = ((widget.canvasWidth - panelWidth) / 2).clamp(
      14.0 * _scale,
      math.max(14.0 * _scale, widget.canvasWidth - panelWidth - 14.0 * _scale),
    );
    final top = math.max(
      18.0 * _scale,
      widget.canvasHeight - panelHeight - 18.0 * _scale,
    );

    return Positioned(
      left: left.toDouble(),
      top: top,
      width: panelWidth,
      height: panelHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(16 * _scale),
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(20 * _scale),
            border: Border.all(
              color: const Color(0xFFFF6F91).withValues(alpha: 0.34),
              width: 1.2 * _scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 24 * _scale,
                offset: Offset(0, 8 * _scale),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36 * _scale,
                    height: 36 * _scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6F91).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12 * _scale),
                    ),
                    child: Icon(
                      Icons.tips_and_updates_rounded,
                      color: const Color(0xFFFF8FAB),
                      size: 21 * _scale,
                    ),
                  ),
                  SizedBox(width: 11 * _scale),
                  Expanded(
                    child: Text(
                      '사용 방법을 안내해드릴까요?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * _scale,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 30 * _scale,
                      height: 30 * _scale,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20 * _scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * _scale),
              Expanded(
                child: Text(
                  '라벨, 위험도, 추천 메뉴, 가격 환산 기능을 짧게 보여드릴게요.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13 * _scale,
                    fontWeight: FontWeight.w600,
                    height: 1.36,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        minimumSize: Size(0, 36 * _scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '괜찮아요',
                        style: TextStyle(
                          fontSize: 12 * _scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * _scale),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => _guideStarted = true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F91),
                        foregroundColor: Colors.white,
                        minimumSize: Size(0, 36 * _scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '볼게요',
                        style: TextStyle(
                          fontSize: 12 * _scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final item = widget.items[_pageIndex];

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: _guideStarted ? 0.18 : 0.12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Stack(
            children: [
              if (_guideStarted) ...[
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.items.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (_, index) =>
                      _buildHighlight(widget.items[index]),
                ),
                _buildPanel(item),
              ] else
                _buildPrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingTouchIcon extends StatefulWidget {
  const _PulsingTouchIcon({
    required this.color,
    required this.size,
    required this.iconSize,
  });

  final Color color;
  final double size;
  final double iconSize;

  @override
  State<_PulsingTouchIcon> createState() => _PulsingTouchIconState();
}

class _PulsingTouchIconState extends State<_PulsingTouchIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final pulse = math.sin(_controller.value * math.pi);
        final scale = 1.0 + pulse * 0.16;
        final dy = -pulse * widget.size * 0.09;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.28),
              blurRadius: widget.size * 0.62,
              spreadRadius: widget.size * 0.08,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: widget.size * 0.36,
            ),
          ],
        ),
        child: Icon(
          Icons.touch_app_rounded,
          color: Colors.white,
          size: widget.iconSize,
        ),
      ),
    );
  }
}

class _OverlayBox extends StatelessWidget {
  const _OverlayBox({
    required this.overlayItem,
    required this.isRecommended,
    required this.isDummy,
    required this.canvasWidth,
  });

  final _ResolvedOverlayItem overlayItem;
  final bool isRecommended;
  final bool isDummy;
  final double canvasWidth;

  AnalyzedMenuItem get item => overlayItem.item;

  AllergyRisk get _risk => item.allergyRisk;

  bool get _showsRiskBadge => item.hasRiskAnalysis;

  bool get _isVerticalSplit => overlayItem.splitDirection == 'vertical';

  bool get _canTap =>
      item.itemType == 'menu_name' ||
      (item.itemType == 'price' &&
          item.convertedPrice != null &&
          item.convertedPrice!.trim().isNotEmpty);

  bool get _showsPriceHint =>
      item.itemType == 'price' &&
      item.convertedPrice != null &&
      item.convertedPrice!.trim().isNotEmpty;

  Color get _overlayColor {
    if (_showsRiskBadge) return _allergyColor(_risk);
    return switch (item.itemType) {
      'price' => const Color(0xFF42A5F5),
      'description' => const Color(0xFF90A4AE),
      _ => const Color(0xFF757575),
    };
  }

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
      GoogleFonts.blackHanSans(fontSize: _overlayBadgeFontSize, height: 1.0),
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
    double minFontSize = 12.0,
  }) {
    var low = minFontSize;
    var high = 28.0;
    var best = minFontSize;

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

  void _showMenuDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => isDummy
          ? LegacyMenuDetailSheet(item: item)
          : _MenuDetailSheet(item: item),
    );
  }

  void _showConvertedPrice(BuildContext context) {
    final convertedPrice = item.convertedPrice;
    if (convertedPrice == null || convertedPrice.trim().isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => _PriceConversionDialog(
        rawPrice: item.originalText,
        convertedPrice: convertedPrice,
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (item.itemType == 'price') {
      _showConvertedPrice(context);
      return;
    }

    if (item.itemType == 'menu_name') {
      _showMenuDetail(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final rect = overlayItem.rect;
    final originalLeft = rect.left;
    final top = rect.top;
    final originalWidth = math.max(rect.width, 44.0);
    final originalHeight = _isVerticalSplit
        ? math.max(rect.height, 12.0)
        : math.max(rect.height, 24.0);
    final label = overlayItem.text;
    final color = _overlayColor;
    const recommendedColor = Color(0xFFFFC107);
    const badgeRowHeight = _overlayBadgeRowHeight;
    const sideBadgeWidth = 24.0;
    const sideBadgeGap = 4.0;
    final showTopBadges = _showsRiskBadge && !_isVerticalSplit;
    final showSideBadges =
        _isVerticalSplit && (_showsRiskBadge || isRecommended);
    final sideBadgeSpace = showSideBadges ? sideBadgeWidth + sideBadgeGap : 0.0;
    final horizontalPadding = originalWidth < 64 ? 4.0 : 6.0;
    final rightTextPadding = horizontalPadding + _overlayTextRightSafetyPadding;
    final priceIconSpace = _showsPriceHint ? 20.0 : 0.0;
    final verticalPadding = originalHeight < 32 ? 3.0 : 4.0;
    final badgeWidth = !showTopBadges
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
            priceIconSpace +
            _overlayTextWidthSafetyBuffer,
      ),
      badgeWidth,
    );
    final overlayWidth = math.min(
      desiredWidth,
      math.max(1.0, canvasWidth - sideBadgeSpace),
    );
    final totalOverlayWidth = overlayWidth + sideBadgeSpace;
    final overlayLeft =
        (showSideBadges ? originalLeft - sideBadgeSpace : originalLeft)
            .clamp(0.0, math.max(0.0, canvasWidth - totalOverlayWidth))
            .toDouble();
    final wrapsToTwoLines = desiredWidth > canvasWidth;
    final availableTextWidth = math.max(
      1.0,
      overlayWidth - horizontalPadding - rightTextPadding - priceIconSpace,
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
        ? math.max(originalHeight, wrappedPainter!.height + verticalPadding * 2)
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
      minFontSize: _isVerticalSplit ? 8.0 : 12.0,
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
    final resolvedOverlayHeight = _isVerticalSplit
        ? overlayHeight
        : math.max(
            overlayHeight,
            finalTextPainter.height + verticalPadding * 2 + 2.0,
          );

    return Positioned(
      left: overlayLeft,
      top: showTopBadges ? top - badgeRowHeight : top,
      width: totalOverlayWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canTap ? () => _handleTap(context) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTopBadges)
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
                              shadowColor: recommendedColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSideBadges) ...[
                    _VerticalSideBadges(
                      height: resolvedOverlayHeight,
                      riskLabel: _showsRiskBadge ? _risk.label : null,
                      riskColor: color,
                      riskIcon: _showsRiskBadge ? _allergyIcon(_risk) : null,
                      isRecommended: isRecommended,
                    ),
                    const SizedBox(width: sideBadgeGap),
                  ],
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
                        color: _showsRiskBadge
                            ? color
                            : _showsPriceHint
                            ? color
                            : color.withValues(alpha: 0.74),
                        width: _showsPriceHint ? 2.4 : 2.0,
                      ),
                      boxShadow: isRecommended
                          ? [
                              BoxShadow(
                                color: recommendedColor.withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : _showsPriceHint
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.32),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: wrapsToTwoLines ? 2 : 1,
                              softWrap: wrapsToTwoLines,
                              overflow: TextOverflow.visible,
                              textScaler: TextScaler.noScaling,
                              style: textStyle,
                            ),
                          ),
                          if (_showsPriceHint) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.currency_exchange_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalSideBadges extends StatelessWidget {
  const _VerticalSideBadges({
    required this.height,
    required this.riskLabel,
    required this.riskColor,
    required this.riskIcon,
    required this.isRecommended,
  });

  final double height;
  final String? riskLabel;
  final Color riskColor;
  final IconData? riskIcon;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (riskLabel != null && riskIcon != null)
        _VerticalInfoBadge(
          backgroundColor: riskColor,
          foregroundColor: Colors.white,
          icon: riskIcon!,
          label: riskLabel!,
        ),
      if (isRecommended)
        const _VerticalInfoBadge(
          backgroundColor: Color(0xFFFFD54F),
          foregroundColor: Colors.black,
          icon: Icons.star_rounded,
          label: '추천 메뉴',
        ),
    ];

    return SizedBox(
      width: 24,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < badges.length; i++) ...[
              if (i > 0) const SizedBox(height: 3),
              badges[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _VerticalInfoBadge extends StatelessWidget {
  const _VerticalInfoBadge({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;

  String get _verticalLabel => label.runes
      .map((rune) => String.fromCharCode(rune))
      .where((char) => char.trim().isNotEmpty)
      .join('\n');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foregroundColor, size: 10),
            const SizedBox(height: 3),
            Text(
              _verticalLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderAssistantAllergyChip {
  const _OrderAssistantAllergyChip({
    required this.koreanName,
    required this.icon,
  });

  final String koreanName;
  final String icon;
}

class _OrderAssistantDialog extends StatefulWidget {
  const _OrderAssistantDialog({
    required this.departureLanguageCode,
    required this.arrivalLanguageCode,
    required this.staffMenuName,
    required this.userMenuName,
    required this.allergies,
  });

  final String departureLanguageCode;
  final String arrivalLanguageCode;
  final String staffMenuName;
  final String userMenuName;
  final List<_OrderAssistantAllergyChip> allergies;

  @override
  State<_OrderAssistantDialog> createState() => _OrderAssistantDialogState();
}

class _OrderAssistantDialogState extends State<_OrderAssistantDialog> {
  bool _showQuestion = false;
  bool _showAllergies = false;
  bool _showActions = false;
  bool? _isSafe;
  bool _useStaffLanguage = true;

  String get _activeLanguageCode => _useStaffLanguage
      ? widget.departureLanguageCode
      : widget.arrivalLanguageCode;

  String get _activeMenuName =>
      _useStaffLanguage ? widget.staffMenuName : widget.userMenuName;

  bool get _isRtl => _activeLanguageCode == 'ar';

  List<OrderAssistantAllergy> get _translatedAllergies {
    return widget.allergies
        .map(
          (allergy) => OrderAssistantAllergy(
            name: translatedAllergyName(
              allergy.koreanName,
              _activeLanguageCode,
            ),
            icon: allergy.icon,
          ),
        )
        .toList(growable: false);
  }

  String get _question {
    return buildOrderAssistantQuestion(
      languageCode: _activeLanguageCode,
      menuName: _activeMenuName,
      allergyNames: _translatedAllergies
          .map((allergy) => allergy.name)
          .toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _startIntro();
  }

  Future<void> _startIntro() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _showQuestion = true);

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showAllergies = true);

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showActions = true);
  }

  void _selectAnswer(bool isSafe) {
    setState(() => _isSafe = isSafe);
  }

  void _setLanguageMode(bool useStaffLanguage) {
    if (_useStaffLanguage == useStaffLanguage) return;
    setState(() => _useStaffLanguage = useStaffLanguage);
  }

  Widget _fadeIn({required bool visible, required Widget child}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, 0.04),
        child: child,
      ),
    );
  }

  Widget _buildStaffView(OrderAssistantCopy copy) {
    final allergies = _translatedAllergies;

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLanguageSwitcher(),
          const SizedBox(height: 14),
          _fadeIn(
            visible: _showQuestion,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC1D6)),
              ),
              child: Text(
                _question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _fadeIn(
            visible: _showAllergies,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: allergies
                  .map(
                    (allergy) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFF8BBD0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            allergy.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            allergy.name,
                            style: const TextStyle(
                              color: Color(0xFF424242),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          _fadeIn(
            visible: _showActions,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _selectAnswer(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      copy.safeOption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _selectAnswer(false),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_rounded),
                    label: Text(
                      copy.unsafeOption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    Widget buildOption({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2D2D2D) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF616161),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          buildOption(
            label: '종업원 언어',
            selected: _useStaffLanguage,
            onTap: () => _setLanguageMode(true),
          ),
          buildOption(
            label: '사용자 언어',
            selected: !_useStaffLanguage,
            onTap: () => _setLanguageMode(false),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final isSafe = _isSafe ?? false;
    final color = isSafe ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final icon = isSafe ? Icons.verified_rounded : Icons.warning_rounded;
    final title = isSafe ? '직원이 안전하다고 답했습니다' : '다른 메뉴를 선택하는 것이 좋습니다';
    final message = isSafe
        ? '직원 확인 결과 이 메뉴를 먹어도 된다는 답변을 받았습니다. 그래도 이상 증상이 느껴지면 즉시 섭취를 중단하세요.'
        : '직원 확인 결과 이 메뉴는 피하는 것이 좋다는 답변을 받았습니다. 다른 메뉴를 선택해 주세요.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.82, end: 1),
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF616161),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = orderAssistantCopyFor(_activeLanguageCode);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: _isSafe == null
          ? Text(
              copy.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2D2D2D),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isSafe == null
                ? KeyedSubtree(
                    key: const ValueKey('staff'),
                    child: _buildStaffView(copy),
                  )
                : KeyedSubtree(
                    key: const ValueKey('result'),
                    child: _buildResultView(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PriceConversionDialog extends StatelessWidget {
  const _PriceConversionDialog({
    required this.rawPrice,
    required this.convertedPrice,
  });

  final String rawPrice;
  final String convertedPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        '환산 가격',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rawPrice.trim().isEmpty
                ? convertedPrice
                : '$rawPrice ≈ $convertedPrice',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'AI가 추정한 참고용 환산 금액입니다. 실제 결제 금액이나 환율과 다를 수 있습니다.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
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
            : [BoxShadow(color: shadowColor!, blurRadius: 10, spreadRadius: 1)],
      ),
      child: SizedBox(
        height: _overlayBadgeHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _overlayBadgeHorizontalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _overlayBadgeIconSize,
                height: _overlayBadgeIconSize,
                child: Icon(
                  icon,
                  color: foregroundColor,
                  size: _overlayBadgeIconSize,
                ),
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

  Future<void> _showOrderAssistant(MenuDetail? detail) async {
    final allergyIndices = await UserPrefs.loadAllergyIndices();
    final allergies = allergyIndices
        .where((index) => index >= 0 && index < allergyItems.length)
        .map((index) {
          final item = allergyItems[index];
          return _OrderAssistantAllergyChip(
            koreanName: item['name']!,
            icon: item['icon']!,
          );
        })
        .toList(growable: false);

    if (!mounted) return;
    if (allergies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('등록된 알레르기 항목이 없어 주문 도우미를 사용할 수 없습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final settings = await UserPrefs.loadLanguageSettings();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _OrderAssistantDialog(
        departureLanguageCode: settings.departure,
        arrivalLanguageCode: settings.arrival,
        staffMenuName: _staffOrderAssistantMenuName(detail),
        userMenuName: _userOrderAssistantMenuName(detail),
        allergies: allergies,
      ),
    );
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
          const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white24,
            size: 36,
          ),
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
            errorBuilder: (_, __, ___) =>
                _buildImagePlaceholder('이미지를 불러오지 못했습니다.'),
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

  String _userOrderAssistantMenuName(MenuDetail? detail) {
    final translatedText = _item.content.translatedText?.trim();
    if (translatedText != null && translatedText.isNotEmpty) {
      return translatedText;
    }
    return _titleText(detail);
  }

  String _staffOrderAssistantMenuName(MenuDetail? detail) {
    final rawText = _item.content.rawText?.trim();
    if (rawText != null && rawText.isNotEmpty) {
      return rawText;
    }

    final originalText = _item.originalText.trim();
    if (originalText.isNotEmpty) {
      return originalText;
    }

    return _titleText(detail);
  }

  Widget _buildDetailTextSection({
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientChips(List<String> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 재료',
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
          children: ingredients
              .map(
                (ingredient) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    ingredient,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showOrderAssistant(detail),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.record_voice_over_rounded),
                      label: const Text(
                        '주문 도우미',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFB74D),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '메뉴 상세 정보를 불러오는 중입니다.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
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
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
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
                  if (detail != null &&
                      detail.description != null &&
                      detail.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailTextSection(
                      title: '메뉴 설명',
                      body: detail.description!,
                    ),
                  ],
                  if (detail != null && detail.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildIngredientChips(detail.ingredients),
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
  const LegacyMenuDetailSheet({super.key, required this.item});

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
                    Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white24,
                      size: 36,
                    ),
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
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
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
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Colors.white38,
                      ),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (failureMessage != null) ...[
              const SizedBox(height: 16),
              _DebugSection(
                title: '오류 메시지',
                copyText: failureMessage,
                child: SelectableText(
                  failureMessage!,
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
