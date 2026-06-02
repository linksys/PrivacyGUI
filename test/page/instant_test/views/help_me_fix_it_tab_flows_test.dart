// Tests for the HelpMeFixItTab guided-flow system (USP branch).
//
// Covers:
//   1. FlowMenu renders qualifier when _showAllFlows is null
//   2. FlowMenu "One specific device" routes to Flow 3 (via onSelect)
//   3. FlowMenu "Everything in my home" shows flow cards
//   4. HelpMeFixItTab renders landing (no active flow) when no pendingFlowNotifier
//   5. HelpMeFixItTab launches Flow 1 when pendingFlowNotifier fires 1
//   6. HelpMeFixItTab fires -1 reset when tab re-tapped (via pendingFlowNotifier)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_test/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

import '../../../mocks/mock_instant_test_notifier.dart';
import '../../../mocks/test_data/instant_test_state_data.dart';

// ── Stub notifiers ────────────────────────────────────────────────────────────

/// Stub WifiDataNotifier that returns an empty WifiData without making network
/// calls. Avoids the SSE/USP boot sequence during widget tests.
class _StubWifiDataNotifier extends WifiDataNotifier {
  @override
  Future<WifiData> build() async => const WifiData.empty();
}

/// Stub UspInstantPrivacyNotifier that returns a disabled privacy state.
class _StubInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  @override
  Future<UspInstantPrivacyState> build() async => const UspInstantPrivacyState(
        isEnabled: false,
        connectedDevices: [],
        allowedDevices: [],
        macFilterContext: MacFilterContext.empty,
      );
}

/// Stub BrowserDiagnosticService that never completes — prevents Flow 1 from
/// auto-running diagnostics during widget tests.
class _StubbedBrowserDiagnosticService extends BrowserDiagnosticService {
  @override
  Future<GatewayPingResult> pingGateway() =>
      Completer<GatewayPingResult>().future;

  /// Both pingPublicIp and pingGateway return [GatewayPingResult] in this
  /// service — there is no separate PublicIpPingResult type.
  @override
  Future<GatewayPingResult> pingPublicIp() =>
      Completer<GatewayPingResult>().future;

  @override
  Future<DnsCheckResult> checkDns() => Completer<DnsCheckResult>().future;

  @override
  Future<SpeedTestResult> runInternetSpeedTest({
    void Function(String step)? onStep,
  }) =>
      Completer<SpeedTestResult>().future;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(
  InstantTestState state,
  Widget child, {
  BrowserDiagnosticService? diagnosticService,
}) {
  return ProviderScope(
    overrides: [
      instantTestProvider.overrideWith(() => MockInstantTestNotifier(state)),
      wifiDataProvider.overrideWith(() => _StubWifiDataNotifier()),
      uspInstantPrivacyProvider
          .overrideWith(() => _StubInstantPrivacyNotifier()),
      browserDiagnosticServiceProvider.overrideWithValue(
        diagnosticService ?? _StubbedBrowserDiagnosticService(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _wrapTab(
  InstantTestState state, {
  ValueNotifier<int?>? pendingFlowNotifier,
  BrowserDiagnosticService? diagnosticService,
}) {
  return _wrap(
    state,
    HelpMeFixItTab(pendingFlowNotifier: pendingFlowNotifier),
    diagnosticService: diagnosticService,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. FlowMenu qualifier (initial state) ─────────────────────────────────
  group('FlowMenu — initial qualifier', () {
    testWidgets('shows qualifier question when no flow is selected',
        (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      // The qualifier card text
      expect(find.text('What are you running into?'), findsOneWidget);
      expect(find.text('Is it affecting one specific device or everything?'),
          findsOneWidget);
    });

    testWidgets('shows both qualifier buttons', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      expect(find.text('One specific device'), findsOneWidget);
      expect(find.text('Everything in my home'), findsOneWidget);
    });

    testWidgets('does not show flow cards in initial state', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      // Flow-specific cards are only shown after "Everything in my home"
      expect(find.text('My internet isn\'t working'), findsNothing);
      expect(find.text('My internet is slow'), findsNothing);
    });
  });

  // ── 2. FlowMenu "One specific device" routes to Flow 3 ───────────────────
  group('FlowMenu — One specific device → Flow 3', () {
    testWidgets('tapping "One specific device" launches Flow 3 shell',
        (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('One specific device'));
      await tester.pump();

      // Flow shell title for flow 3
      expect(find.text('Device connectivity issues'), findsOneWidget);
    });

    testWidgets('Flow 3 shell shows Back button', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('One specific device'));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Back button from Flow 3 returns to qualifier', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('One specific device'));
      await tester.pump();

      // Verify we're in the flow
      expect(find.text('Device connectivity issues'), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // Returns to qualifier
      expect(find.text('What are you running into?'), findsOneWidget);
    });
  });

  // ── 3. FlowMenu "Everything in my home" shows flow cards ─────────────────
  group('FlowMenu — Everything in my home → flow cards', () {
    testWidgets('tapping "Everything in my home" shows flow cards',
        (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('Everything in my home'));
      await tester.pump();

      // Flow cards should now appear
      expect(find.text('My internet isn\'t working'), findsOneWidget);
      expect(find.text('My internet is slow'), findsOneWidget);
    });

    testWidgets('flow cards list shows all 5 flows', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('Everything in my home'));
      await tester.pump();

      expect(find.text('My internet isn\'t working'), findsOneWidget);
      expect(find.text('My internet is slow'), findsOneWidget);
      expect(find.text('Device connectivity issues'), findsOneWidget);
      expect(find.text('WiFi doesn\'t reach a room'), findsOneWidget);
      expect(find.text('My connection keeps cutting out'), findsOneWidget);
    });

    testWidgets('tapping a flow card launches the flow shell', (tester) async {
      await tester.pumpWidget(
          _wrapTab(InstantTestStateData.idleState()));
      await tester.pump();

      await tester.tap(find.text('Everything in my home'));
      await tester.pump();

      // Tap "My internet is slow" card
      await tester.tap(find.text('My internet is slow'));
      await tester.pump();

      // Flow 2 shell title
      expect(find.text('My internet is slow'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  // ── 4. Landing renders when no pendingFlowNotifier ────────────────────────
  group('HelpMeFixItTab — landing state (no pendingFlowNotifier)', () {
    testWidgets('renders FlowMenu qualifier without a pendingFlowNotifier',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          InstantTestStateData.idleState(),
          const HelpMeFixItTab(), // no pendingFlowNotifier
        ),
      );
      await tester.pump();

      expect(find.text('What are you running into?'), findsOneWidget);
    });

    testWidgets('widget renders without errors when state is allClear',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          InstantTestStateData.allClearState(),
          const HelpMeFixItTab(),
        ),
      );
      await tester.pump();

      expect(find.byType(HelpMeFixItTab), findsOneWidget);
    });
  });

  // ── 5. pendingFlowNotifier fires 1 → launches Flow 1 ─────────────────────
  group('HelpMeFixItTab — pendingFlowNotifier launches flow', () {
    testWidgets('firing 1 on pendingFlowNotifier launches Flow 1',
        (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      // Starts at landing
      expect(find.text('What are you running into?'), findsOneWidget);

      // Fire flow 1
      notifier.value = 1;
      await tester.pump();

      // Flow 1 shell should be displayed
      expect(find.text('My internet isn\'t working'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('pendingFlowNotifier value is consumed (set to null)',
        (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      notifier.value = 1;
      await tester.pump();

      // Value should be consumed by the widget
      expect(notifier.value, isNull);

      notifier.dispose();
    });

    testWidgets('firing 4 launches Flow 4 (WiFi coverage)', (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      notifier.value = 4;
      await tester.pump();

      expect(find.text('WiFi doesn\'t reach a room'), findsOneWidget);

      notifier.dispose();
    });
  });

  // ── 6. pendingFlowNotifier fires -1 resets to landing ────────────────────
  group('HelpMeFixItTab — pendingFlowNotifier -1 resets to landing', () {
    testWidgets('firing -1 while on landing keeps landing visible',
        (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      notifier.value = -1;
      await tester.pump();

      // Still on landing
      expect(find.text('What are you running into?'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('firing -1 while in a flow returns to landing', (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      // Launch flow 4 (simple stateless flow — no async diagnostics)
      notifier.value = 4;
      await tester.pump();
      expect(find.text('WiFi doesn\'t reach a room'), findsOneWidget);

      // Simulate tab re-tap with -1
      notifier.value = -1;
      await tester.pump();

      // Should be back at landing
      expect(find.text('What are you running into?'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      notifier.dispose();
    });

    testWidgets('-1 value is consumed after reset', (tester) async {
      final notifier = ValueNotifier<int?>(null);
      await tester.pumpWidget(
        _wrapTab(
          InstantTestStateData.idleState(),
          pendingFlowNotifier: notifier,
        ),
      );
      await tester.pump();

      notifier.value = -1;
      await tester.pump();

      expect(notifier.value, isNull);

      notifier.dispose();
    });
  });
}
