@Tags(['dashboard-card'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/stat_blocks.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_stats_panel.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Regression tests for #1367.
///
/// Before the fix, `UspStatsPanel.build()` read `devicesDataProvider` with
/// `valueOrNull` and did `if (devicesData == null) return CardSkeleton.stats()`.
/// Because `valueOrNull` is `null` for BOTH loading and error, a single failed
/// domain (devices) was indistinguishable from "still loading" AND blanked all
/// five tiles at once — including the four backed by unrelated providers.
///
/// These tests pin the two behaviours the fix guarantees:
/// 1. A single domain error degrades only its own tile(s); the healthy tiles
///    keep rendering their data.
/// 2. A failed provider produces an error affordance (title kept + tappable
///    retry), NOT the loading skeleton.

enum _Mode { data, loading, error }

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

DevicesData _devicesData() => DevicesData(
      meshNetwork: MeshNetwork(
        master: MasterNode(deviceId: 'GATEWAY', model: 'MR7500'),
      ),
    );

class _FakeDevices extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final _Mode mode;
  _FakeDevices(this.mode);
  @override
  Future<DevicesData> build() => _resolve(mode, _devicesData);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWifi extends AsyncNotifier<WifiData> implements WifiDataNotifier {
  final _Mode mode;
  _FakeWifi(this.mode);
  @override
  Future<WifiData> build() => _resolve(mode, () => const WifiData.empty());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEthernet extends AsyncNotifier<EthernetData>
    implements EthernetDataNotifier {
  final _Mode mode;
  _FakeEthernet(this.mode);
  @override
  Future<EthernetData> build() => _resolve(mode, () => const EthernetData());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePf extends AsyncNotifier<PortForwardingData>
    implements PortForwardingDataNotifier {
  final _Mode mode;
  _FakePf(this.mode);
  @override
  Future<PortForwardingData> build() =>
      _resolve(mode, () => const PortForwardingData(ruleModels: []));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePt extends AsyncNotifier<PortTriggeringData>
    implements PortTriggeringDataNotifier {
  final _Mode mode;
  _FakePt(this.mode);
  @override
  Future<PortTriggeringData> build() =>
      _resolve(mode, () => const PortTriggeringData(ruleModels: []));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

Widget _panel({
  _Mode devices = _Mode.data,
  _Mode wifi = _Mode.data,
  _Mode ethernet = _Mode.data,
  _Mode pf = _Mode.data,
  _Mode pt = _Mode.data,
}) {
  return ProviderScope(
    overrides: [
      devicesDataProvider.overrideWith(() => _FakeDevices(devices)),
      wifiDataProvider.overrideWith(() => _FakeWifi(wifi)),
      ethernetDataProvider.overrideWith(() => _FakeEthernet(ethernet)),
      portForwardingDataProvider.overrideWith(() => _FakePf(pf)),
      portTriggeringDataProvider.overrideWith(() => _FakePt(pt)),
    ],
    child: MaterialApp(
      theme: _theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SizedBox(width: 900, child: UspStatsPanel()),
      ),
    ),
  );
}

void main() {
  group('UspStatsPanel #1367', () {
    testWidgets('all domains healthy → all five tiles render their values',
        (tester) async {
      await tester.pumpWidget(_panel());
      await tester.pumpAndSettle();

      // Five StatTiles, no full-panel skeleton.
      expect(find.byType(StatTile), findsNWidgets(5));
      expect(find.byType(CardSkeleton), findsNothing);
      // The error placeholder glyph must not appear when everything is healthy.
      expect(find.text('—'), findsNothing);
    });

    testWidgets(
        'single devices fault degrades only its tiles; healthy tiles still render',
        (tester) async {
      // Only devices faulted — wifi/ethernet/port providers are healthy.
      await tester.pumpWidget(_panel(devices: _Mode.error));
      await tester.pumpAndSettle();

      // The panel did NOT collapse into a single skeleton (the #1367 bug).
      expect(find.byType(CardSkeleton), findsNothing);

      // The three tiles backed by healthy providers still render their values:
      // Radios (wifi) "0/0", LAN Ports (ethernet) "0/0", Port Rules (pf+pt) "0".
      expect(find.text('0'), findsOneWidget); // Port Rules
      expect(find.text('0/0'), findsNWidgets(2)); // Radios + LAN Ports

      // The two devices-derived tiles (Router + Devices) show the error glyph,
      // not their (missing) values.
      expect(find.text('—'), findsNWidgets(2));

      // Error tiles keep their title mounted (title = domain label).
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.router), findsOneWidget);
      expect(find.text(l10n.devices), findsOneWidget);
    });

    testWidgets(
        'error tile is a distinct, tappable retry affordance — not a skeleton',
        (tester) async {
      await tester.pumpWidget(_panel(devices: _Mode.error));
      await tester.pumpAndSettle();

      // A failed provider must NOT render the loading skeleton (the core #1367
      // confusion between error and loading).
      expect(find.byType(CardSkeleton), findsNothing);

      // The error tile is tappable (InkWell from StatTile.onTap) so the user
      // can recover the single failed domain without a full page reload.
      final inkWells = find.descendant(
        of: find.byType(StatTile),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsWidgets);

      // A Semantics retry affordance is exposed on the error tiles.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.bySemanticsLabel(RegExp(l10n.retry)),
        findsWidgets,
      );
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
  });
}
