import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// Widget specifications for all USP Dashboard cards.
///
/// All constraints use DisplayMode.normal only (DisplayMode switching deferred).
/// Column values are based on a 12-column layout.
abstract class UspWidgetSpecs {
  UspWidgetSpecs._();

  // ---------------------------------------------------------------------------
  // Card Specs (2-column default, preferredColumns=6)
  // h values sized for fixed slot height: 100px per row
  // ---------------------------------------------------------------------------

  static const statsPanel = WidgetSpec(
    id: 'stats_panel',
    displayName: 'Stats Panel',
    canHide: false,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(1),
        minHeightRows: 1,
        maxHeightRows: 2,
      ),
    },
  );

  static const deviceInfo = WidgetSpec(
    id: 'device_info',
    displayName: 'Device Info',
    canHide: false,
    // Measured floor, #1288 AC 1: 34.0 card chrome + 136.0 hero fixed cost
    // (12px block padding ×2 + a 96px icon container + `AppGap.lg`) + 91.6 for
    // `MR7500`, which has no space to break at = 261.6, confirmed by a 2px sweep
    // at 262. Locale-invariant: this card's hero strings are device data, so the
    // worst locale is `ko` only because it has the smallest content viewport
    // (122.0px) — and fixture-dependent, since a hostname longer than the
    // fixture's raises it (#1267 measures a second data profile).
    normalAbove: 262,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const networkStatus = WidgetSpec(
    id: 'network_status',
    displayName: 'WAN Status',
    canHide: false,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const topology = WidgetSpec(
    id: 'topology',
    displayName: 'Network Topology',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const lanInfo = WidgetSpec(
    id: 'lan_info',
    displayName: 'LAN Info',
    // Measured floor, #1288 AC 1: 34.0 card chrome + 96.0 hero fixed cost (12px
    // block padding ×2 + the 56px avatar + `AppGap.lg`) + 12.0 for the status dot
    // and its gap + 107.2 for `Ενεργοποιήθηκε` = 249.2, confirmed by a 2px sweep
    // at 250. The binding string is the *subtitle*'s longest token in `el`, not
    // the IP address (105.8) — by 1.4px, which is why the floor is measured per
    // token rather than reasoned from which line looks longest.
    normalAbove: 250,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 5,
      ),
    },
  );

  static const ethernetPorts = WidgetSpec(
    id: 'ethernet_ports',
    displayName: 'Ethernet Ports',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const systemStatus = WidgetSpec(
    id: 'system_status',
    displayName: 'System Status',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  static const connectedDevices = WidgetSpec(
    id: 'connected_devices',
    displayName: 'Connected Devices',
    // Measured floor, #1289 AC 1: the widest *bounded* token a device row shows
    // is a full 15-character IPv4 quad at 93.1px, and the floor is the narrowest
    // card at which the **normal** row seats it — 336px, from a 1px sweep of the
    // pinned normal form from 200px to 460px (335px grants 93.0px and clips by
    // 0.1px; 336px and everything above is clean).
    //
    // ## Why 336 and not the 311 the fixture's rows suggest
    //
    // The same sweep against a row behind `MR7500` puts the floor at 310.4
    // (`cardWidth − 217.3` content, + 93.1), and shipping that number would have
    // been wrong for a reason worth recording: the trailing slot takes what it
    // *demands*, and this row's demand includes a parent-node badge whose width
    // is `min(nodeName + 16, 100)`. A six-character node name demands 62px; one
    // at the 100px cap demands 100px, and the extra 38px comes out of the only
    // column left — the address. Measured at 311px with `Living-Room-Extender-2`
    // as the node: the quad is granted 69.0px against the 93.1px it needs.
    //
    // The badge's own drop rule cannot cover this, and that is the point. It
    // drops the badge when the slot cannot seat the name *whole*, but a capped
    // name is whole at 100px by definition, so at every width from 311 up the
    // rule is satisfied and the badge stays. A per-row rule cannot decline a
    // demand that is inside its own budget; only the threshold can, which is why
    // the number carries it. The badge is *bounded* (unlike the node name it
    // renders), so a width does exist that pays for it — 336px — and a bounded
    // demand that a width can retire belongs in the floor.
    //
    // ## Why the floor is not the 330px "nothing ellipsizes" width
    //
    // A 1px sweep from 191px to 520px in all 26 locales puts *that* number at
    // 330, identically in every one, and the binding token is the fixture's
    // `Gaming-Console` (124.9px) — a device *name*. Names are unbounded router
    // data: no width makes an arbitrary one fit, so 330 is a property of the
    // fixture rather than a threshold, and ellipsis on a name is the designed
    // behaviour. `MacBook-A…` still identifies a device; `192.168.1.…` does not
    // identify a host, which is the whole distinction this number is derived
    // from. Locale-invariance is the same finding from the other side: the
    // widest thing on this card is data, not a translated string.
    //
    // ## What the bands buy
    //
    // `widthCasesFor` realizes exactly two widths here — 191.375px (3-column
    // floor) and 288.000px (6- and 8-column spans both clamped to the 4-column
    // mobile grid). So this threshold puts the first in popup and the *second* in
    // compact, and 288px is where it pays: the normal row ellipsizes four of the
    // five fixture names there, and the compact row's 60px hands `Smart-Speaker`
    // (113.0px) a column that fits. The band also covers the widths between the
    // realizations that the grid produces and the gate never pumps — a 3-column
    // span is 228.5px on a 700px screen.
    //
    // The compact form holds the quad across the **whole** band: a 1px sweep of
    // the pinned compact form from 200px to 340px grants all four worst-case rows
    // 93.1px at every width, with no clipping anywhere, in all 26 locales. That
    // is a stronger statement than the band needs (it clears 336) and it is what
    // makes the [200, 336) span safe to declare rather than a span that merely
    // happens to work at the two widths the grid realizes.
    normalAbove: 336,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const wifiStatus = WidgetSpec(
    id: 'wifi_status',
    displayName: 'WiFi Status',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 4,
        maxHeightRows: 6,
      ),
    },
  );

  static const wifiNetworks = WidgetSpec(
    id: 'wifi_networks',
    displayName: 'WiFi Networks',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const timeSettings = WidgetSpec(
    id: 'time_settings',
    displayName: 'Time Settings',
    // Measured floor, #1288 AC 1: 34.0 card chrome + 96.0 hero fixed cost + 124.6
    // for `2024-06-15` = 254.6, confirmed by a 2px sweep at 256. The binding
    // string is the timestamp's *widest token*, not the whole 223.1px stamp: it
    // has a space, so the normal form breaks it into `2024-06-15` / `21:30:48`
    // with both tokens whole, which is why this card reads at the 288px
    // realization and its floor is 32px below it rather than 100px above.
    //
    // Locale-invariant, and by construction rather than by luck:
    // `TimeSettingsUIModel.formatDateTime` hardcodes `yyyy-MM-dd HH:mm:ss`, so
    // the stamp is byte-identical in all 26 locales. The worst locale, `ru`, is
    // worst only for the sync badge (`Синхронизировано`, 112.1px), which
    // ellipsizes by design (#1237) and so does not set the floor.
    normalAbove: 256,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        // `minColumns` stays 3 deliberately. This is the one card in the whole
        // baseline where raising it would have worked: its fit width is 288px
        // (§1.2), so 3 → 5 columns would have covered every locale, while the
        // other 12 cards need more than the 12 columns that exist (§1.3).
        //
        // Declined anyway, and #1237 exists partly to record why. The floor is
        // the user's, not ours — it decides how narrow they may make this card on
        // their own dashboard — and 5 of 12 columns is a permanent charge against
        // every layout to buy headroom in a handful of long-timezone locales. The
        // card-own fix (`usp_time_settings_card.dart:108`) cleared all 21
        // coordinates by deleting a single-child `Row` that had no other effect
        // than handing the badge unbounded width, so the widening bought nothing
        // that constraining the content did not.
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 3,
        maxHeightRows: 4,
      ),
    },
  );

  static const dhcpReservations = WidgetSpec(
    id: 'dhcp_reservations',
    displayName: 'DHCP Reservations',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const portForwarding = WidgetSpec(
    id: 'port_forwarding',
    displayName: 'Port Forwarding',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const deviceAnalytics = WidgetSpec(
    id: 'device_analytics',
    displayName: 'Device Analytics',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  static const networkHealth = WidgetSpec(
    id: 'network_health',
    displayName: 'Network Health',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 3,
        maxHeightRows: 6,
      ),
    },
  );

  static const firewallOverview = WidgetSpec(
    id: 'firewall_overview',
    displayName: 'Firewall Overview',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 3,
        maxHeightRows: 6,
      ),
    },
  );

  static const wifiPerformance = WidgetSpec(
    id: 'wifi_performance',
    displayName: 'WiFi Performance',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  static const trafficAnalysis = WidgetSpec(
    id: 'traffic_analysis',
    displayName: 'Traffic Analysis',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  // Speed Test — disabled: blocked by FW support (#857)
  // static const speedTest = WidgetSpec(
  //   id: 'speed_test',
  //   displayName: 'Speed Test',
  //   constraints: {
  //     DisplayMode.normal: WidgetGridConstraints(
  //       minColumns: 3,
  //       maxColumns: 6,
  //       preferredColumns: 5,
  //       heightStrategy: HeightStrategy.strict(3),
  //       minHeightRows: 2,
  //       maxHeightRows: 5,
  //     ),
  //   },
  // );

  // ---------------------------------------------------------------------------
  // Registry
  // ---------------------------------------------------------------------------

  static const List<WidgetSpec> all = [
    statsPanel,
    deviceInfo,
    networkStatus,
    topology,
    lanInfo,
    ethernetPorts,
    systemStatus,
    connectedDevices,
    wifiStatus,
    wifiNetworks,
    timeSettings,
    dhcpReservations,
    portForwarding,
    networkHealth,
    firewallOverview,
    wifiPerformance,
    trafficAnalysis,
    deviceAnalytics,
    // speedTest, // disabled: blocked by FW support (#857)
  ];

  static WidgetSpec? getById(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Layout Scaling
  // ---------------------------------------------------------------------------

  /// Proportionally scales a serialised layout from [fromCols] to [toCols].
  ///
  /// * Tablet (12→8): `w=6` → `w=4`, preserving two-column pairs.
  /// * Mobile (12→4): all items become full-width (`w=toCols`) for
  ///   single-column stacking — `compact()` then resolves y positions.
  /// * Constraints (minW / maxW) are scaled accordingly.
  static List<dynamic> scaleLayout(
    List<dynamic> layout,
    int fromCols,
    int toCols,
  ) {
    return layout.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final x = map['x'] as int;
      final w = map['w'] as int;
      final minW = map['minW'] as int? ?? 1;
      final maxW = (map['maxW'] as num?)?.toInt() ?? fromCols;

      int newW;
      int newX;

      if (toCols <= 4) {
        // Mobile: full-width single-column
        newW = toCols;
        newX = 0;
      } else {
        // Proportional scaling
        newW = (w * toCols / fromCols).round().clamp(1, toCols);
        newX = (x * toCols / fromCols).round();
        if (newX + newW > toCols) newX = toCols - newW;
        if (newX < 0) {
          newX = 0;
          newW = toCols;
        }
      }

      final newMinW = (minW * toCols / fromCols).round().clamp(1, toCols);
      final newMaxW = (maxW * toCols / fromCols).round().clamp(newMinW, toCols);

      return {
        ...map,
        'x': newX,
        'w': newW,
        'minW': newMinW,
        'maxW': newMaxW.toDouble(),
      };
    }).toList();
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
