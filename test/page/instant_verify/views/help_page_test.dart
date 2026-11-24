import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
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

  group('Help flows — kit components', () {
    const bridgeChoices = [
      'Enable bridge mode on the ISP gateway',
      'Switch Linksys to WiFi access point mode',
      'Leave it as two routers — contact my internet provider',
      'Leave as-is — internet is working fine',
    ];
    const placements = [
      ('Center of my home or close to it', 'Central placement can help'),
      ('Near a wall, door, or in a corner', 'Move your router toward the center'),
      ('Inside a closet, cabinet, or behind the TV',
          'Move your router out into the open'),
    ];

    void atWidth(WidgetTester tester, double width) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    /// A new page each time: re-pumping the same tree would keep its state.
    Future<void> openFresh(WidgetTester tester, int flow,
        [InstantVerifyPivotState? state]) async {
      await tester.pumpWidget(const SizedBox());
      await _open(tester, flow, state);
    }

    AppCard cardAround(WidgetTester tester, Finder text) => tester.widget<AppCard>(
        find.ancestor(of: text, matching: find.byType(AppCard)).first);

    testWidgets('step headings are titleSmall semantics headers',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 6);
      await _tap(tester, find.text(bridgeChoices.first));
      expect(tester.getSemantics(find.text('Enabling bridge mode'))
          .hasFlag(SemanticsFlag.isHeader), isTrue);
      await _open(tester, 4);
      expect(tester.getSemantics(find.text('Where is your router right now?'))
          .hasFlag(SemanticsFlag.isHeader), isTrue);
      handle.dispose();
    });

    testWidgets('two-router choices are borderless AppListCard rows',
        (tester) async {
      for (final width in [390.0, 800.0]) {
        atWidth(tester, width);
        await openFresh(tester, 6);
        expect(find.byType(ListTile), findsNothing);
        for (final label in bridgeChoices) {
          final row = find.ancestor(
              of: find.text(label), matching: find.byType(AppListCard));
          expect(row, findsOneWidget, reason: label);
          final card = tester.widget<AppListCard>(row);
          expect(card.showBorder, isFalse, reason: label);
          expect(card.leading, isA<Icon>(), reason: label);
          expect(card.onTap, isNotNull, reason: label);
        }
      }
    });

    testWidgets('every two-router branch fits at phone and tablet width',
        (tester) async {
      for (final width in [390.0, 800.0]) {
        atWidth(tester, width);
        for (final label in bridgeChoices) {
          await openFresh(tester, 6);
          await _tap(tester, find.text(label));
          expect(find.text('Two routers detected'), findsNothing,
              reason: '$label at $width');
        }
      }
    });

    testWidgets('a shared address offers only the provider choice',
        (tester) async {
      final cgnat = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {
          'wanStatus': 'Connected',
          'wanConnection': {'ipAddress': '100.64.1.1'},
        },
      );
      atWidth(tester, 390);
      await _open(tester, 6, cgnat);
      expect(find.byType(AppListCard), findsOneWidget);
      await _tap(tester,
          find.text('Contact my internet provider for a dedicated IP'));
      expect(find.text('Say to your provider:'), findsOneWidget);
    });

    testWidgets('coverage placements are labelled radios at both widths',
        (tester) async {
      final handle = tester.ensureSemantics();
      for (final width in [390.0, 800.0]) {
        atWidth(tester, width);
        await openFresh(tester, 4);
        for (final (label, advice) in placements) {
          final radio = tester.getSemantics(find.text(label));
          expect(radio.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup),
              isTrue, reason: label);
          expect(radio.label, contains(label));
          // Choose it as a screen reader (and the browser's radio) would.
          await tester.ensureVisible(find.text(label));
          tester.binding.pipelineOwner.semanticsOwner!
              .performAction(radio.id, SemanticsAction.tap);
          await tester.pumpAndSettle();
          expect(tester.getSemantics(find.text(label))
              .hasFlag(SemanticsFlag.isChecked), isTrue, reason: label);
          expect(find.textContaining(advice), findsOneWidget, reason: label);
        }
        await _tap(tester, find.text('More coverage tips'));
        expect(find.text('Need more coverage?'), findsOneWidget);
      }
      handle.dispose();
    });

    testWidgets('info, provider script and support are default kit cards',
        (tester) async {
      await _open(tester, 6);
      final info = cardAround(
          tester, find.textContaining('connected behind another router'));
      expect(info.borderColor, isNull);
      expect(info.color, isNull);
      expect(find.descendant(of: find.byWidget(info),
          matching: find.byIcon(LinksysIcons.infoCircle)), findsOneWidget);

      await _tap(tester, find.text(bridgeChoices[2]));
      final script = cardAround(tester, find.text('Say to your provider:'));
      expect(script.borderColor, isNull);
      expect(script.color, isNull);

      final support = cardAround(tester, find.text('Still need help?'));
      expect(support.borderColor, isNull);
      expect(support.color, isNull);
    });

    testWidgets('the AP-mode note is a setting card with a colored icon',
        (tester) async {
      await _open(tester, 6);
      await _tap(tester, find.text(bridgeChoices[1]));
      final note = find.ancestor(
          of: find.textContaining('In AP mode, features like'),
          matching: find.byType(AppSettingCard));
      expect(note, findsOneWidget);
      final card = tester.widget<AppSettingCard>(note);
      expect(card.borderColor, isNull, reason: 'advice, not a blocking warning');
      expect((card.leading as Icon).color, isNotNull);
    });

    testWidgets('the connection check fits at phone and tablet width',
        (tester) async {
      for (final width in [390.0, 800.0]) {
        atWidth(tester, width);
        await openFresh(tester, 1);
        await _tap(tester, find.text('View test details'));
        expect(find.text('This device reached your router'), findsOneWidget);
      }
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
