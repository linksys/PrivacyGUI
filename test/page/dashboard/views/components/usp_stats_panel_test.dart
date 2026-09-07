// `layout-gate` because the overflow group below is a PR-blocking layout check:
// `run_tests.sh` excludes `golden||loc||ui`, so any of those tags would let it
// leave the PR command in silence. Not `overflow` as well — that tag is the
// pre-commit selector for the five *registered* sweeps, each of which owns a
// frozen baseline under `test/fixtures/overflow_baselines/`. This group pumps
// `probeCardOverflow` directly rather than through `runOverflowSweep`, so it has no
// baseline row and `./tool/overflow_baseline.sh` does not know it; carrying the tag
// would make `--tags overflow` mean two different things. Same choice, for the same
// reason, as the two detail-view overflow files under `test/page/topology/` and
// `test/page/devices/`.
//
// Written as `dashboard-card` on `gate/fix-1367`, which is what this tag was called
// on `dev-2.7.0`; #1336 renamed it and the merge would otherwise have left this file
// naming a tag `dart_test.yaml` no longer declares — blocking a PR by luck rather
// than by selection, which is exactly what `dart_test.yaml`'s own note predicts for
// the next such file.
@Tags(['layout-gate'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/stat_blocks.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_stats_panel.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/test_data/devices_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

/// Regression tests for #1367.
///
/// Before the fix, `UspStatsPanel.build()` read `devicesDataProvider` with
/// `valueOrNull` and did `if (devicesData == null) return CardSkeleton.stats()`.
/// Because `valueOrNull` is `null` for BOTH loading and error, a single failed
/// domain (devices) was indistinguishable from "still loading" AND blanked all
/// five tiles at once — including the four backed by unrelated providers.
///
/// These tests pin the behaviours the fix guarantees:
/// 1. A single domain error degrades only its own tile(s); the healthy tiles
///    keep rendering their data — for *every* domain, not just devices.
/// 2. A provider that failed with no value produces an error affordance (title
///    kept + tappable retry), NOT the loading skeleton.
/// 3. Tapping that affordance actually re-fetches, and only the failed provider.
/// 4. A provider that failed while *holding* a value keeps rendering it: a
///    failed background refresh must not blank a figure the tile still has.
/// 5. A retry in flight reads as loading, so the tap is acknowledged and the tap
///    target is gone while it runs.

enum _Mode { data, loading, error }

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The shared devices fixture: one node, two clients (both active).
final _devicesData = DevicesTestData.createSimpleDevicesData();

/// Resolves a fake notifier's `build()` to the requested async state:
/// - data: the fixture value
/// - error: throws (settles into AsyncError)
/// - loading: a never-completing Future (stays in AsyncLoading)
Future<T> _resolve<T>(_Mode mode, T Function() value) {
  switch (mode) {
    case _Mode.data:
      return Future.value(value());
    case _Mode.error:
      return Future.error(Exception('injected fault #1367'));
    case _Mode.loading:
      return Completer<T>().future; // never completes
  }
}

/// Counts `build()` runs so a test can assert which providers a retry re-fetched
/// — the assertion that catches an `onRetry` wired to nothing, and the one that
/// catches a retry invalidating a provider that had not failed.
class _Builds {
  int devices = 0;
  int wifi = 0;
  int ethernet = 0;
  int pf = 0;
  int pt = 0;
}

/// The fakes extend the real notifiers rather than implementing them, which is
/// the pattern established by `mock_dashboard_cards.dart`: overriding `build()`
/// on the real class needs no `noSuchMethod` stub, and it keeps the fake honest
/// if the notifier gains members.
class _FakeDevices extends DevicesDataNotifier {
  _FakeDevices(this.mode, this.builds);
  final _Mode mode;
  final _Builds builds;
  @override
  Future<DevicesData> build() {
    builds.devices++;
    return _resolve(mode, () => _devicesData);
  }
}

class _FakeWifi extends WifiDataNotifier {
  _FakeWifi(this.mode, this.builds);
  final _Mode mode;
  final _Builds builds;
  @override
  Future<WifiData> build() {
    builds.wifi++;
    return _resolve(mode, () => const WifiData.empty());
  }
}

class _FakeEthernet extends EthernetDataNotifier {
  _FakeEthernet(this.mode, this.builds);
  final _Mode mode;
  final _Builds builds;
  @override
  Future<EthernetData> build() {
    builds.ethernet++;
    return _resolve(mode, () => const EthernetData());
  }
}

class _FakePf extends PortForwardingDataNotifier {
  _FakePf(this.mode, this.builds);
  final _Mode mode;
  final _Builds builds;
  @override
  Future<PortForwardingData> build() {
    builds.pf++;
    return _resolve(mode, () => const PortForwardingData(ruleModels: []));
  }
}

class _FakePt extends PortTriggeringDataNotifier {
  _FakePt(this.mode, this.builds);
  final _Mode mode;
  final _Builds builds;
  @override
  Future<PortTriggeringData> build() {
    builds.pt++;
    return _resolve(mode, () => const PortTriggeringData(ruleModels: []));
  }
}

/// A devices notifier whose FIRST build succeeds and whose every later build
/// fails — i.e. "had data, then the refresh failed", the state riverpod
/// represents as `AsyncError` carrying the previous value.
class _FailsOnRefreshDevices extends DevicesDataNotifier {
  _FailsOnRefreshDevices(this.builds);
  final _Builds builds;
  @override
  Future<DevicesData> build() {
    builds.devices++;
    if (builds.devices == 1) return Future.value(_devicesData);
    return Future.error(Exception('refresh failed #1367'));
  }
}

/// A devices notifier that fails its first build and then never settles, so the
/// frame *during* a retry can be inspected.
class _HangsOnRetryDevices extends DevicesDataNotifier {
  _HangsOnRetryDevices(this.builds);
  final _Builds builds;
  @override
  Future<DevicesData> build() {
    builds.devices++;
    if (builds.devices == 1) {
      return Future.error(Exception('cold load failed #1367'));
    }
    return Completer<DevicesData>().future; // retry stays in flight
  }
}

/// The semantics boundary the dashboard grid puts around every card in
/// production: `sliver_dashboard`'s `DashboardItemWidget` builds
/// `Semantics(container: true, label: semanticLabel, ...)` around the widget the
/// factory returned (`dashboard_item_widget.dart:592` in 2.6.0). A tile that does
/// not declare a boundary of its own is absorbed into it — the failure #1301
/// documents — so the a11y assertions have to be made under this ancestor, not
/// under a bare `Scaffold`, or they pass for the wrong reason.
const _kGridItemLabel = 'Stat Panel';

Widget _panel({
  _Mode devices = _Mode.data,
  _Mode wifi = _Mode.data,
  _Mode ethernet = _Mode.data,
  _Mode pf = _Mode.data,
  _Mode pt = _Mode.data,
  _Builds? builds,
  DevicesDataNotifier Function()? devicesOverride,
  bool underGridItem = false,
}) {
  final b = builds ?? _Builds();
  const panel = SizedBox(width: 900, child: UspStatsPanel());
  return ProviderScope(
    overrides: [
      devicesDataProvider
          .overrideWith(devicesOverride ?? () => _FakeDevices(devices, b)),
      wifiDataProvider.overrideWith(() => _FakeWifi(wifi, b)),
      ethernetDataProvider.overrideWith(() => _FakeEthernet(ethernet, b)),
      portForwardingDataProvider.overrideWith(() => _FakePf(pf, b)),
      portTriggeringDataProvider.overrideWith(() => _FakePt(pt, b)),
    ],
    child: MaterialApp(
      theme: _theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: underGridItem
            ? Semantics(
                container: true,
                label: _kGridItemLabel,
                child: panel,
              )
            : panel,
      ),
    ),
  );
}

/// The retry affordance for a given tile, located by the semantics node the
/// error branch adds.
///
/// A substring match is needed because the node's label concatenates with the
/// tile's own text (`"Router, Retry\n—\nRouter"`), but the localized string is
/// escaped before it becomes a pattern: `RegExp(l10n.retry)` compiles a
/// translation as a regex and breaks on any locale whose text contains a
/// metacharacter.
Finder _retryAffordance(String label, AppLocalizations l10n) =>
    find.bySemanticsLabel(RegExp(RegExp.escape('$label, ${l10n.retry}')));

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('UspStatsPanel #1367', () {
    testWidgets('all domains healthy → all five tiles render their values',
        (tester) async {
      await tester.pumpWidget(_panel());
      await tester.pumpAndSettle();

      expect(find.byType(StatTile), findsNWidgets(5));
      // The error placeholder glyph must not appear when everything is healthy.
      expect(find.text('—'), findsNothing);
      // The fixture is one node with two active clients.
      expect(find.text('1'), findsOneWidget); // Router
      expect(find.text('2'), findsOneWidget); // Devices
    });

    testWidgets(
        'single devices fault degrades only its tiles; healthy tiles still render',
        (tester) async {
      // Only devices faulted — wifi/ethernet/port providers are healthy.
      await tester.pumpWidget(_panel(devices: _Mode.error));
      await tester.pumpAndSettle();

      // The three tiles backed by healthy providers still render their values:
      // Radios (wifi) "0/0", LAN Ports (ethernet) "0/0", Port Rules (pf+pt) "0".
      expect(find.text('0'), findsOneWidget); // Port Rules
      expect(find.text('0/0'), findsNWidgets(2)); // Radios + LAN Ports

      // The two devices-derived tiles (Router + Devices) show the error glyph,
      // not their (missing) values.
      expect(find.text('—'), findsNWidgets(2));

      // Error tiles keep their title mounted (title = domain label).
      expect(find.text(l10n.router), findsOneWidget);
      expect(find.text(l10n.devices), findsOneWidget);
    });

    // Each non-devices domain gets the same guarantee: the #1367 defect blanked
    // the whole row, so "only this tile degraded" has to hold per domain, not
    // just for the one that happened to trigger the bug.
    testWidgets('a wifi fault degrades only the Radios tile', (tester) async {
      await tester.pumpWidget(_panel(wifi: _Mode.error));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Router
      expect(find.text('2'), findsOneWidget); // Devices
      expect(find.text('0/0'), findsOneWidget); // LAN Ports
      expect(find.text('0'), findsOneWidget); // Port Rules
    });

    testWidgets('an ethernet fault degrades only the LAN Ports tile',
        (tester) async {
      await tester.pumpWidget(_panel(ethernet: _Mode.error));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0/0'), findsOneWidget); // Radios only
      expect(find.text('0'), findsOneWidget); // Port Rules
    });

    testWidgets('error tile is a distinct, tappable retry affordance',
        (tester) async {
      await tester.pumpWidget(_panel(devices: _Mode.error));
      await tester.pumpAndSettle();

      // The error tile is tappable (InkWell from StatTile.onTap) so the user
      // can recover the single failed domain without a full page reload.
      expect(
        find.descendant(
          of: find.byType(StatTile),
          matching: find.byType(InkWell),
        ),
        findsWidgets,
      );
      expect(_retryAffordance(l10n.router, l10n), findsOneWidget);
    });

    testWidgets('the error tile announces its label once and can be activated',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final builds = _Builds();
      await tester.pumpWidget(_panel(devices: _Mode.error, builds: builds));
      await tester.pumpAndSettle();

      // One node per failed tile, labelled exactly once. The node used to
      // concatenate with the tile's own text ("Router, Retry\n—\nRouter"), so the
      // title was read out twice.
      expect(
        find.bySemanticsLabel('${l10n.router}, ${l10n.retry}'),
        findsOneWidget,
      );

      // Excluding the child's semantics also drops the InkWell's tap action, so
      // the node declares its own. Driven through the semantics action rather
      // than a pointer tap, which is the path assistive technology takes and the
      // only one that would catch a node that is a button in name only.
      final node = tester.getSemantics(
        find.bySemanticsLabel('${l10n.router}, ${l10n.retry}'),
      );
      expect(
        node,
        matchesSemantics(
          label: '${l10n.router}, ${l10n.retry}',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // The tile's own text must not survive as a second node underneath. With
      // the child's semantics left in, `container: true` gave a clean parent
      // label but the tile kept a node of its own reading "—\nRouter", so a
      // traversal announced the title twice across the two.
      expect(
        node.childrenCount,
        0,
        reason: 'the tile text must not be announced as a second node',
      );
      // `SemanticsController.tap` refuses a node that does not report the action,
      // so this both fires it and asserts the node is activatable.
      tester.semantics.tap(
        find.semantics.byLabel('${l10n.router}, ${l10n.retry}'),
      );
      await tester.pumpAndSettle();

      expect(builds.devices, 2);
      semantics.dispose();
    });

    testWidgets(
        'the error tile keeps its own node under the dashboard grid boundary',
        (tester) async {
      // The grid item wraps every card in `Semantics(container: true, label:
      // ...)`. A tile that does not declare a boundary of its own is absorbed
      // into that node, whose rect is the whole card — #1301's failure, where a
      // click anywhere on the card fired the absorbed action. Release web builds
      // keep the semantics tree alive for E2E and route clicks through the DOM
      // overlay, so this is a real click target, not only a screen-reader one.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _panel(devices: _Mode.error, underGridItem: true),
      );
      await tester.pumpAndSettle();

      final label = '${l10n.router}, ${l10n.retry}';
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node,
        matchesSemantics(label: label, isButton: true, hasTapAction: true),
        reason: 'the retry node must survive as its own boundary, not merge '
            'into the grid item',
      );

      // The two things #1301 actually turned on, asserted directly rather than
      // through the label:
      //
      // 1. The tap action stayed on this node instead of being absorbed by the
      //    grid item. Without a boundary the grid item is what carries `tap`,
      //    and its rect is the whole card — every healthy tile becomes a click
      //    target for whichever failed tile got absorbed.
      final gridItem = tester.getSemantics(
        find.bySemanticsLabel(RegExp(RegExp.escape(_kGridItemLabel))),
      );
      expect(
        gridItem.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the retry tap must not be absorbed into the card-wide node',
      );
      // 2. The node's rect is this tile's, not the card's. 900px of panel over
      //    five tiles: a tile is well under half the width the grid item covers.
      expect(node.rect.width, lessThan(gridItem.rect.width / 2));
      // The grid item is still a boundary of its own, i.e. the tile carved its
      // node out from under it rather than replacing it. Its label concatenates
      // the healthy tiles' text, so it is matched as a substring.
      expect(gridItem.label, contains(_kGridItemLabel));
      expect(gridItem.label, isNot(contains(l10n.retry)));
      semantics.dispose();
    });

    testWidgets('a still-loading domain keeps a per-tile skeleton (not error)',
        (tester) async {
      await tester.pumpWidget(_panel(devices: _Mode.loading));
      // Do not settle — the loading provider never completes.
      await tester.pump();

      // The two devices-derived tiles are in the loading branch: no error glyph.
      expect(find.text('—'), findsNothing);
      // Healthy tiles still render.
      expect(find.byType(StatTile), findsNWidgets(3)); // wifi, ethernet, ports
    });

    // -------------------------------------------------------------------------
    // The retry wiring itself
    // -------------------------------------------------------------------------

    testWidgets('tapping the retry affordance re-fetches the failed provider',
        (tester) async {
      final builds = _Builds();
      await tester.pumpWidget(_panel(devices: _Mode.error, builds: builds));
      await tester.pumpAndSettle();
      expect(builds.devices, 1);

      await tester.tap(_retryAffordance(l10n.router, l10n));
      await tester.pumpAndSettle();

      // Without this, replacing `onRetry` with `(){}` leaves the suite green.
      expect(builds.devices, 2, reason: 'retry must invalidate its provider');
      // ...and only its own: the healthy providers are not re-fetched.
      expect(
        [builds.wifi, builds.ethernet, builds.pf, builds.pt],
        [1, 1, 1, 1],
        reason: 'a tile retry must not re-fetch unrelated domains',
      );
    });

    testWidgets('a retry that recovers puts the value back', (tester) async {
      final builds = _Builds();
      await tester.pumpWidget(_panel(
        builds: builds,
        devicesOverride: () => _RecoversOnRetryDevices(builds),
      ));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsNWidgets(2));

      await tester.tap(_retryAffordance(l10n.router, l10n));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsNothing);
      expect(find.text('1'), findsOneWidget); // Router
      expect(find.text('2'), findsOneWidget); // Devices
    });

    testWidgets('a retry in flight reads as loading, not as an error',
        (tester) async {
      final builds = _Builds();
      await tester.pumpWidget(_panel(
        builds: builds,
        devicesOverride: () => _HangsOnRetryDevices(builds),
      ));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsNWidgets(2));

      await tester.tap(_retryAffordance(l10n.router, l10n));
      await tester.pump();

      // `ref.invalidate` on an errored provider emits AsyncError(isLoading:
      // true), so reading `hasError` before `isLoading` left this frame
      // byte-identical to the pre-tap one — the tap looked like it did nothing.
      expect(
        find.text('—'),
        findsNothing,
        reason: 'an in-flight retry must not still read as a settled error',
      );
      // The tap target is gone while the retry runs, which is the in-flight
      // guard: the user cannot queue a second request at the bridge.
      expect(_retryAffordance(l10n.router, l10n), findsNothing);
      expect(builds.devices, 2);
    });

    // -------------------------------------------------------------------------
    // A failed refresh must not blank a value the tile still holds
    // -------------------------------------------------------------------------

    testWidgets('a failed background refresh keeps the last-known value',
        (tester) async {
      final builds = _Builds();
      await tester.pumpWidget(_panel(
        builds: builds,
        devicesOverride: () => _FailsOnRefreshDevices(builds),
      ));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget); // Router, from the first build

      // The refresh path: SSE invalidation, orchestrator refreshAll(), and the
      // retry backoff all do exactly this.
      final element = tester.element(find.byType(UspStatsPanel));
      ProviderScope.containerOf(element).invalidate(devicesDataProvider);
      await tester.pumpAndSettle();

      expect(builds.devices, 2, reason: 'the refresh must have been attempted');
      // riverpod's AsyncError carries the previous value, so the figure is still
      // there to render. Checking `hasError` first replaced it with `—`, which
      // is a regression against the code #1367 set out to fix.
      expect(
        find.text('1'),
        findsOneWidget,
        reason: 'a stale figure beats a blank one',
      );
      expect(find.text('—'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Port Rules — the only two-provider tile
    // -------------------------------------------------------------------------

    testWidgets('Port Rules degrades when either of its providers fails',
        (tester) async {
      await tester.pumpWidget(_panel(pf: _Mode.error));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);

      await tester.pumpWidget(_panel(pt: _Mode.error));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('Port Rules waits on a loading side rather than erroring',
        (tester) async {
      // One side failed, the other has not resolved: nothing has failed
      // outright yet, so the tile must not commit to the error affordance.
      await tester.pumpWidget(_panel(pf: _Mode.error, pt: _Mode.loading));
      await tester.pump();

      expect(find.text('—'), findsNothing);
    });

    testWidgets('a Port Rules retry re-fetches only the side that failed',
        (tester) async {
      final builds = _Builds();
      await tester.pumpWidget(_panel(pt: _Mode.error, builds: builds));
      await tester.pumpAndSettle();
      expect([builds.pf, builds.pt], [1, 1]);

      await tester.tap(_retryAffordance(l10n.portRules, l10n));
      await tester.pumpAndSettle();

      expect(builds.pt, 2, reason: 'the failed side must be re-fetched');
      expect(
        builds.pf,
        1,
        reason:
            'the healthy side must not be re-fetched — every request queues '
            'at the same single-threaded bridge',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Overflow at the panel's real narrowest box
  // ---------------------------------------------------------------------------

  group('UspStatsPanel at its narrowest grid box', () {
    // #1367 replaced the row-wide `CardSkeleton.stats()` with a per-tile skeleton
    // and a per-tile error affordance. Both are new boxes inside the strip, and
    // the #1183 gate cannot reach either: it resolves every provider from the
    // kitchen-sink fixture, so it only ever pumps the data branch. The picked-form
    // files cannot reach them either — `stats_panel` has no popup or compact form
    // to pick. So the two new branches are swept here, at the width the grid
    // really gives the panel.
    //
    // That width is the whole grid at the 320px screen floor: `minColumns: 6` of
    // 12 and always full width, so 288px across five tiles and their gaps is the
    // narrowest realization of any span. Taken from the spec through the gate's own
    // enumeration rather than hardcoded, so it moves if either changes.
    //
    // What this catches, measured by mutation: an over-tall tile child fails all
    // six cases. An over-*wide* one does not — a `Column` reports no horizontal
    // RenderFlex overflow for a child wider than itself, it just paints outside.
    // That is a property of every overflow sweep in this suite, not of this group;
    // the tiles' widths are held by their `Expanded`, and clipping inside a tile is
    // the golden pipeline's to see.
    // Resolved at collection time, not in `setUpAll`: the widths feed the test
    // names. It is pure grid arithmetic over the spec, so nothing here needs the
    // binding — only the fonts do.
    final spec = UspWidgetSpecs.getById('stats_panel')!;
    final narrowest = widthCasesFor(spec).first;
    final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;

    setUpAll(() async {
      // Real glyph metrics, for the reason the #1183 gate loads them: the Ahem
      // block measures every character the same width, so a label that overflows
      // in production may fit here and vice versa.
      await loadAppFonts();
    });

    // Three locales rather than all 26, matching the sibling forced-form sweep:
    // English as the baseline, German for the longest compounds in Latin script,
    // and zh_TW for the widest glyphs. The tile's value is a digit either way; the
    // label is what varies, and it is the label that can overflow.
    for (final locale in const [
      Locale('en'),
      Locale('de'),
      Locale('zh', 'TW')
    ]) {
      final tag = locale.countryCode == null || locale.countryCode!.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';

      for (final branch in _Mode.values.where((m) => m != _Mode.data)) {
        testWidgets(
            'the ${branch.name} branch is clean at '
            '${narrowest.cardWidth.toStringAsFixed(0)}px ($tag)',
            (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            // The id keys the harness's geometry only; the widget under test is
            // the override, which is the panel with every provider driven into
            // the branch being swept. The factory-built panel would resolve from
            // the kitchen-sink fixture and land in the data branch instead.
            cardId: 'stats_panel',
            cardOverride: const UspStatsPanel(),
            widthCase: narrowest,
            cardHeightRows: rows,
            tabIndex: 0,
            locale: locale,
            extraOverrides: [
              devicesDataProvider
                  .overrideWith(() => _FakeDevices(branch, _Builds())),
              wifiDataProvider.overrideWith(() => _FakeWifi(branch, _Builds())),
              ethernetDataProvider
                  .overrideWith(() => _FakeEthernet(branch, _Builds())),
              portForwardingDataProvider
                  .overrideWith(() => _FakePf(branch, _Builds())),
              portTriggeringDataProvider
                  .overrideWith(() => _FakePt(branch, _Builds())),
            ],
          );

          final significant =
              incidents.where((i) => i.pixels > kOverflowTolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: 'the ${branch.name} branch overflowed the panel\'s box:\n'
                '${significant.join('\n')}',
          );
        });
      }
    }
  });
}

/// A devices notifier that fails its first build and succeeds on retry.
class _RecoversOnRetryDevices extends DevicesDataNotifier {
  _RecoversOnRetryDevices(this.builds);
  final _Builds builds;
  @override
  Future<DevicesData> build() {
    builds.devices++;
    if (builds.devices == 1) {
      return Future.error(Exception('cold load failed #1367'));
    }
    return Future.value(_devicesData);
  }
}
