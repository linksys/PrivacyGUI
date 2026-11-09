import 'package:privacy_gui/page/dashboard/models/usp_card_sizing.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_spec_registry.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// Widget specifications for all USP Dashboard cards, and the layout rules built
/// on them, behind one name.
///
/// Three files, one per reason to change (#1311):
///
/// * [UspWidgetSpecRegistry] — the card specs, `all` and `getById`: changes when
///   a card is added, renamed, or its grid constraints move.
/// * [UspCardSizing] — twelfths → columns arithmetic and the card-form policy:
///   changes when the breakpoint model or the density feature does.
/// * this class — layout construction (`alignMembership`, the default layout):
///   changes when the preset or default layout does. It forwards `all`,
///   `getById` and every public member of [UspCardSizing], so no call site has
///   to change.
abstract class UspWidgetSpecs {
  UspWidgetSpecs._();

  // ---------------------------------------------------------------------------
  // Forwarders (#1311)
  //
  // Each is a const tear-off of the member that does the work, so it keeps that
  // member's signature — named parameters included — without restating it. A
  // static extension cannot do this: a static member declared in
  // `extension on UspWidgetSpecs` cannot be called on `UspWidgetSpecs` itself.
  // Each also carries a one-line doc naming its target, because hovering a
  // field shows the field's own doc, not the doc of what it points at.
  // ---------------------------------------------------------------------------

  // Registry — usp_widget_spec_registry.dart
  /// Forwards [UspWidgetSpecRegistry.all].
  static const all = UspWidgetSpecRegistry.all;

  /// Forwards [UspWidgetSpecRegistry.getById].
  static const getById = UspWidgetSpecRegistry.getById;

  // Twelfths → columns — usp_card_sizing.dart
  /// Forwards [UspCardSizing.scaleSpan].
  static const scaleSpan = UspCardSizing.scaleSpan;

  /// Forwards [UspCardSizing.correctedSize].
  static const correctedSize = UspCardSizing.correctedSize;

  /// Forwards [UspCardSizing.scaleLayout].
  static const scaleLayout = UspCardSizing.scaleLayout;

  /// Forwards [UspCardSizing.lockToFullWidth].
  static const lockToFullWidth = UspCardSizing.lockToFullWidth;

  // Card forms (#1299) — usp_card_sizing.dart
  /// Forwards [UspCardSizing.cardsWithoutPopupForm].
  static const cardsWithoutPopupForm = UspCardSizing.cardsWithoutPopupForm;

  /// Forwards [UspCardSizing.popupColumns].
  static const popupColumns = UspCardSizing.popupColumns;

  /// Forwards [UspCardSizing.popupHeightRows].
  static const popupHeightRows = UspCardSizing.popupHeightRows;

  /// Forwards [UspCardSizing.compactMinColumns].
  static const compactMinColumns = UspCardSizing.compactMinColumns;

  /// Forwards [UspCardSizing.compactMinHeightRows].
  static const compactMinHeightRows = UspCardSizing.compactMinHeightRows;

  /// Forwards [UspCardSizing.selectableForms].
  static const selectableForms = UspCardSizing.selectableForms;

  /// Forwards [UspCardSizing.withCardForm].
  static const withCardForm = UspCardSizing.withCardForm;

  /// Forwards [UspCardSizing.applyPickedForms].
  static const applyPickedForms = UspCardSizing.applyPickedForms;

  // ---------------------------------------------------------------------------
  // Layout Membership
  // ---------------------------------------------------------------------------

  /// Rewrites [layout] to hold exactly the cards in [reference], in that order,
  /// keeping whatever geometry [layout] already has for the ones it knows and
  /// scaling in the ones it does not.
  ///
  /// Which cards exist is a property of the dashboard, not of a breakpoint:
  /// deleting a card on a phone deletes the card. Only geometry is per-grid, so
  /// a stored per-grid layout can legitimately fall behind — it was written
  /// before a card was added. Importing it as-is would be worse than useless:
  /// `DashboardController.setSlotCount` treats the layout it is leaving as the
  /// truth about membership, so the stale grid's missing card would be
  /// reconciled *out* of every other breakpoint on the way back.
  static List<LayoutItem> alignMembership(
    List<LayoutItem> layout,
    List<LayoutItem> reference, {
    required int fromCols,
    required int toCols,
  }) {
    final stored = {for (final item in layout) item.id: item};

    return reference
        .map((refItem) =>
            stored[refItem.id] ??
            scaleLayout([refItem], fromCols, toCols).single)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Default Layout
  // ---------------------------------------------------------------------------

  /// Creates the default 2-column layout for the USP Dashboard.
  ///
  /// Each card uses w=6 (half of 12-column grid).
  /// h values sized for fixed slot height: 120px per row.
  ///
  /// ```
  /// y=0:  StatsPanel (12×1)
  /// y=1:  DeviceInfo (6×3)          | NetworkStatus (6×3)
  /// y=4:  NetworkHealth (6×4)       | SystemStatus (6×5)
  /// y=9:  TrafficAnalysis (6×5)     | LanInfo (6×3)
  /// y=14: EthernetPorts (6×3)       | ConnectedDevices (6×4)
  /// y=18: Topology (6×5)            | DeviceAnalytics (6×5)
  /// y=23: WiFiStatus (6×6)          | WiFiPerformance (6×5)
  /// y=29: FirewallOverview (6×4)    | TimeSettings (6×3)
  /// y=33: DhcpReservations (6×4)    | PortForwarding (6×4)
  /// ```
  static List<LayoutItem> createDefaultLayout() {
    return createLayoutForCards(all.map((s) => s.id).toList());
  }

  /// Creates a 2-column layout for the given [cardIds].
  ///
  /// * `stats_panel` is always placed full-width (12 cols) if present.
  /// * Remaining cards are placed in 6-col pairs, auto-calculating y.
  /// * Uses each spec's preferred height from its `HeightStrategy`.
  static List<LayoutItem> createLayoutForCards(List<String> cardIds) {
    final items = <LayoutItem>[];
    int y = 0;

    // stats_panel first (full width) if present
    if (cardIds.contains('stats_panel')) {
      final spec = getById('stats_panel')!;
      items.add(LayoutItemFactory.fromSpec(spec, x: 0, y: y, w: 12));
      y += items.last.h;
    }

    // Remaining cards in 6-col pairs
    final remaining = cardIds.where((id) => id != 'stats_panel').toList();
    for (int i = 0; i < remaining.length; i += 2) {
      final leftSpec = getById(remaining[i]);
      if (leftSpec == null) continue;
      final leftItem = LayoutItemFactory.fromSpec(leftSpec, x: 0, y: y, w: 6);
      items.add(leftItem);

      int rowHeight = leftItem.h;

      if (i + 1 < remaining.length) {
        final rightSpec = getById(remaining[i + 1]);
        if (rightSpec != null) {
          final rightItem =
              LayoutItemFactory.fromSpec(rightSpec, x: 6, y: y, w: 6);
          items.add(rightItem);
          if (rightItem.h > rowHeight) rowHeight = rightItem.h;
        }
      }

      y += rowHeight;
    }

    return items;
  }
}
