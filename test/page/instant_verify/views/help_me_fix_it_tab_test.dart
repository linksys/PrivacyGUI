import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
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

void main() {
  mockDependencyRegister();

  group('HelpMeFixItTab — flow menu', () {
    testWidgets('shows 5 flow cards', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
      expect(find.text('My internet isn\'t working'), findsOneWidget);
      expect(find.text('My internet is slow'), findsOneWidget);
      expect(find.text('Device connectivity issues'), findsOneWidget);
      expect(find.text('WiFi doesn\'t reach a room'), findsOneWidget);
      expect(find.text('My connection keeps cutting out'), findsOneWidget);
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
      await tester.tap(find.text('WiFi doesn\'t reach a room'));
      await tester.pump(); // don't pumpAndSettle — Flow 1 auto-runs async
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button returns to menu', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('My internet isn\'t working'));
      await tester.pump(); // pump once — diagnostics auto-start
    }

    testWidgets('shows diagnostic progress card on entry', (tester) async {
      await openFlow1(tester);
      expect(find.text('Running diagnostics…'), findsOneWidget);
      expect(find.text('Your device → Router'), findsOneWidget);
      expect(find.text('Router → Internet'), findsOneWidget);
      expect(find.text('DNS (website names)'), findsOneWidget);
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
      await tester.tap(find.text('My internet is slow'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows speed test button', (tester) async {
      await openFlow2(tester);
      expect(find.text('Check my speed'), findsOneWidget);
      expect(find.text('Run a speed test'), findsOneWidget);
    });
  });

  group('Flow 3: Device connectivity issues', () {
    Future<void> openFlow3(WidgetTester tester, InstantVerifyPivotState state) async {
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Device connectivity issues'));
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
      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('connected but something is wrong'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('keeps dropping'));
      await tester.pumpAndSettle();
      expect(find.text('Device keeps dropping WiFi'), findsOneWidget);
      expect(find.textContaining('Move the device closer'), findsOneWidget);
      expect(find.textContaining('forgetting your WiFi'), findsOneWidget);
    });

    testWidgets('not-connecting path shows device type picker', (tester) async {
      await openFlow3(tester, _baseState());
      await tester.tap(find.textContaining('won\'t connect at all'));
      await tester.pumpAndSettle();
      expect(find.text('What kind of device is it?'), findsOneWidget);
      expect(find.text('Phone or tablet'), findsOneWidget);
      expect(find.textContaining('Smart home device'), findsOneWidget);
    });

    testWidgets('phone → not connecting → shows WiFi credentials', (tester) async {
      await openFlow3(tester, _wifiCredsState());
      await tester.tap(find.textContaining('won\'t connect at all'));
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

  group('Cross-cutting — Linksys Support tile', () {
    testWidgets('Flow 4 terminal screen shows Linksys Support', (tester) async {
      await tester.pumpWidget(_buildTab(_baseState()));
      await tester.pumpAndSettle();
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
      // Navigate to credentials via not-connecting path
      await tester.tap(find.text('Device connectivity issues'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('won\'t connect at all'));
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
}
