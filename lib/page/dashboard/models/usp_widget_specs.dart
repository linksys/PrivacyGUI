import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
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
    // Measured floor, #1290 AC 1 — and the first one on this card that is *not*
    // a width at which the content fits, because no such width exists.
    //
    // ## What the sweep found
    //
    // A pinned-normal 4px sweep from 200px to 700px, plus all 26 locales at
    // every realization `widthCasesFor` produces: **not one port item seats
    // inside the content viewport at any width**, in any locale. The viewport is
    // 121px at this card's minimum height (2 rows) and one port item is 82px
    // tall starting *below* the summary tiles, so the binding constraint is
    // vertical and width cannot retire it. The two narrow realizations show
    // 0.0px of every port glyph; even 512px desktop seats none whole (4 of 5
    // glyphs are fully visible, all 5 labels sit below the fold — the loss
    // §2.12 already records as pre-dating #1228).
    //
    // So the threshold is not "where it fits". It is the coordinate at which the
    // normal form stops *costing* the ports their glyphs:
    //
    // * **386** — the card width at which the content column first reaches
    //   352px and the summary tiles stop stacking. From a 1px sweep: stacked at
    //   385, side by side at 386, so the content column is `cardWidth − 34`
    //   (16px of card padding plus a 1px border, each side). Stacked, all five
    //   glyphs measure 0.0px visible; side by side, four measure the full 38px.
    //   That flip *is* the regression this ticket carries, so its coordinate is
    //   the threshold, and it subsumes `_kSideBySideMinWidth` from the grid's
    //   side without deleting it (see that constant for the presentation side).
    // * **570** — rejected. It is where all five 88px items fit one run
    //   (5 × 88 + 4 × 24 = 536px of content), i.e. where the *whole* grid shows
    //   every glyph, and it is above `desktopCaseFor` (512): declaring it would
    //   put the desktop realization in compact and contradict the requirement
    //   that the full grid render there.
    //
    // 386 clears the ">288px" the ticket demands for a reason that is the
    // ticket's own: 288 is a realization the grid produces, at which the normal
    // form shows two tiles, a divider and no ports at all.
    //
    // ## What the bands buy
    //
    // 191.375px (the 3-column floor) goes to the popup form, so the ports become
    // readable in the presentation. 288.000px — the realization that cannot be
    // fixed by a threshold alone — goes to **compact**, which drops the tiles and
    // seats all five ports as chips in 72px of the 121px viewport. Every width
    // between, which the grid produces and the gate never pumps (a 3-column span
    // is 228.5px on a 700px screen), is covered: a pinned-compact 4px sweep of
    // [200, 386) seats all five chips at every width in all 26 locales — three
    // runs (112px of the 121px viewport) up to 268px, two runs (72px) from 269px
    // — so the tightest point in the band still clears by 7px. Chip metrics are
    // locale-invariant because a port label and a speed are ASCII device data:
    // 32px tall and 61.8–79.0 wide in every one of the 26.
    normalAbove: 386,
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
    // Measured floor, #1321: the narrowest width at which the **normal** Active
    // Leases row seats an IP *and* a lease duration side by side — measured
    // against the widest row the product can produce, not against the fixture.
    //
    // ## What "widest" means here, and why it is not the fixture
    //
    // Both operands are bounded, so both are measured at their bound. This is
    // the criterion `usp_dhcp_reservations_density_test.dart` inherits from
    // #1289: a bounded token must never be clipped, an unbounded one may.
    //
    //  - the IP is a 15-character IPv4 quad. The pool is user-editable
    //    (`AppIpv4TextField`, Local Network page), so `192.168.100.200` is an
    //    ordinary address rather than a corner case, and the fixture's
    //    `192.168.1.102` is two characters short of the format.
    //  - the lease is `leaseTimeFormatted`'s widest bucket. `validateLeaseTime`
    //    caps a pool's lease at 525600 minutes
    //    (`usp_local_network_service.dart:197`), so `364d 23h` is the widest
    //    string the getter can render for a lease this product accepts.
    //
    // 1px sweeps of the pinned normal form, `en`, three lease rows per shape:
    //
    // | row content                   | first width with no clipping |
    // |-------------------------------|------------------------------|
    // | fixture IP + `23h 59m`        | 329                          |
    // | fixture IP + `364d 23h`       | 330–336                      |
    // | 15-char quad + `23h 59m`      | 361–369                      |
    // | **15-char quad + `364d 23h`** | **369** (368 clips 0.7px)    |
    //
    // Row 1 is what this threshold was set to first, and the table is why it
    // moved: of the 40px between, 25 are the two extra address characters and 5
    // are the exotic lease. The number is driven by the *address format*, which
    // is what the row exists to show — a lease nobody configured is not what
    // makes 369 the floor.
    //
    // ## Why 369 and not the 368 that "widest failing + 1" gives
    //
    // Every other threshold in this file is the widest *failing* width plus one,
    // where failing means "over `kOverflowTolerancePx`". That derivation puts
    // this one at 368 — and 368 still clips, by 0.7px, which only the 2.0px
    // tolerance absorbs. The tolerance exists for rasterizer drift between the
    // mac and ubuntu font stacks (`overflow_probe.dart:4-15`), so a threshold
    // set inside it spends the very margin the tolerance is there to provide.
    // 369 is the narrowest width where the row does not clip at all, which is
    // the claim a threshold should be making, and it costs 1px.
    //
    // ## What the bands buy
    //
    // `widthCasesFor` realizes exactly two widths here — 260.500px (the
    // 4-column floor, @601px screen) and 288.000px (6- and 8-column spans both
    // clamped to the 4-column mobile grid, @320px). **Both were shipping
    // broken**: the normal row overflowed by 51.0px and 31.0px against an
    // unexpired lease, with the duration clipped off the right edge on a real
    // router. This threshold puts both in compact, and it stays below
    // `desktopCaseFor` (512.000px) so the side-by-side row is intact wherever
    // there is room for it.
    //
    // The compact form holds **both** operands across the whole band, and it
    // does so by stacking them rather than dropping either half: at the worst
    // case above it is clean at 200, 260.5, 288, 330, 350, 367 and 368px in
    // `en`, and at 367px — the band's top edge — in all 26 locales. The
    // side-by-side row needs ~126px of trailing slot at the fixture's content
    // and ~166px at the bound; stacked it needs `max(IP, lease)` ≈ 93px, which
    // is what makes [200, 369) safe to *declare* rather than a band that happens
    // to work at the two widths the grid realizes. `DeviceRow.compact`'s 60px is
    // spent on the same row and is not enough on its own — it clears 252px, not
    // 200px.
    //
    // The cost of the band is one 8px dot per row. `build` filters to
    // `isOnline == true` before building any lease row, so that dot is always
    // the success colour: it is the only thing on this row that can be spent
    // without losing information, which is what makes 369 cheap to declare and
    // would not be true of a card whose leading slot carried a state.
    normalAbove: 369,
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
    // #1291. The only *height* defect in the six: the Health tab's gauge is a
    // fixed 120px inside an `Expanded`, so the three-chip metric row below it
    // takes its height, and how much it takes is a function of translation
    // length. Measured across 26 locales at 1px, `gauge + row == 165px` at every
    // width — perfectly complementary — and `de` spends 142px of it on
    // `Verworfene Pakete` over 6 lines, leaving 23px for a centre column that
    // needs 44. That is the 0.52 scale #1235 absorbed with `BoxFit.scaleDown`
    // and explicitly handed to this threshold.
    //
    // ## Two floors, and why the higher one is the threshold
    //
    // A pinned-normal 1px sweep from 200px to 620px in all 26 locales produces
    // two different numbers, because two different things are wrong:
    //
    //   | floor                                | worst locale        | width |
    //   |--------------------------------------|---------------------|-------|
    //   | the centre stops being height-scaled | `de` (`th` 204)     | 231   |
    //   | no metric label breaks mid-word      | `da`/`nb`           | 366   |
    //
    // 231 is where the row stops being *tall* enough to starve the gauge; 366 is
    // where it stops wrapping at all. They are the same defect at two severities,
    // and the threshold pays for the second, because a threshold is the width at
    // which the normal form *earns selection* (§2.6f point 1) and this form has
    // not earned it while `Forkastninger` is being cut into `Forkastnin`/`ger`.
    //
    // That is #1289's rule applied unchanged: a **bounded** token must never be
    // cut, an unbounded one may. These three labels are bounded — fixed
    // translated words, not router data — so a width exists that pays for them,
    // and 366 is it (widest failing + 1, as every threshold in this file is
    // derived). Unlike #1289's device names, no fixture can make them wider.
    //
    // Nothing ellipsizes anywhere in that sweep: the labels wrap instead, which
    // is why the #1183 gate and #1235 both stayed quiet — a mid-word break makes
    // text *narrower* (§2.10d point 3).
    //
    // ## What the bands buy
    //
    // `widthCasesFor` realizes 191.375px and 288.000px here, so this threshold
    // puts the first in popup (score) and the *second* in compact — which is what
    // #1291 predicted when it said to "expect the threshold to land above 288px
    // or expect the compact form to carry 288px too". 366 also stays below
    // `desktopCaseFor` (512px), so the three-chip row is intact where the tab has
    // room for it, and §1.2's 420px fit width sits inside the normal band.
    //
    // The compact form holds the whole band rather than the two realized widths:
    // a 1px sweep of the pinned compact form from 200px to 372px gives the gauge
    // its full 120x120 in all 26 locales, with the centre at 1.000 (`ru` 0.973 —
    // its centre is 123px wide against a 120px gauge, a *width* bind present at
    // desktop too, which no threshold can retire).
    normalAbove: 366,
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

  /// Converts a column span from a [fromCols]-wide grid to a [toCols]-wide one,
  /// never returning less than one column or more than the grid holds.
  ///
  /// Every column figure in a [WidgetSpec] is written for the 12-column grid, so
  /// anything comparing a live item against its spec has to bring the spec to the
  /// grid the item is actually on: read literally, `stats_panel`'s
  /// `minColumns: 6` would demand three quarters of an 8-column row, and more
  /// columns than a 4-column grid even has.
  static int scaleSpan(
    int span, {
    required int fromCols,
    required int toCols,
  }) =>
      (span * toCols / fromCols).round().clamp(1, toCols);

  /// [scaleSpan] from the 12-column grid every spec column figure is written for.
  ///
  /// Every caller inside this file scales *from* twelfths — that is what a
  /// [WidgetGridConstraints] column figure is — so `fromCols` was the same
  /// constant at all five sites and never once a variable. Only [scaleLayout]
  /// scales between two grids it is told about, and it keeps the general call.
  ///
  /// Named for the direction rather than made a default on [scaleSpan], so the day
  /// a figure is written against some other grid the compiler makes whoever wrote
  /// it say which one.
  static int _scaleFromTwelfths(int span, {required int toCols}) => scaleSpan(
        span,
        fromCols: UspLayoutEnvelope.desktopSlotCount,
        toCols: toCols,
      );

  /// The size a card has to be corrected to on a [slotCount]-wide grid, or null
  /// when the size it already has is allowed.
  ///
  /// The arithmetic lives here rather than in the resize handler because the
  /// grid-dependent part is the whole point: the column figures in
  /// [WidgetGridConstraints] describe the 12-column grid and mean nothing until
  /// [scaleSpan] brings them to the grid in front of the user. Row counts are
  /// absolute — a row is the same height on every grid — so they are compared
  /// as they are.
  ///
  /// Mobile widths are left alone rather than scaled: there the width is pinned
  /// by [lockToFullWidth], so a resize cannot have changed it and "correcting"
  /// it could only fight the lock.
  static ({int w, int h})? correctedSize(
    WidgetGridConstraints constraints, {
    required int w,
    required int h,
    required int slotCount,
  }) {
    var newW = w;
    var newH = h;

    if (slotCount > UspLayoutEnvelope.mobileSlotCount) {
      final minColumns =
          _scaleFromTwelfths(constraints.minColumns, toCols: slotCount);
      final maxColumns =
          _scaleFromTwelfths(constraints.maxColumns, toCols: slotCount);
      // Sequential rather than clamp(). WidgetGridConstraints asserts
      // min <= max, but a package widget's constraints are parsed from a remote
      // template and asserts are gone in release, so the one build where a bad
      // template could arrive is the one where clamp() would throw — inside a
      // gesture handler. Narrowing to the ceiling is the better failure.
      if (newW < minColumns) newW = minColumns;
      if (newW > maxColumns) newW = maxColumns;
    }

    if (newH < constraints.minHeightRows) newH = constraints.minHeightRows;
    if (newH > constraints.maxHeightRows) newH = constraints.maxHeightRows;

    if (newW == w && newH == h) return null;
    return (w: newW, h: newH);
  }

  /// Proportionally scales a serialised layout from [fromCols] to [toCols].
  ///
  /// * Tablet (12→8): `w=6` → `w=4`, preserving two-column pairs.
  /// * Mobile (12→4): delegates to [lockToFullWidth] — see there for why the
  ///   width stops being the user's to choose at all.
  /// * Constraints (minW / maxW) are scaled with the widths.
  static List<dynamic> scaleLayout(
    List<dynamic> layout,
    int fromCols,
    int toCols,
  ) {
    if (toCols <= UspLayoutEnvelope.mobileSlotCount) {
      return lockToFullWidth(layout, toCols);
    }

    return layout.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final x = map['x'] as int;
      final w = map['w'] as int;
      final minW = map['minW'] as int? ?? 1;
      final maxW = (map['maxW'] as num?)?.toInt() ?? fromCols;

      // Proportional scaling
      var newW = scaleSpan(w, fromCols: fromCols, toCols: toCols);
      var newX = (x * toCols / fromCols).round();
      if (newX + newW > toCols) newX = toCols - newW;
      if (newX < 0) {
        newX = 0;
        newW = toCols;
      }

      final newMinW = scaleSpan(minW, fromCols: fromCols, toCols: toCols);
      final newMaxW = scaleSpan(maxW, fromCols: fromCols, toCols: toCols)
          .clamp(newMinW, toCols);

      return {
        ...map,
        'x': newX,
        'w': newW,
        'minW': newMinW,
        'maxW': newMaxW.toDouble(),
      };
    }).toList();
  }

  /// Pins every item in [layout] to the full width of a [cols]-wide grid.
  ///
  /// Below five columns there is no width worth choosing — every card is either
  /// full-width or unreadably narrow — so on mobile the width stops being
  /// editable instead of being merely defaulted. `minW == maxW == cols` is the
  /// whole of what enforces that, as of `sliver_dashboard` 2.6.0 (#1399): the
  /// resolver clamps the new width to `[minW, maxW]` *and then* clamps `x` into
  /// `[originalRight - maxW, originalRight - minW]`
  /// (`dashboard_controller_impl.dart:1828-1842`), which for a card pinned at
  /// both caps is the single value it already has. The left-hand handles are held
  /// by the second clamp and the right-hand ones by the first.
  ///
  /// 0.9.1 had only the first, so the left-hand handles moved `x` and the package
  /// trimmed the width to what was left of the row — `x: 1, w: 3` dragged inwards
  /// and `x: 0, w: 3` dragged outwards, on a grid where neither width was
  /// authorised. That is why this used to be backed by a watcher writing the live
  /// layout back; the watcher is gone, and `edit_mode_interactions_test.dart`
  /// samples every frame of a left-edge drag, its bottom-left diagonal and an
  /// arrow-key move to show the geometry is now never produced rather than
  /// corrected afterwards.
  ///
  /// Only the inward end of that second clamp is ours, which is worth knowing
  /// before reading those tests: its lower bound is
  /// `max(limitX, originalRight - maxW)`, and `limitX` is already 0 for a card at
  /// the left edge, so a card cannot be dragged out of the row whatever the caps
  /// say. `minW` is what stops it being dragged *in*.
  ///
  /// Rewriting both caps rather than only lowering `maxW` also repairs what a
  /// projection from a wider grid produces, in both directions. Scaling
  /// proportionally gave a card with `maxW: 8` at 12 columns a `maxW` of 3 at 4
  /// columns while its width was set to 4 — a width outside its own cap, which the
  /// first resize would have snapped down to 3 of 4 columns. And a spec that
  /// declares `minW: 6` for the desktop grid arrives with a floor wider than the
  /// whole phone grid, which is not a mis-size but a crash: the engine asserts
  /// `currentL.minW <= cols` (`layout_engine.dart:963`) while the page is
  /// building.
  static List<dynamic> lockToFullWidth(List<dynamic> layout, int cols) {
    return layout.map((item) {
      return {
        ...Map<String, dynamic>.from(item as Map),
        'x': 0,
        'w': cols,
        'minW': cols,
        'maxW': cols.toDouble(),
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Card Forms (#1299) — the chosen density decides which sizes are legal
  // ---------------------------------------------------------------------------

  /// Cards that offer no [CardDensity.popup] entry.
  ///
  /// popup is central, not per card: [DashboardCardTemplate] renders
  /// [CardPopupForm] whenever the scope says popup, and its `value` falls back to
  /// the card title, so forcing popup renders on every card built through the
  /// template. `stats_panel` is the one registered card that is not — see the
  /// `'stats_panel' => UspStatsPanel()` arm of `UspWidgetFactory._buildCard` — so
  /// it has no popup path to force and its entry would be a control that visibly
  /// does nothing.
  static const Set<String> cardsWithoutPopupForm = {'stats_panel'};

  /// The footprint a popup tile collapses to on the 8- and 12-column grids.
  ///
  /// "Cannot be resized" needs a target. A card selected into popup is whatever
  /// size the user last dragged it to, and a locked 12-column icon-plus-value is
  /// both absurd and — with the handles gone — unrecoverable. Two columns is the
  /// 2×1 tile recorded as a decision on the issue before any of this was written
  /// (§2.6c item 1): the smallest footprint the popup form has content for, once
  /// [popupHeightRows] has taken the height.
  ///
  /// It sits *below* [kPopupBelow] on purpose, and this is where the two floors in
  /// this file are easy to confuse. Clearing 200px is [compactMinColumns]' job —
  /// §2.6c item 4 derives that figure, and it is why compact's floor is four
  /// columns rather than the three its consumers declare. The band below it is what
  /// popup is *for*: the form exists precisely because a label and a value stop
  /// fitting side by side there (§2.1). What makes a box this small safe to lock is
  /// not a width guarantee but [CardFormChoice.restoreW] — the previous box travels
  /// with the choice, because with the handles gone no gesture could recover it.
  static const int popupColumns = 2;

  /// The height a popup tile collapses to, on every grid.
  ///
  /// One row is the whole form: an icon, a label and a value on one line. On the
  /// 4-column grid this is the *only* axis popup touches — see [applyCardForms]
  /// for why the width there belongs to [lockToFullWidth] instead.
  static const int popupHeightRows = 1;

  /// The narrowest a [CardDensity.compact] card may be shrunk to, in 12-column
  /// units.
  ///
  /// Four columns, not the three every compact consumer declares as its
  /// `minColumns`: a 3-column card is 191.4px at its narrowest realization (§1.5)
  /// and so falls *below* [kPopupBelow], which is the width at which §2.1 says a
  /// label and a value no longer fit side by side in any locale. Four columns is
  /// the smallest span guaranteed to clear 200px at every screen width, so it is
  /// the floor at which the reduced form still reads (§2.6c, §D3).
  static const int compactMinColumns = 4;

  /// The shortest a [CardDensity.compact] card may be shrunk to, in rows.
  ///
  /// A floor on the height axis as well, so "shrinking is refused" holds in both
  /// directions rather than only sideways. The figure is two rows — a title line
  /// and a content line — and it is deliberately not a *measured* raise: the
  /// compact form is shorter than normal, so a number above what each card
  /// already declares could only be invented, and §2.4 is explicit that an
  /// unmeasured constant must not be frozen into the code. Every one of the seven
  /// compact consumers already declares `minHeightRows` of 2 or 3, so today this
  /// floor is the mechanism without the raise; the raise it would apply is real
  /// the moment a card declares less.
  static const int compactMinHeightRows = 2;

  /// The forms the user may pick for the card [id], in menu order, or an empty
  /// list when the card offers no choice.
  ///
  /// [CardDensity.normal] appears only alongside something to return *from* — on
  /// its own it is not a choice, just the status quo with a control attached.
  /// [CardDensity.compact] appears only for the seven cards that read the density
  /// (`normalAbove != null` is the existing predicate); offered anywhere else it
  /// would render exactly the normal form, which is a control that visibly does
  /// nothing. Building compact forms for the other eleven is card-own design work
  /// at #1288-#1291's scale and is out of this ticket's scope.
  static List<CardDensity> selectableForms(String id) {
    final spec = getById(id);
    // Package widgets load from a remote template and are not built through
    // DashboardCardTemplate, so neither form has a path on them.
    if (spec == null) return const [];

    final forms = <CardDensity>[
      if (spec.normalAbove != null) CardDensity.compact,
      if (!cardsWithoutPopupForm.contains(id)) CardDensity.popup,
    ];
    if (forms.isEmpty) return const [];
    return [CardDensity.normal, ...forms];
  }

  /// Applies each card's chosen form in [choices] to [layout] on a [cols]-wide
  /// grid, returning the sizes that form makes legal.
  ///
  /// This is the inversion #1299 is about. #1232 runs width → density; this runs
  /// density → the sizes that are legal, and it runs on *import*, from the stored
  /// pick, so the flags are never persisted twice and can be re-derived whenever
  /// the rules change:
  ///
  /// | picked | what changes |
  /// |---|---|
  /// | [CardDensity.popup] | `isResizable: false`, and the box is pinned to [popupColumns] × [popupHeightRows] |
  /// | [CardDensity.compact] | `minW`/`minH` raised to the floors, `isResizable` back on; the card grows to the floor if it was under it |
  /// | [CardDensity.normal] | the spec's own bounds, `isResizable` back on |
  ///
  /// `isStatic` is never touched: it also disables dragging, and reordering is the
  /// one edit a popup tile should keep.
  ///
  /// ## Two things this deliberately does not do
  ///
  /// It does not own the width on the 4-column grid. There popup asks to be small
  /// and the #1293 lock pins `x: 0, w: cols`; the two rules would overwrite each
  /// other, so each takes one axis — popup locks the height and stays full width,
  /// a short full-width bar, and [lockToFullWidth] runs after this and has the
  /// last word on `x`/`w`/`minW`/`maxW`. The values written here for mobile agree
  /// with the lock's on purpose, so the order of the two is not load-bearing.
  ///
  /// It does not re-promote a card whose width grew back past `normalAbove`. A
  /// chosen density is what renders or the choice does not stick, and a wide
  /// compact card is sparse, not broken.
  ///
  /// Returns [layout] itself when [choices] is empty, which is how an install
  /// with no picks stays byte-identical to one from before this ticket.
  static List<dynamic> applyCardForms(
    List<dynamic> layout,
    int cols,
    Map<String, CardFormChoice> choices,
  ) {
    if (choices.isEmpty) return layout;

    return layout.map((item) {
      final id = (item as Map)['id'];
      final choice = choices[id];
      if (choice == null) return item;

      final map = Map<String, dynamic>.from(item);
      final constraints = getById('$id')?.constraints[DisplayMode.normal];

      switch (choice.density) {
        case CardDensity.popup:
          // Pinned as caps as well as with the flag. isResizable: false is what
          // removes the handles, but a `w` outside its own [minW, maxW] is the
          // shape that made #1293 permanent — correctBounds and setSlotCount both
          // read the caps — so the box states its size in every field that
          // describes it.
          final w = cols <= UspLayoutEnvelope.mobileSlotCount
              ? cols
              : popupColumns.clamp(1, cols);
          _pinSpan(map, cols: cols, w: w, h: popupHeightRows);
          map['isResizable'] = false;

        case CardDensity.compact:
          _applyFloors(
            map,
            cols: cols,
            constraints: constraints,
            floorColumns: compactMinColumns,
            floorHeightRows: compactMinHeightRows,
          );
          map['isResizable'] = true;

        case CardDensity.normal:
          // Not a pin: normal *removes* a constraint, so it puts back exactly the
          // bounds the card would have had if no form had ever been picked. That
          // has to be a restore rather than a floor — popup wrote `maxW`/`maxH`
          // down to pin the tile, and a rule that only ever raises minima would
          // leave the card un-widenable after it expanded again.
          _applySpecBounds(map, cols: cols, constraints: constraints);
          map['isResizable'] = true;
      }

      return map;
    }).toList();
  }

  /// Pins [map]'s box to exactly [w] × [h] on a [cols]-wide grid, caps included.
  static void _pinSpan(
    Map<String, dynamic> map, {
    required int cols,
    required int w,
    required int h,
  }) {
    map['w'] = w;
    map['minW'] = w;
    map['maxW'] = w.toDouble();
    map['h'] = h;
    map['minH'] = h;
    map['maxH'] = h.toDouble();
    // Shrinking cannot push a card off the right edge, but a stored layout can
    // arrive already overhanging — the pin is applied to whatever is on disk, not
    // only to a card the user just picked.
    final x = map['x'];
    if (x is! int || x + w > cols) map['x'] = 0;
  }

  /// Puts back the bounds [constraints] declares, scaled to a [cols]-wide grid,
  /// and pulls the card's own size inside them.
  ///
  /// The undo of [_pinSpan] and of [_applyFloors]: the only bounds a card with no
  /// constraint on it should carry are its spec's, which is also what
  /// [LayoutItemFactory.fromSpec] gives a freshly added card. Cards with no spec
  /// (package widgets, or ids this build does not ship) are left exactly as they
  /// are — there is nothing to restore them *to*, and inventing bounds for a card
  /// we cannot describe is how a layout we did not author gets rewritten.
  static void _applySpecBounds(
    Map<String, dynamic> map, {
    required int cols,
    required WidgetGridConstraints? constraints,
  }) {
    if (constraints == null) return;

    // Mobile widths are left to [lockToFullWidth], as in [_applyFloors].
    if (cols > UspLayoutEnvelope.mobileSlotCount) {
      final minW = _scaleFromTwelfths(constraints.minColumns, toCols: cols);
      final maxW = _scaleFromTwelfths(constraints.maxColumns, toCols: cols)
          .clamp(minW, cols);
      map['minW'] = minW;
      map['maxW'] = maxW.toDouble();
      final w = map['w'];
      if (w is int) map['w'] = w.clamp(minW, maxW);
    }

    // Rows are absolute — a row is the same height on every grid — so they are
    // restored as declared.
    final minH = constraints.minHeightRows;
    final maxH =
        constraints.maxHeightRows < minH ? minH : constraints.maxHeightRows;
    map['minH'] = minH;
    map['maxH'] = maxH.toDouble();
    final h = map['h'];
    if (h is int) map['h'] = h.clamp(minH, maxH);
  }

  /// Raises [map]'s floors to the greater of its spec's bounds and the given
  /// floor, growing the card if it was already under the result.
  static void _applyFloors(
    Map<String, dynamic> map, {
    required int cols,
    required WidgetGridConstraints? constraints,
    required int floorColumns,
    required int floorHeightRows,
  }) {
    // Mobile widths are not scaled for the same reason [correctedSize] leaves
    // them alone: there the width is pinned by [lockToFullWidth], so anything
    // written here could only fight the lock.
    if (cols > UspLayoutEnvelope.mobileSlotCount) {
      final specMinW =
          _scaleFromTwelfths(constraints?.minColumns ?? 1, toCols: cols);
      final floorW = _scaleFromTwelfths(floorColumns, toCols: cols);
      final minW = (specMinW > floorW ? specMinW : floorW).clamp(1, cols);
      map['minW'] = minW;
      final w = map['w'];
      if (w is int && w < minW) map['w'] = minW;
      final maxW = (map['maxW'] as num?)?.toDouble() ?? cols.toDouble();
      if (maxW < minW) map['maxW'] = minW.toDouble();
    }

    // Row counts are absolute — a row is the same height on every grid — so they
    // are used as they are, exactly as [correctedSize] does.
    final specMinH = constraints?.minHeightRows ?? 1;
    final minH = specMinH > floorHeightRows ? specMinH : floorHeightRows;
    map['minH'] = minH;
    final h = map['h'];
    if (h is int && h < minH) map['h'] = minH;
    final maxH = (map['maxH'] as num?)?.toDouble() ?? minH.toDouble();
    if (maxH < minH) map['maxH'] = minH.toDouble();
  }

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
  static List<dynamic> alignMembership(
    List<dynamic> layout,
    List<dynamic> reference, {
    required int fromCols,
    required int toCols,
  }) {
    final stored = <String, dynamic>{
      for (final item in layout) (item as Map)['id'] as String: item,
    };

    return reference.map((refItem) {
      final id = (refItem as Map)['id'] as String;
      return stored[id] ?? scaleLayout([refItem], fromCols, toCols).single;
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
