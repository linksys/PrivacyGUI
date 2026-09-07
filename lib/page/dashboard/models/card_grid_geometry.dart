import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Height of one dashboard grid row, in logical pixels.
///
/// Fixed rather than derived: the grid sizes columns from the viewport but keeps
/// rows at a constant height, which is what makes a card's `minHeightRows` a
/// height at all. Lives here rather than on the view that lays the grid out
/// because callers that need only the arithmetic — the popup form's presentation
/// among them — would otherwise have to import the view, and the view already
/// imports them.
const double kDashboardSlotHeight = 120.0;

/// Pixel height of a card spanning [rows] grid rows.
///
/// The inter-row gaps count: a 2-row card is two slots *plus* the gap between
/// them, so it is 256px rather than 240. Same two numbers the view feeds
/// `SliverDashboard`, which is why this is the height a card of that many rows
/// is actually given.
double dashboardRowsToHeight(int rows) =>
    rows * kDashboardSlotHeight + (rows - 1) * AppSpacing.lg;

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
class CardGridGeometry extends Equatable {
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
  List<Object?> get props => [
        slotWidth,
        slotHeight,
        mainAxisSpacing,
        crossAxisSpacing,
        padding,
      ];
}
