import 'package:flutter/widgets.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// The pixel geometry the dashboard grid was laid out with (#1299).
///
/// Anything drawn *over* the grid rather than inside it — the card form toolbar
/// is the first — has to convert a card's grid coordinates back into pixels
/// itself, because the grid only ever hands its items the cell it already put
/// them in.
///
/// `sliver_dashboard` computes exactly this internally, as `SlotMetrics`, and
/// converts the other way in `SlotMetrics.pixelToGrid`. It does not export the
/// class (`lib/sliver_dashboard.dart` omits `layout_metrics.dart`), so this is a
/// deliberate local mirror rather than a duplicate by accident: [cellRect] is the
/// inverse of that method for a vertical grid, and is fed the same numbers the
/// view passes the grid. If a package bump changes how a cell is placed, the
/// geometry tests in `card_form_toolbar_test.dart` fail — they compare this
/// arithmetic against the rect the real grid gave the real card.
@immutable
class CardGridGeometry {
  const CardGridGeometry({
    required this.slotWidth,
    required this.slotHeight,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.padding,
  });

  /// Width of one column.
  final double slotWidth;

  /// Height of one row.
  final double slotHeight;

  /// Gap between rows.
  final double mainAxisSpacing;

  /// Gap between columns.
  final double crossAxisSpacing;

  /// Padding the grid was given, which every cell is offset by.
  final EdgeInsets padding;

  /// Where [item] sits in the grid's own coordinates, at [scrollOffset].
  ///
  /// Vertical scroll direction only, which is the only one this dashboard has.
  Rect cellRect(LayoutItem item, double scrollOffset) => Rect.fromLTWH(
        padding.left + item.x * (slotWidth + crossAxisSpacing),
        padding.top + item.y * (slotHeight + mainAxisSpacing) - scrollOffset,
        item.w * slotWidth + (item.w - 1) * crossAxisSpacing,
        item.h * slotHeight + (item.h - 1) * mainAxisSpacing,
      );

  @override
  bool operator ==(Object other) =>
      other is CardGridGeometry &&
      other.slotWidth == slotWidth &&
      other.slotHeight == slotHeight &&
      other.mainAxisSpacing == mainAxisSpacing &&
      other.crossAxisSpacing == crossAxisSpacing &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(
        slotWidth,
        slotHeight,
        mainAxisSpacing,
        crossAxisSpacing,
        padding,
      );
}
