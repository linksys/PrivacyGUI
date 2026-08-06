@Tags(['ui'])
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_network_health_card.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget-layer regression coverage for PrivacyGUI#1143.
///
/// The helper `computeWanScore` is unit-tested separately; these tests assert
/// the *rendered* Network Health card honours the WAN link state — the gap
/// flagged in the PR review (helper covered, widget integration not):
/// - WAN down  → gauge shows "Disconnected" (not "Excellent"), metric chips
///               show the neutral placeholder instead of a misleading 0.
/// - WAN up    → normal health tier + numeric metrics render.
/// - loading   → `wanIsUpProvider` defaults to `true`, so a not-yet-loaded
///               link state renders as healthy, never a false disconnect.
void main() {
  final testTheme = AppTheme.create(
    brightness: Brightness.light,
    seedColor: Colors.blue,
    designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
  );

  // A healthy, loss-free WAN snapshot (loss 0% → loss-only score 100).
  InterfaceTrafficSnapshot healthyWan() => const InterfaceTrafficSnapshot(
        uploadBytesPerSec: 0,
        downloadBytesPerSec: 0,
        uploadPacketsPerSec: 500,
        downloadPacketsPerSec: 500,
        totalBytesSent: 0,
        totalBytesReceived: 0,
        totalPacketsSent: 0,
        totalPacketsReceived: 0,
      );

  TrafficAnalysisState stateWithWan(InterfaceTrafficSnapshot wan) {
    return TrafficAnalysisState(
      history: [
        MultiInterfaceSnapshot(
          // Fixed timestamp: Notifier.build in tests must be deterministic.
          timestamp: DateTime(2026, 1, 1),
          interfaces: {TrafficInterface.wan: wan},
        ),
      ],
    );
  }

  // The card is designed for a desktop dashboard tile; give tests a
  // representative width/height so a normal render is not reported as an
  // overflow (the traffic-light row is not a Wrap).
  void sizeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(600, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host({
    required TrafficAnalysisState traffic,
    required Override wanOverride,
  }) {
    return ProviderScope(
      overrides: [
        uspTrafficAnalysisProvider.overrideWith(
          () => _FakeTrafficNotifier(traffic),
        ),
        wanOverride,
      ],
      child: MaterialApp(
        theme: testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(child: UspNetworkHealthCard()),
        ),
      ),
    );
  }

  testWidgets('WAN down renders "Disconnected", not "Excellent" (#1143)',
      (tester) async {
    sizeSurface(tester);
    await tester.pumpWidget(host(
      traffic: stateWithWan(healthyWan()),
      // Force the link down even though traffic stats are perfectly healthy —
      // the exact #1143 condition.
      wanOverride: wanIsUpProvider.overrideWithValue(false),
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(UspNetworkHealthCard));
    final l = AppLocalizations.of(context)!;

    // The disconnect must surface; the healthy tier must NOT.
    expect(find.text(l.excellent), findsNothing,
        reason: 'a disconnected WAN must never read "Excellent" (#1143)');
    expect(find.textContaining(l.disconnected), findsWidgets,
        reason: 'WAN traffic light / gauge must show the disconnect');
    // Metric chips must not show a misleading numeric zero.
    expect(find.text('--'), findsWidgets,
        reason: 'loss/error/discard show a neutral placeholder when down');
  });

  testWidgets(
      'WAN down on a narrow tile does not overflow the traffic-light row',
      (tester) async {
    // The "WAN: Disconnected" label is longer than a health tier; on a narrow
    // tile the traffic-light Wrap must reflow to a second line rather than
    // overflow. Guards against reverting the Wrap back to a Row. See #1143.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(
      traffic: stateWithWan(healthyWan()),
      wanOverride: wanIsUpProvider.overrideWithValue(false),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'narrow WAN-down layout must not overflow');
  });

  testWidgets('WAN up renders the healthy tier and numeric metrics',
      (tester) async {
    sizeSurface(tester);
    await tester.pumpWidget(host(
      traffic: stateWithWan(healthyWan()),
      wanOverride: wanIsUpProvider.overrideWithValue(true),
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(UspNetworkHealthCard));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.excellent), findsWidgets,
        reason: 'a healthy, connected WAN scores 100 / Excellent');
    expect(find.textContaining(l.disconnected), findsNothing);
    // Numeric loss metric renders (no placeholder).
    expect(find.text('0.00%'), findsWidgets);
  });

  testWidgets('loading link state defaults to up (no false disconnect)',
      (tester) async {
    sizeSurface(tester);
    // Do NOT override wanIsUpProvider; leave the real provider, whose backing
    // wanDataProvider is still loading (no value) → default `true`.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uspTrafficAnalysisProvider.overrideWith(
            () => _FakeTrafficNotifier(stateWithWan(healthyWan())),
          ),
          // wanDataProvider left un-resolved: build() would hit real services,
          // so stub it to a perpetual loading state.
          wanDataProvider.overrideWith(() => _LoadingWanNotifier()),
        ],
        child: MaterialApp(
          theme: testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: UspNetworkHealthCard()),
          ),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(UspNetworkHealthCard));
    final l = AppLocalizations.of(context)!;

    expect(find.textContaining(l.disconnected), findsNothing,
        reason: 'a not-yet-loaded link state must not read as disconnected');
    expect(find.text(l.excellent), findsWidgets,
        reason: 'loading falls back to the healthy default (wanIsUp = true)');
  });
}

/// Fake traffic notifier that yields a fixed state without timers/services.
class _FakeTrafficNotifier extends UspTrafficAnalysisNotifier {
  _FakeTrafficNotifier(this._state);
  final TrafficAnalysisState _state;

  @override
  TrafficAnalysisState build() => _state;
}

/// WAN notifier that never completes, holding the provider in AsyncLoading so
/// `wanIsUpProvider` exercises its `?? true` loading fallback.
class _LoadingWanNotifier extends WanDataNotifier {
  @override
  Future<WanData> build() => Completer<WanData>().future;
}
