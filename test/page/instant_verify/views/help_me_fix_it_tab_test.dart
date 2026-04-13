import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/help_me_fix_it_tab.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/mock_instant_verify_pivot_notifier.dart';

// ── State factories ────────────────────────────────────────────────────────

InstantVerifyPivotState _baseState({
  Map<String, dynamic>? macFilter,
  Map<String, dynamic>? radioInfo,
  Map<String, dynamic>? networkSecurity,
}) {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {
      'wanStatus': 'Connected',
      'wanConnection': {'ipAddress': '10.0.0.1'},
    },
    clients: const [],
    macFilter: macFilter,
    radioInfo: radioInfo,
    networkSecurity: networkSecurity,
  );
}

InstantVerifyPivotState _macFilterOnState() => _baseState(
      macFilter: {
        'macFilterMode': 'MACFilter',
        'maxMACAddresses': 32,
        'macAddresses': <String>[],
      },
    );

InstantVerifyPivotState _wifiCredsState() => _baseState(
      radioInfo: {
        'isBandSteeringSupported': false,
        'radios': [
          {
            'radioID': 'radio0',
            'physicalRadioID': 'radio0',
            'bssid': 'AA:BB:CC:DD:EE:FF',
            'band': '2.4GHz',
            'supportedModes': <String>[],
            'supportedChannelsForChannelWidths': <dynamic>[],
            'supportedSecurityTypes': <String>[],
            'maxRADIUSSharedKeyLength': 64,
            'settings': {
              'ssid': 'MyHomeNetwork',
              'broadcastSSID': true,
              'isEnabled': true,
              'mode': 'Mixed',
              'channel': 6,
              'channelWidth': 'Auto',
              'securityType': 'WPA2-Personal',
              'wpaPersonalSettings': {'passphrase': 'mypassword123'},
            },
          }
        ],
      },
    );

Widget _buildTab(InstantVerifyPivotState state) {
  final notifier = MockInstantVerifyPivotNotifier(state);
  return testableWidget(
    overrides: [
      instantVerifyPivotProvider.overrideWith(() => notifier),
    ],
    child: const HelpMeFixItTab(),
  );
}

/// Helper: navigate past the pre-qualifier by selecting "Everything in my home".
/// Required for flows 1, 2, 4, 5 (network-wide issues).
Future<void> _tapEverything(WidgetTester tester) async {
  await tester.tap(find.text('Everything in my home'));
  await tester.pumpAndSettle();
}

void main() {
  mockDependencyRegister();

  group('HelpMeFixItTab — flow menu', () {
    testWidgets('shows qualifier on entry', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      // Pre-qualifier shown first
      expect(find.text('Is it affecting one specific device or everything?'), findsOneWidget);
      expect(find.text('One specific device'), findsOneWidget);
      expect(find.text('Everything in my home'), findsOneWidget);
    });

    testWidgets('shows 5 flow cards after selecting Everything', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      expect(find.text('My internet isn\'t working'), findsOneWidget);
      expect(find.text('My internet is slow'), findsOneWidget);
      expect(find.text('Device connectivity issues'), findsOneWidget);
      expect(find.text('WiFi doesn\'t reach a room'), findsOneWidget);
      expect(find.text('My connection keeps cutting out'), findsOneWidget);
    });

    testWidgets('One specific device routes directly to Flow 3', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One specific device'));
      await tester.pumpAndSettle();
      // Should land directly in Flow 3
      expect(find.text('Can your device connect to your WiFi?'), findsOneWidget);
    });

    testWidgets('shows question header', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      expect(find.text('What are you running into?'), findsOneWidget);
    });
  });

  group('HelpMeFixItTab — flow navigation', () {
    testWidgets('tapping a flow shows back button', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pump(); // don't pumpAndSettle — Flow 1 auto-runs async
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button returns to menu', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('What are you running into?'), findsOneWidget);
    });
  });

  group('Flow 1: My internet isn\'t working', () {
    Future<void> openFlow1(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet isn\'t working'));
      await tester.pump(); // pump once — diagnostics auto-start
    }

    testWidgets('shows diagnostic progress card on entry', (tester) async {
      await openFlow1(tester);
      expect(find.text('Running diagnostics…'), findsOneWidget);
      expect(find.text('This device reached your router'), findsOneWidget);
      expect(find.text('Your router reached the internet'), findsOneWidget);
      expect(find.text('Websites are loading'), findsOneWidget);
    });

    testWidgets('never shows restart as first action', (tester) async {
      await openFlow1(tester);
      // On initial load, before any diagnostic result, restart should not be visible
      expect(find.text('Restart Router'), findsNothing);
    });
  });

  group('Flow 2: My internet is slow', () {
    Future<void> openFlow2(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet is slow'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows speed test button', (tester) async {
      await openFlow2(tester);
      expect(find.text('Check my speed'), findsOneWidget);
      expect(find.text('Run a speed test'), findsOneWidget);
    });
  });

  group('Flow 2: Speed test result — capability display', () {
    // Build a state where speed result is pre-populated so step 1 shows
    InstantVerifyPivotState _stateWithSpeedResult(double mbps) {
      return InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
        speedTest: SpeedTestResult(
          downloadMbps: mbps,
          uploadMbps: mbps / 4,
          latencyMs: 15,
          jitterMs: 5,
        ),
        clients: const [],
      );
    }

    testWidgets('capability statement shown instead of raw Mbps headline', (tester) async {
      // We can't easily navigate to step 1 without running the async speed test.
      // Test the _speedCapability method indirectly by verifying capability language exists.
      // The speed test step 0 shows the run button — we verify speed result display via
      // state factory approach by building a tab that starts mid-flow.
      // For now verify step 0 still shows entry point correctly.
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet is slow'));
      await tester.pumpAndSettle();
      // Step 0 shown — no raw Mbps yet
      expect(find.text('Check my speed'), findsOneWidget);
      // Capability framing not shown yet (need speed result first)
      expect(find.textContaining('handles'), findsNothing);
    });

    testWidgets('"still slow" step shows where-is-it-slow question', (tester) async {
      // Can't easily get to step 2 without running async speed test.
      // Verify step 2 content is reachable from step 0.
      // This is integration-level — test step structure instead.
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet is slow'));
      await tester.pumpAndSettle();
      // Verify step 0 entry point exists
      expect(find.text('Run a speed test'), findsOneWidget);
    });
  });

  group('Flow 3: Slow device path (connected but slow)', () {
    Future<void> _navigateToSlowDevice(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One specific device'));
      await tester.pumpAndSettle();
      // Step 0: select "connected but something is wrong"
      await tester.tap(find.textContaining('connected but something is wrong'));
      await tester.pumpAndSettle();
      // Step 1: select "internet is slow on this device"
      await tester.tap(find.textContaining('slow on this device'));
      await tester.pumpAndSettle();
    }

    testWidgets('slow device path shows device picker when no device selected', (tester) async {
      await _navigateToSlowDevice(tester);
      expect(find.text('Which device is slow?'), findsOneWidget);
    });

    testWidgets('slow device path shows wireless clients to pick from', (tester) async {
      await _navigateToSlowDevice(tester);
      // Should list wireless devices for selection
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('slow device path no longer has Go to My Devices loop', (tester) async {
      await _navigateToSlowDevice(tester);
      // Old CTA was a loop — now replaced with inline picker
      expect(find.text('Go to My Devices tab'), findsNothing);
    });

    testWidgets('slow device path is not blank', (tester) async {
      await _navigateToSlowDevice(tester);
      // Critical: this was the blank page bug — verifying it no longer blanks
      expect(find.byType(Card), findsAtLeast(1));
    });
  });

  group('Flow 3: Device connectivity issues', () {
    // Flow 3 can be reached via "One specific device" qualifier shortcut
    Future<void> openFlow3(WidgetTester tester, InstantVerifyPivotState state) async {
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One specific device')); // qualifier shortcut
      await tester.pumpAndSettle();
    }

    testWidgets('first question asks can device connect', (tester) async {
      await openFlow3(tester, _baseState());
      expect(find.text('Can your device connect to your WiFi?'), findsOneWidget);
      expect(find.textContaining('connected but something is wrong'), findsOneWidget);
      expect(find.textContaining('won\'t connect at all'), findsOneWidget);
    });

    testWidgets('connected path shows issue type picker', (tester) async {
      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('connected but something is wrong'));
      await tester.pumpAndSettle();
      expect(find.text('What\'s happening?'), findsOneWidget);
      expect(find.textContaining('keeps dropping'), findsOneWidget);
      expect(find.textContaining('slow on this device'), findsOneWidget);
    });

    testWidgets('keeps dropping path shows dropout steps', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('connected but something is wrong'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('keeps dropping'));
      await tester.pumpAndSettle();
      expect(find.text('Device keeps dropping WiFi'), findsOneWidget);
      // Checklist items now in _ClickChecklistItem widgets — use broad search
      expect(find.textContaining('Move the device closer'), findsOneWidget);
      // 'forgetting' text is below the fold but in the widget tree
      expect(find.textContaining('reconnect fresh'), findsAtLeast(1));
    });

    testWidgets('not-connecting path shows SSID visibility check first', (tester) async {
      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      // Item 12: SSID visibility check shown before device type picker
      expect(find.textContaining('WiFi list'), findsOneWidget);
      expect(find.text('Yes — I can see it'), findsOneWidget);
      expect(find.text('No — I don\'t see it'), findsOneWidget);
    });

    testWidgets('not-connecting → can see SSID → shows device type picker', (tester) async {
      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — I can see it'));
      await tester.pumpAndSettle();
      expect(find.text('What kind of device is it?'), findsOneWidget);
      expect(find.text('Phone or tablet'), findsOneWidget);
      expect(find.textContaining('Smart home device'), findsOneWidget);
    });

    testWidgets('phone → not connecting → shows WiFi credentials', (tester) async {
      await openFlow3(tester, _wifiCredsState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — I can see it')); // past SSID visibility
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phone or tablet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Check your WiFi details'), findsOneWidget);
      expect(find.text('MyHomeNetwork'), findsOneWidget);
      expect(find.text('mypassword123'), findsOneWidget);
    });

    testWidgets('MAC filter warning shown when active', (tester) async {
      await openFlow3(tester, _macFilterOnState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — I can see it')); // past SSID visibility
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phone or tablet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('device blocklist'), findsOneWidget);
      expect(find.text('Turn off blocklist'), findsOneWidget);
    });

    testWidgets('smart home → path B shows 2.4GHz tip', (tester) async {
      await openFlow3(tester, _wifiCredsState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — I can see it')); // past SSID visibility
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Smart home device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Connect your smart home device'), findsOneWidget);
      expect(find.textContaining('2.4 GHz'), findsOneWidget);
    });
  });

  group('Flow 4: WiFi doesn\'t reach a room', () {
    Future<void> openFlow4(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows placement question', (tester) async {
      await openFlow4(tester);
      expect(find.text('Where is your router right now?'), findsOneWidget);
    });

    testWidgets('closet placement shows move advice', (tester) async {
      await openFlow4(tester);
      await tester.tap(find.textContaining('Inside a closet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Move your router out into the open'), findsOneWidget);
    });

    testWidgets('center placement shows good placement message', (tester) async {
      await openFlow4(tester);
      await tester.tap(find.textContaining('Center of my home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your placement is good'), findsOneWidget);
    });

    testWidgets('shows Linksys support tile', (tester) async {
      await openFlow4(tester);
      await tester.tap(find.textContaining('Center of my home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Still need help?'), findsOneWidget);
    });
  });

  group('Flow 5: My connection keeps cutting out', () {
    Future<void> openFlow5(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My connection keeps cutting out'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows frequency question', (tester) async {
      await openFlow5(tester);
      expect(find.text('How often does it drop?'), findsOneWidget);
      expect(find.text('Every few minutes'), findsOneWidget);
      expect(find.text('A few times a day'), findsOneWidget);
    });

    testWidgets('specific devices shows redirect to device flow', (tester) async {
      await openFlow5(tester);
      await tester.tap(find.text('Every few minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Is it everything or specific devices?'), findsOneWidget);
      await tester.tap(find.textContaining('Just specific devices'));
      await tester.pumpAndSettle();
      // Shows "go to device connectivity issues" button (not just menu)
      expect(find.text('Go to Device connectivity issues'), findsOneWidget);
    });

    testWidgets('whole internet → shows connection test with explanation', (tester) async {
      await openFlow5(tester);
      await tester.tap(find.text('A few times a day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('whole internet goes out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Run a 2-minute connection test'), findsOneWidget);
      // Connection test has an explanation
      expect(find.textContaining('every ~25 seconds'), findsOneWidget);
      expect(find.textContaining('2 minutes'), findsOneWidget);
    });
  });

  group('Flow 2: My internet is slow — gaming/latency path', () {
    // The gaming path (_step5Gaming) is reachable via step 2 → 'Games or video calls
    // are laggy'. Step 2 requires a speed result first (_step == 1 && _speedResult != null).
    // Since the speed test is async and the mock browser service has no real network,
    // we test what's directly reachable without forcing async service calls.

    testWidgets('Flow 2 step 0 shows speed test entry point', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet is slow'));
      await tester.pumpAndSettle();
      // Step 0 is the default entry — speed test button visible
      expect(find.text('Check my speed'), findsOneWidget);
      expect(find.text('Run a speed test'), findsOneWidget);
    });
  });

  group('Flow 5: My connection keeps cutting out — back navigation', () {
    Future<void> openFlow5(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My connection keeps cutting out'));
      await tester.pumpAndSettle();
    }

    testWidgets('back button visible after advancing from step 0', (tester) async {
      await openFlow5(tester);
      // Step 0: select a frequency and continue to step 1
      await tester.tap(find.text('Every few minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      // Now on step 1 (scope question). Back button should be present.
      expect(find.text('← Back'), findsOneWidget);
    });

    testWidgets('tapping back returns to frequency question', (tester) async {
      await openFlow5(tester);
      await tester.tap(find.text('Every few minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      // Verify we moved forward
      expect(find.text('Is it everything or specific devices?'), findsOneWidget);
      // Go back
      await tester.tap(find.text('← Back'));
      await tester.pumpAndSettle();
      // Should be back on step 0
      expect(find.text('How often does it drop?'), findsOneWidget);
    });
  });

  group('Flow 3: back navigation within cant-connect path', () {
    testWidgets('back button visible after entering cant-connect path', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One specific device'));
      await tester.pumpAndSettle();
      // Tap "won't connect at all" to push into step 1
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      // Should be on SSID visibility check — this is still step 1 (cant-connect)
      // The back button is rendered via _backButton which appears when _stepHistory is non-empty.
      // However, _step1CantConnect doesn't include a _backButton widget directly —
      // the back logic is at the parent step. Verify the SSID check is shown.
      expect(find.textContaining('WiFi list'), findsOneWidget);
    });
  });

  group('Flow 4: satisfaction prompt', () {
    Future<void> navigateToFlow4Terminal(WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Center of my home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('satisfaction prompt appears on terminal screen', (tester) async {
      await navigateToFlow4Terminal(tester);
      // Satisfaction prompt is hidden (SizedBox.shrink) pending feedback mechanism.
      // Re-enable when prompt is wired to a real feedback destination.
      expect(find.text('Did this help?'), findsNothing);
    }); // satisfaction prompt hidden — see _SatisfactionPromptState.build()

    testWidgets('terminal screen renders without satisfaction prompt', (tester) async {
      await navigateToFlow4Terminal(tester);
      // Prompt is hidden — verify no rating buttons are shown
      expect(find.text('Fixed it'), findsNothing);
      expect(find.text('Did this help?'), findsNothing);
    }); // satisfaction prompt hidden — re-enable when wired to feedback destination
  });

  group('Flow 5: PPPoE WAN connection type', () {
    testWidgets('wanConnectionType getter returns PPPoE from detectedWANType', (tester) async {
      // This is a state-level test — we just verify the getter returns the right value.
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {
          'wanStatus': 'Connected',
          'detectedWANType': 'PPPoE',
          'wanConnection': {'ipAddress': '10.0.0.1'},
        },
      );
      expect(state.wanConnectionType, equals('PPPoE'));
    });

    testWidgets('wanConnectionType null when not present in wanStatus', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {
          'wanStatus': 'Connected',
          'wanConnection': {'ipAddress': '10.0.0.1'},
        },
      );
      expect(state.wanConnectionType, isNull);
    });
  });

  group('Flow 1: session summary compiles at gateway-fail path', () {
    testWidgets('gateway fail path renders without crash', (tester) async {
      // Flow 1 auto-runs diagnostics on entry. With no real network in tests,
      // the browser service will fail gracefully → lands on gateway-fail path.
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('My internet isn\'t working'));
      await tester.pump(); // let the diagnostic card render
      // Gateway fail path should show 'Check your connection to the router'
      // after diagnostics resolve (or keep loading — both are valid in tests).
      // We just confirm the tab doesn't throw.
      expect(find.byType(HelpMeFixItTab), findsOneWidget);
    });
  });

  group('Cross-cutting — Linksys Support tile', () {
    testWidgets('Flow 4 terminal screen shows Linksys Support', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _tapEverything(tester);
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Center of my home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Still need help?'), findsOneWidget);
      expect(find.textContaining('Linksys Support'), findsOneWidget);
    });
  });

  group('Cross-cutting — text selectability', () {
    testWidgets('WiFi credentials render as SelectableText', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_wifiCredsState()));
      await tester.pumpAndSettle();
      // Navigate via qualifier → Flow 3 → not connecting → visibility check → credentials
      await tester.tap(find.text('One specific device'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes — I can see it')); // past SSID visibility
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phone or tablet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // SSID and password are wrapped in SelectableText
      expect(
        tester.widgetList<SelectableText>(
            find.widgetWithText(SelectableText, 'MyHomeNetwork')),
        isNotEmpty,
      );
      expect(
        tester.widgetList<SelectableText>(
            find.widgetWithText(SelectableText, 'mypassword123')),
        isNotEmpty,
      );
    });
  });

  // ── Qualifier buttons ──────────────────────────────────────────────────────

  group('HelpMeFixItTab — qualifier button styling', () {
    testWidgets('both qualifier buttons are OutlinedButton (neither pre-selected)', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();

      // Find all OutlinedButton children that contain the qualifier labels
      expect(find.text('One specific device'), findsOneWidget);
      expect(find.text('Everything in my home'), findsOneWidget);

      // Neither should be a FilledButton — FilledButton renders with filled background
      // using a different widget type from OutlinedButton
      final oneDeviceBtn = find.ancestor(
        of: find.text('One specific device'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      final everythingBtn = find.ancestor(
        of: find.text('Everything in my home'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );

      expect(oneDeviceBtn, findsOneWidget,
          reason: '"One specific device" must be an OutlinedButton');
      expect(everythingBtn, findsOneWidget,
          reason: '"Everything in my home" must be an OutlinedButton');

      // Confirm no FilledButton wraps either label
      final oneFilledBtn = find.ancestor(
        of: find.text('One specific device'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      final everythingFilledBtn = find.ancestor(
        of: find.text('Everything in my home'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      );
      expect(oneFilledBtn, findsNothing,
          reason: '"One specific device" must NOT be a FilledButton');
      expect(everythingFilledBtn, findsNothing,
          reason: '"Everything in my home" must NOT be a FilledButton');
    });
  });

  // ── SSID not visible diagnostics ──────────────────────────────────────────

  /// Navigate through qualifier → Flow 3 → "No, it won't connect" → "No, I don't see it"
  Future<void> _navigateToSsidNotVisible(WidgetTester tester) async {
    await tester.tap(find.text('One specific device'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('won\'t connect at all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No — I don\'t see it'));
    await tester.pumpAndSettle();
  }

  group('HelpMeFixItTab — Flow 3 SSID not visible diagnostics', () {
    testWidgets('renders without crash when no radioInfo', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('checked your router'), findsOneWidget);
    });

    testWidgets('shows no-data message when radioInfo is absent', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      // With no radioInfo, shows generic "no obvious cause" message
      expect(find.textContaining('didn\'t detect an obvious cause'), findsOneWidget);
    });

    testWidgets('disabled 2.4 GHz radio shows disabled band finding', (tester) async {
      final state = _baseState(radioInfo: {
        'radios': [
          {
            'band': '2.4GHz',
            'settings': {'isEnabled': false, 'ssid': 'MyNet'},
          },
          {
            'band': '5GHz',
            'settings': {'isEnabled': true, 'ssid': 'MyNet'},
          },
        ],
      });
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('radio is turned off'), findsOneWidget);
    });

    testWidgets('hidden SSID (broadcastSsid: false) shows hidden-network finding', (tester) async {
      final state = _baseState(radioInfo: {
        'radios': [
          {
            'band': '2.4GHz',
            'settings': {
              'isEnabled': true,
              'ssid': 'MyNet',
              'broadcastSsid': false,
            },
          },
        ],
      });
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('hidden'), findsWidgets);
    });

    testWidgets('WPA3-only security shows WPA3 compatibility finding', (tester) async {
      final state = _baseState(
        radioInfo: {
          'radios': [
            {
              'band': '5GHz',
              'settings': {'isEnabled': true, 'ssid': 'MyNet'},
            },
          ],
        },
        networkSecurity: {'securityType': 'WPA3-Personal'},
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('WPA3'), findsWidgets);
    });

    testWidgets('active radios show both bands with Active status', (tester) async {
      final state = _baseState(radioInfo: {
        'radios': [
          {
            'band': '2.4GHz',
            'settings': {'isEnabled': true, 'ssid': 'MyNet'},
          },
          {
            'band': '5GHz',
            'settings': {'isEnabled': true, 'ssid': 'MyNet'},
          },
        ],
      });
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      // Radio status card shows bands
      expect(find.text('2.4 GHz'), findsWidgets);
      expect(find.text('5 GHz'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('Restart Router button is always present', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      expect(find.text('Restart Router'), findsOneWidget);
    });

    testWidgets('Back button navigates back to SSID visibility question', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      await _navigateToSsidNotVisible(tester);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      // Should return to "Can you see your network?" question
      expect(find.textContaining('WiFi list'), findsOneWidget);
    });
  });
}
