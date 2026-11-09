import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

/// Widget specifications for all USP Dashboard cards, and the lookup by id.
///
/// All constraints use DisplayMode.normal only (DisplayMode switching deferred).
/// Column values are based on a 12-column layout.
///
/// This is the file a card is added to, renamed in, or has its grid constraints
/// moved in. Call sites read `all` and `getById` through `UspWidgetSpecs`, which
/// forwards them (#1311); no literal is referenced from outside this file.
abstract class UspWidgetSpecRegistry {
  UspWidgetSpecRegistry._();

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
}
