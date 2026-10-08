import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/help/help_page.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/mock_instant_verify_pivot_notifier.dart';

// Flow bodies on their help page (route instantTestHelp, one flow per page).
// Navigation between pages is covered by single_page_test.dart and
// instant_test_route_test.dart.

// ── State factories ────────────────────────────────────────────────────────

const _phone = DiagnosticClient(
  macAddress: 'AA:BB:CC:00:00:01',
  hostname: 'Phone',
  band: '5 GHz',
  isWireless: true,
  signalDecibels: -60,
);

InstantVerifyPivotState _baseState({
  Map<String, dynamic>? macFilter,
  Map<String, dynamic>? radioInfo,
  Map<String, dynamic>? networkSecurity,
  List<DiagnosticClient> clients = const [],
}) {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {
      'wanStatus': 'Connected',
      'wanConnection': {'ipAddress': '10.0.0.1'},
    },
    clients: clients,
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

Widget _buildFlow(InstantVerifyPivotState state, int flow) {
  final notifier = MockInstantVerifyPivotNotifier(state);
  return testableWidget(
    overrides: [
      instantVerifyPivotProvider.overrideWith(() => notifier),
    ],
    child: InstantTestHelpView(flow: flow),
  );
}

Future<void> _open(WidgetTester tester, int flow,
    [InstantVerifyPivotState? state]) async {
  await tester.pumpWidget(_buildFlow(state ?? _baseState(), flow));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

/// Flow 3: device not in the list → cannot-connect path (SSID question).
Future<void> _openCantConnect(WidgetTester tester,
    [InstantVerifyPivotState? state]) async {
  await _open(tester, 3, state);
  await _tap(tester, find.text("I don't see my device"));
}

/// ... → "No, I don't see it" (SSID not visible diagnostics).
Future<void> _navigateToSsidNotVisible(WidgetTester tester,
    [InstantVerifyPivotState? state]) async {
  await _openCantConnect(tester, state);
  await _tap(tester, find.text('No — I don\'t see it'));
}

void main() {
  mockDependencyRegister();

  group('Help page frame', () {
    testWidgets('each flow page carries its title', (tester) async {
      // Desktop width: Flow 6's ListTile options under-report their
      // intrinsic height when titles wrap (see single_page_test.dart).
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final flow in InstantTestHelpView.flows) {
        await tester.pumpWidget(_buildFlow(_baseState(), flow));
        await tester.pump();
        expect(find.text(InstantTestHelpView.title(flow)), findsOneWidget,
            reason: 'flow $flow');
      }
    });
  });

  group('Flow 1: My internet isn\'t working', () {
    Future<void> openFlow1(WidgetTester tester) async {
      await tester.pumpWidget(_buildFlow(_baseState(), 1));
      await tester.pump(); // pump once — diagnostics auto-start
    }

    testWidgets('shows diagnostic progress card on entry', (tester) async {
      await openFlow1(tester);
      expect(find.text('Running diagnostics…'), findsOneWidget);
      await tester.tap(find.text('View test details'));
      await tester.pump();
      expect(find.text('This device reached your router'), findsOneWidget);
      expect(find.text('Your router reached the internet'), findsOneWidget);
      expect(find.textContaining('Websites are loading'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('never shows restart as first action', (tester) async {
      await openFlow1(tester);
      // On initial load, before any diagnostic result, restart should not be visible
      expect(find.text('Restart Router'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('gateway fail path renders without crash', (tester) async {
      await openFlow1(tester);
      expect(find.byType(InstantTestHelpView), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Flow 2: My internet is slow', () {
    testWidgets('shows speed test entry point', (tester) async {
      await _open(tester, 2);
      expect(find.text('Check my speed'), findsOneWidget);
      expect(find.text('Run a speed test'), findsOneWidget);
      // Capability framing not shown yet (need speed result first)
      expect(find.textContaining('handles'), findsNothing);
    });
  });

  group('Flow 3: Slow device path (connected but slow)', () {
    testWidgets('slow device path shows the device picker', (tester) async {
      await _open(tester, 31, _baseState(clients: const [_phone]));
      expect(find.text('Which device needs help?'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('slow device path no longer has Go to My Devices loop',
        (tester) async {
      await _open(tester, 31, _baseState(clients: const [_phone]));
      expect(find.text('Go to My Devices tab'), findsNothing);
    });
  });

  group('Flow 3: Device connectivity issues', () {
    testWidgets('keeps dropping path shows dropout steps', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _open(tester, 32, _baseState(clients: const [_phone]));
      await _tap(tester, find.text('Phone'));
      expect(find.text('Device keeps dropping WiFi'), findsOneWidget);
      expect(find.textContaining('Move the device closer'), findsOneWidget);
      await _tap(tester, find.text('Try the next step'));
      expect(find.textContaining('reconnect fresh'), findsAtLeast(1));
    });

    testWidgets('not-connecting path shows SSID visibility check first',
        (tester) async {
      await _openCantConnect(tester);
      expect(find.textContaining('WiFi list'), findsOneWidget);
      expect(find.text('Yes — I can see it'), findsOneWidget);
      expect(find.text('No — I don\'t see it'), findsOneWidget);
    });

    testWidgets('can see SSID goes straight to WiFi credentials',
        (tester) async {
      await _openCantConnect(tester, _wifiCredsState());
      await _tap(tester, find.text('Yes — I can see it'));
      expect(find.text('Check your WiFi details'), findsOneWidget);
      expect(find.text('MyHomeNetwork'), findsOneWidget);
      expect(find.text('mypassword123'), findsOneWidget);
    });

    testWidgets('MAC filter warning shown when active', (tester) async {
      await _openCantConnect(tester, _macFilterOnState());
      await _tap(tester, find.text('Yes — I can see it'));
      expect(find.textContaining('device blocklist'), findsOneWidget);
      expect(find.text('Turn off blocklist'), findsOneWidget);
    });

    testWidgets('2.4GHz tip shown in unified path for all device types',
        (tester) async {
      await _openCantConnect(tester, _wifiCredsState());
      await _tap(tester, find.text('Yes — I can see it'));
      for (var i = 0; i < 3; i++) {
        await _tap(tester, find.text('Try the next step'));
      }
      expect(find.textContaining('2.4 GHz'), findsWidgets);
    });
  });

  group('Flow 4: WiFi doesn\'t reach a room', () {
    testWidgets('shows placement question', (tester) async {
      await _open(tester, 4);
      expect(find.text('Where is your router right now?'), findsOneWidget);
    });

    testWidgets('closet placement shows move advice', (tester) async {
      await _open(tester, 4);
      await _tap(tester, find.textContaining('Inside a closet'));
      expect(find.textContaining('Move your router out into the open'),
          findsOneWidget);
    });

    testWidgets('center placement shows good placement message',
        (tester) async {
      await _open(tester, 4);
      await _tap(tester, find.textContaining('Center of my home'));
      expect(find.textContaining('Central placement can help'), findsOneWidget);
    });

    testWidgets('terminal screen renders without satisfaction prompt',
        (tester) async {
      await _open(tester, 4);
      await _tap(tester, find.textContaining('Center of my home'));
      // Prompt is hidden pending a feedback destination.
      expect(find.text('Fixed it'), findsNothing);
      expect(find.text('Did this help?'), findsNothing);
    });
  });

  group('Flow 5: My connection keeps cutting out', () {
    testWidgets('shows frequency question', (tester) async {
      await _open(tester, 5);
      expect(find.text('How often does it drop?'), findsOneWidget);
      expect(find.text('Every few minutes'), findsOneWidget);
      expect(find.text('A few times a day'), findsOneWidget);
    });

    testWidgets('specific devices offers the device flow', (tester) async {
      await _open(tester, 5);
      await _tap(tester, find.text('Every few minutes'));
      await _tap(tester, find.text('Specific devices'));
      expect(find.text('Choose the affected device'), findsOneWidget);
    });

    testWidgets('whole internet → shows connection test with explanation',
        (tester) async {
      await _open(tester, 5);
      await _tap(tester, find.text('A few times a day'));
      await _tap(tester, find.text('All devices'));
      expect(find.text('Run a 2-minute connection test'), findsOneWidget);
      expect(find.textContaining('every 24 seconds'), findsOneWidget);
      expect(find.textContaining('two minutes'), findsWidgets);
    });
  });

  group('Flow 5: PPPoE WAN connection type', () {
    testWidgets('wanConnectionType getter returns PPPoE from detectedWANType',
        (tester) async {
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

    testWidgets('wanConnectionType null when not present in wanStatus',
        (tester) async {
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

  group('Cross-cutting — Linksys Support tile', () {
    testWidgets('help page shows Linksys Support', (tester) async {
      await _open(tester, 4);
      await _tap(tester, find.textContaining('Center of my home'));
      expect(find.text('Still need help?'), findsOneWidget);
      expect(find.textContaining('Linksys Support'), findsOneWidget);
    });
  });

  group('Cross-cutting — text selectability', () {
    testWidgets('WiFi credentials render as SelectableText', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());
      await _openCantConnect(tester, _wifiCredsState());
      await _tap(tester, find.text('Yes — I can see it'));
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

  // ── SSID not visible diagnostics ──────────────────────────────────────────

  group('Flow 3 SSID not visible diagnostics', () {
    testWidgets('renders without crash when no radioInfo', (tester) async {
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('checked your router'), findsOneWidget);
    });

    testWidgets('shows no-data message when radioInfo is absent',
        (tester) async {
      await _navigateToSsidNotVisible(tester);
      expect(find.textContaining('didn\'t detect an obvious cause'),
          findsOneWidget);
    });

    testWidgets('disabled 2.4 GHz radio shows disabled band finding',
        (tester) async {
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
      await _navigateToSsidNotVisible(tester, state);
      expect(find.textContaining('radio is turned off'), findsOneWidget);
    });

    testWidgets('hidden SSID (broadcastSsid: false) shows hidden-network finding',
        (tester) async {
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
      await _navigateToSsidNotVisible(tester, state);
      expect(find.textContaining('hidden'), findsWidgets);
    });

    testWidgets('WPA3-only security shows WPA3 compatibility finding',
        (tester) async {
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
      await _navigateToSsidNotVisible(tester, state);
      expect(find.textContaining('WPA3'), findsWidgets);
    });

    testWidgets('active radios show both bands with Active status',
        (tester) async {
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
      await _navigateToSsidNotVisible(tester, state);
      await _tap(tester, find.text('WiFi radio details'));
      expect(find.text('2.4 GHz'), findsWidgets);
      expect(find.text('5 GHz'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('Restart Router button is always present', (tester) async {
      await _navigateToSsidNotVisible(tester);
      expect(find.text('Restart Router'), findsOneWidget);
    });

    testWidgets('Back button navigates back to SSID visibility question',
        (tester) async {
      await _navigateToSsidNotVisible(tester);
      await _tap(tester, find.text('Back'));
      expect(find.textContaining('WiFi list'), findsOneWidget);
    });
  });
}
