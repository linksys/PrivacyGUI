import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/route/constants.dart';
import 'dart:ui' show PointerDeviceKind, SemanticsFlag;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/answer_row.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_menu_view.dart'
    show AppMenuCard;

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../common/testable_widget.dart';
import 'instant_test_harness.dart';

const printer = DiagnosticClient(
    macAddress: 'AA:BB:CC:DD:EE:01',
    hostname: 'Office printer',
    band: '2.4 GHz',
    isWireless: true,
    signalDecibels: -80,
    txRateMbps: 20);

class FixtureNotifier extends InstantVerifyPivotNotifier {
  FixtureNotifier({this.clients = const [printer], this.meshNodes, this.dnsCheck, this.rejectRestart = false, this.rejectReconnect = false});
  final bool rejectRestart;
  final bool rejectReconnect;
  final DnsCheckResult? dnsCheck;
  final List<MeshNodeInfo>? meshNodes;
  final List<DiagnosticClient> clients;
  @override
  InstantVerifyPivotState build() => InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        dnsCheck: dnsCheck,
        clients: clients,
        deviceScores: clients.map(DeviceScore.compute).toList(),
        meshNodes: meshNodes ??
            const [
              MeshNodeInfo(
                  deviceId: 'node',
                  name: 'Bedroom',
                  isController: false,
                  backhaulType: 'Wireless',
                  backhaulRssi: -80)
            ],
      );
  @override
  Future<void> deauthClient(String macAddress) async {
    if (rejectReconnect) throw StateError('reconnect rejected');
  }

  int fetchCount = 0;
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {
    fetchCount++;
  }

  void loseClientList() => state = state.copyWith(clients: []);

  @override
  Future<void> restartRouter() async {
    if (rejectRestart) throw StateError('restart rejected');
    state = state.copyWith(hasRestartedThisSession: true);
  }
}

class ProbeService extends MockBrowserDiagnosticService {
  int calls = 0;
  Completer<GatewayPingResult>? pending;
  bool fail = false;
  bool speedFail = false;
  bool speedFailAfterFirst = false;
  int speedCalls = 0;
  bool gatewayUnavailable = false;
  bool internetUnavailable = false;
  bool dnsUnavailable = false;
  Completer<SpeedTestResult>? pendingSpeed;
  @override
  Future<SpeedTestResult> runInternetSpeedTest(
      {void Function(String)? onStep}) async {
    speedCalls++;
    if (speedFail || (speedFailAfterFirst && speedCalls > 1)) throw StateError('speed unavailable');
    return pendingSpeed == null
        ? super.runInternetSpeedTest()
        : pendingSpeed!.future;
  }

  @override
  Future<GatewayPingResult> pingGateway() async {
    calls++;
    if (gatewayUnavailable) return const GatewayPingResult(reachable: false);
    if (fail) throw StateError('test probe unavailable');
    return pending == null ? super.pingGateway() : pending!.future;
  }

  @override
  Future<GatewayPingResult> pingPublicIp() async => internetUnavailable
      ? const GatewayPingResult(reachable: false) : await super.pingPublicIp();

  @override
  Future<DnsCheckResult> checkDns() async => dnsUnavailable
      ? const DnsCheckResult(resolved: false) : await super.checkDns();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Whether the kit radio (AppRadioList) labelled [label] is selected.
bool radioSelected(WidgetTester tester, String label) {
  final item = find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
  final radio = tester.widget<Radio>(find.descendant(
      of: item, matching: find.byWidgetPredicate((w) => w is Radio)));
  return radio.value == radio.groupValue;
}

/// The collapsed answer shown for an answered workflow question.
String answer(WidgetTester tester, String label) => tester
    .widget<AnswerRow>(
        find.byWidgetPredicate((w) => w is AnswerRow && w.label == label))
    .value;

void main() {
  mockDependencyRegister();

  /// Opens Instant-Test through its routes ([location] defaults to home).
  Future<GoRouter> mount(WidgetTester tester,
      {FixtureNotifier? notifier,
      BrowserDiagnosticService? service,
      InstantVerifyPivotNotifier Function()? pivot,
      String location = instantTestHome}) async {
    final router = instantTestRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(testableRouter(router: router, overrides: [
      instantVerifyPivotProvider
          .overrideWith(pivot ?? () => notifier ?? FixtureNotifier()),
      browserDiagnosticServiceProvider
          .overrideWithValue(service ?? MockBrowserDiagnosticService()),
    ]));
    await tester.pumpAndSettle();
    return router;
  }

  /// One Instant-Test page widget on its own, without routes.
  Future<void> mountPage(WidgetTester tester, Widget page,
      {FixtureNotifier? notifier}) async {
    await tester.pumpWidget(testableWidget(overrides: [
      instantVerifyPivotProvider
          .overrideWith(() => notifier ?? FixtureNotifier()),
      browserDiagnosticServiceProvider
          .overrideWithValue(MockBrowserDiagnosticService()),
    ], child: page));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'home keeps the result and action visible while preserving measured details',
      (tester) async {
    await mount(tester, pivot: MockInstantVerifyPivotNotifier.new);
    expect(find.text('Your router is very busy'), findsOneWidget);
    expect(find.textContaining('88% CPU'), findsOneWidget);
    expect(find.text('Restart Router'), findsOneWidget);
    expect(find.text('Why this matters'), findsNothing);
    // Other findings, weak devices and weak WiFi nodes share one list.
    expect(find.text('Devices that may need help'), findsNothing);
    expect(find.textContaining('Mesh Network'), findsNothing);
    await tapText(tester,
        tester.widget<Text>(find.textContaining('more things we found')).data!);
    expect(find.text('Restart Router'), findsWidgets);
  });

  testWidgets('the result and every problem choice fit on one desktop screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, pivot: MockInstantVerifyPivotNotifier.new);
    for (final label in [
      'Your router is very busy',
      'Restart Router',
      "Internet isn't working",
      "Doesn't reach a room",
    ]) {
      expect(tester.getRect(find.text(label)).bottom, lessThan(800),
          reason: '$label should be visible without scrolling');
    }
  });

  testWidgets('problem choices sit three to a row and follow resizing',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2048, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    final first = find.widgetWithText(AppMenuCard, "Internet isn't working");
    final last = find.widgetWithText(AppMenuCard, 'Keeps cutting out');
    // Three choices per row, like the Menu page.
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(last).dy);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(first).dx, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('open diagnostic details survive page resizing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2048, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    await tapText(tester, 'View test details');
    // From 360: the shared TopBar itself overflows below that width.
    for (final width in [360.0, 600.0, 905.0, 1240.0, 2048.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpAndSettle();
      expect(find.text('This device reached your router'), findsOneWidget);
      expect(find.text('Hide test details'), findsOneWidget);
      final result = tester.getRect(find.text('Your router can reach the internet'));
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('workflow result and its next step share one card', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    final result = tester.getRect(find.text('Your router can reach the internet'));
    final guidance =
        tester.getRect(find.textContaining('The connection looks healthy'));
    expect(guidance.top, greaterThan(result.bottom));
    // The result and its next step share one card.
    final card = find.ancestor(
        of: find.text('Your router can reach the internet'),
        matching: find.byType(AppCard));
    expect(
        find.descendant(
            of: card.first,
            matching: find.textContaining('The connection looks healthy')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('healthy follow-up groups context with compact controls at every width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2048, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    expect(find.textContaining('Everything looks fine right now'), findsNothing);
    expect(find.textContaining('The connection looks healthy'), findsOneWidget);
    for (final width in [2048.0, 390.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpAndSettle();
      final action = find.ancestor(
          of: find.text('Yes — troubleshoot a specific device'),
          matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton)).first;
      final labelWidth = tester.getSize(find.text('Yes — troubleshoot a specific device')).width;
      expect(tester.getSize(action).width, lessThanOrEqualTo(labelWidth + 100));
      expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    }
    await tapText(tester, 'Yes — troubleshoot a specific device');
    expect(find.text('Which device needs help?'), findsOneWidget);
  });

  testWidgets('test details are optional and can be closed again',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    expect(find.text('Your router can reach the internet'), findsOneWidget);
    expect(find.text('This device reached your router'), findsNothing);
    await tapText(tester, 'View test details');
    expect(find.text('This device reached your router'), findsOneWidget);
    await tapText(tester, 'Hide test details');
    expect(find.text('This device reached your router'), findsNothing);
    expect(find.text('Your router can reach the internet'), findsOneWidget);
  });

  testWidgets(
      'device advice stays visible while telemetry and picker are collapsed',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'One device is slow');
    await tapText(tester, 'Office printer');
    expect(find.text('Very weak WiFi signal'), findsOneWidget);
    expect(find.text('Try this first'), findsOneWidget);
    expect(find.text('Band'), findsNothing);
    expect(find.text('Link rate'), findsNothing);
    expect(find.byKey(const ValueKey('device-choice-AA:BB:CC:DD:EE:01')),
        findsNothing);
    await tapText(tester, 'Connection details');
    expect(find.text('Band'), findsOneWidget);
    expect(find.text('Link rate'), findsOneWidget);
    await tapText(tester, 'Hide connection details');
    expect(find.text('Band'), findsNothing);
    await tapText(tester, 'Change device');
    expect(find.byKey(const ValueKey('device-choice-AA:BB:CC:DD:EE:01')),
        findsOneWidget);
  });

  testWidgets(
      'compact signal summary matches details and keeps missing data unknown',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final signal in [-75, null]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester,
          notifier: FixtureNotifier(clients: [
            DiagnosticClient(
              macAddress: 'AA:BB:CC:DD:EE:02',
              hostname: 'Laptop',
              band: '5 GHz',
              isWireless: true,
              signalDecibels: signal,
            )
          ]));
      await tapText(tester, 'One device is slow');
      await tapText(tester, 'Laptop');
      expect(
          find.text(signal == null
              ? 'Signal information is unavailable.'
              : 'Weak WiFi signal'),
          findsOneWidget);
      await tapText(tester, 'Connection details');
      if (signal != null) expect(find.text('Weak (-75 dBm)'), findsOneWidget);
      expect(find.text('Good WiFi signal'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'manual steps reveal one instruction at a time and support going back',
      (tester) async {
    final notifier = FixtureNotifier();
    await mount(tester, notifier: notifier);
    final initialFetches = notifier.fetchCount;
    await tapText(tester, "Device won't connect");
    await tapText(tester, 'My device uses an Ethernet cable');
    expect(
        find.text('Check the Ethernet cable is firmly plugged in at both ends'),
        findsOneWidget);
    expect(
        find.text('Try a different Ethernet port on the router'), findsNothing);
    await tapText(tester, 'Try the next step');
    expect(find.text('Try a different Ethernet port on the router'),
        findsOneWidget);
    expect(
        find.text('Check the Ethernet cable is firmly plugged in at both ends'),
        findsNothing);
    await tapText(tester, 'Previous step');
    expect(
        find.text('Check the Ethernet cable is firmly plugged in at both ends'),
        findsOneWidget);
    expect(notifier.fetchCount, initialFetches);
    await tapText(tester, 'Restart Router');
    expect(find.text('Restart your router?'), findsOneWidget);
    expect(find.textContaining('disconnect'), findsWidgets);
    await tapText(tester, 'Cancel');
  });

  testWidgets('speed capability stays visible while measurements are optional',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'Whole internet is slow');
    await tapText(tester, 'Check my speed');
    expect(find.textContaining('Mbps down'), findsNothing);
    expect(find.text('Just one specific device'), findsOneWidget);
    await tapText(tester, 'View speed test details');
    expect(find.textContaining('Mbps down'), findsOneWidget);
    await tapText(tester, 'Hide speed test details');
    expect(find.textContaining('Mbps down'), findsNothing);
  });

  testWidgets(
      'weak WiFi finding opens connection analysis, not cannot-connect advice',
      (tester) async {
    await mount(tester);
    // Weak devices are listed by name with what else we found.
    if (find.text('Help Office printer').evaluate().isEmpty) {
      await tapText(tester,
          (tester.widget<Text>(find.textContaining(' we found').last)).data!);
    }
    await tapText(tester, 'Help Office printer');
    expect(answer(tester, 'Device'), 'Office printer');
    expect(answer(tester, 'Problem'), 'Slow connection');
    expect(find.text('Yes — I can see it'), findsNothing);
  });

  testWidgets('network detail health includes link speed and unknown telemetry',
      (tester) async {
    await mountPage(tester, const MyNetworkTab(),
        notifier: FixtureNotifier(meshNodes: const [
          MeshNodeInfo(deviceId: 'parent', name: 'Main', isController: true),
          MeshNodeInfo(
              deviceId: 'weak',
              name: 'Bedroom',
              isController: false,
              backhaulType: 'Wireless',
              backhaulRssi: -52,
              backhaulSpeedMbps: 45),
          MeshNodeInfo(
              deviceId: 'moderate',
              name: 'Hall',
              isController: false,
              backhaulType: 'Wireless',
              backhaulSpeedMbps: 100),
          MeshNodeInfo(
              deviceId: 'unknown',
              name: 'Garage',
              isController: false,
              backhaulType: 'Wireless'),
        ]));
    expect(find.text('Connected wirelessly — Weak (45 Mbps)'), findsOneWidget);
    expect(find.text('Connected wirelessly — Moderate (100 Mbps)'),
        findsOneWidget);
    expect(find.text('Connected wirelessly — Health unknown'), findsOneWidget);
    expect(find.textContaining('Good'), findsNothing);
  });

  testWidgets('completed internet diagnostics stop reporting running',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    expect(find.text('Your router can reach the internet'), findsOneWidget);
    expect(find.text('Running diagnostics…'), findsNothing);
  });

  testWidgets('failed internet check marks later checks as not run',
      (tester) async {
    await mount(tester, service: ProbeService()..gatewayUnavailable = true);
    await tester.tap(find.text("Internet isn't working"));
    await tester.pumpAndSettle();
    expect(find.text("Your device can't reach the router"), findsOneWidget);
    await tapText(tester, 'View test details');
    expect(find.text('Your router reached the internet — Not run'),
        findsOneWidget);
    expect(find.text('Websites are loading — Not run'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final dnsFailure in [false, true]) {
    testWidgets('collapsed result identifies ${dnsFailure ? "website" : "internet"} failure',
        (tester) async {
      await mount(tester, service: ProbeService()
        ..internetUnavailable = !dnsFailure
        ..dnsUnavailable = dnsFailure);
      await tapText(tester, "Internet isn't working");
      expect(find.text(dnsFailure
          ? "Your router is online, but websites aren't loading"
          : "Your router can't reach the internet"), findsOneWidget);
      expect(find.text('This device reached your router'), findsNothing);
      expect(find.text('Your router can reach the internet'), findsNothing);
      expect(find.text('Running diagnostics…'), findsNothing);
    });
  }

  testWidgets('diagnostic exception offers a retry without a false outcome', (tester) async {
    final service = ProbeService()..fail = true;
    await mount(tester, service: service);
    await tapText(tester, "Internet isn't working");
    expect(tester.takeException(), isNull);
    expect(find.text('Connection check could not finish'), findsOneWidget);
    expect(find.text('Your router can reach the internet'), findsNothing);
    service.fail = false;
    await tapText(tester, 'Try connection check again');
    expect(find.text('Your router can reach the internet'), findsOneWidget);
  });

  testWidgets('connection check offers one re-check per screen', (tester) async {
    for (final service in [
      ProbeService(),
      ProbeService()..gatewayUnavailable = true,
      ProbeService()..internetUnavailable = true,
      ProbeService()..fail = true,
    ]) {
      await tester.pumpWidget(const SizedBox());
      await mount(tester, service: service);
      await tapText(tester, "Internet isn't working");
      final rechecks = find.byWidgetPredicate((w) =>
          w is Text &&
          const {'Check again', 'Still seeing issues — test again',
                  'Try connection check again'}.contains(w.data));
      expect(rechecks, findsOneWidget);
      expect(find.text('Tried a fix?'), findsNothing);
      // One way back: the page's back arrow, not a second footer link.
      expect(backButton, findsOneWidget);
      expect(find.text('Back to Instant-Test'), findsNothing);
    }
  });

  testWidgets('device problem choices are visible without expanding a picker',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Internet isn't working");
    await tapText(tester, 'Yes — troubleshoot a specific device');
    await tapText(tester, 'Office printer');
    expect(find.text("What's happening with this device?"), findsOneWidget);
    expect(find.text('Change problem'), findsNothing);
    for (final label in [
      "Won't connect", 'Slow connection', 'Keeps disconnecting', 'Something else'
    ]) {
      expect(find.widgetWithText(ChoiceChip, label).hitTestable(), findsOneWidget);
    }
    expect(
        tester.widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Something else')).selected,
        isTrue);
  });

  testWidgets('re-check shows it is running even when probes finish instantly',
      (tester) async {
    final service = ProbeService();
    await mount(tester, service: service);
    await tapText(tester, "Internet isn't working");
    expect(find.textContaining('Checked again at'), findsNothing);
    final target = find.text('Still seeing issues — test again');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.calls, 2);
    expect(find.text('Running diagnostics…'), findsOneWidget);
    expect(find.text('Checking your connection…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Your router can reach the internet'), findsOneWidget);
    expect(find.textContaining('Checked again at'), findsOneWidget);
  });

  testWidgets('rejected reconnect reports failure without claiming disconnection', (tester) async {
    await mount(tester, notifier: FixtureNotifier(rejectReconnect: true));
    await tapText(tester, 'One device is slow');
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Change problem');
    await tapText(tester, 'Keeps disconnecting');
    await tapText(tester, 'Force reconnect a device');
    await tapText(tester, 'Reconnect');
    expect(find.textContaining('The reconnect request could not be confirmed'), findsOneWidget);
    expect(find.textContaining('Office printer disconnected'), findsNothing);
  });

  testWidgets('rejected restart dismisses progress without claiming recovery', (tester) async {
    final service = ProbeService()..dnsUnavailable = true;
    await mount(tester, notifier: FixtureNotifier(rejectRestart: true), service: service);
    await tapText(tester, "Internet isn't working");
    final calls = service.calls;
    await tapText(tester, 'Restart Router');
    await tapText(tester, 'Restart');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('The restart could not be confirmed'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(service.calls, calls);
    expect(find.text("If restarting didn't fix it:"), findsNothing);
  });

  testWidgets('cancelled DNS restart does not claim a restart or rerun probes', (tester) async {
    final service = ProbeService()..dnsUnavailable = true;
    await mount(tester, service: service);
    await tapText(tester, "Internet isn't working");
    final calls = service.calls;
    await tapText(tester, 'Restart Router');
    await tapText(tester, 'Cancel');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(service.calls, calls);
    expect(find.text("If restarting didn't fix it:"), findsNothing);
  });

  testWidgets('cancelled slow-connection restart does not rerun speed tests', (tester) async {
    final service = ProbeService();
    await mount(tester, service: service);
    await tapText(tester, 'Whole internet is slow');
    await tapText(tester, 'Check my speed');
    await tapText(tester, 'Everything in my home is slow');
    await tapText(tester, 'Restart + Run Speed Test Again');
    await tapText(tester, 'Cancel');
    expect(service.speedCalls, 1);
    expect(find.text('Restart + Run Speed Test Again'), findsOneWidget);
  });

  testWidgets('changing the problem starts its new instructions at step one', (tester) async {
    await mount(tester);
    await tapText(tester, 'One device is slow');
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Change problem');
    await tapText(tester, 'Something else');
    // The new answer collapses back to one line.
    expect(answer(tester, 'Problem'), 'Something else');
    expect(find.widgetWithText(ChoiceChip, 'Keeps disconnecting'), findsNothing);
    await tapText(tester, 'Try the next step');
    await tapText(tester, 'Try the next step');
    expect(find.text('Step 3 of 4'), findsOneWidget);
    await tapText(tester, 'Change problem');
    await tapText(tester, 'Keeps disconnecting');
    expect(find.text('Step 1 of 3'), findsOneWidget);
  });

  testWidgets('escalation does not present old website results as current', (tester) async {
    await mount(tester,
        notifier: FixtureNotifier(dnsCheck: const DnsCheckResult(resolved: true)),
        service: ProbeService()..internetUnavailable = true);
    await tapText(tester, "Internet isn't working");
    expect(find.text('Not checked in this test'), findsOneWidget);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('failed post-restart speed test offers retry instead of an ISP conclusion', (tester) async {
    await mount(tester, service: ProbeService()..speedFailAfterFirst = true);
    await tapText(tester, 'Whole internet is slow');
    await tapText(tester, 'Check my speed');
    await tapText(tester, 'Everything in my home is slow');
    await tapText(tester, 'Restart + Run Speed Test Again');
    await tester.tap(find.text('Restart'));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('no speed conclusion is available'), findsOneWidget);
    expect(find.text('Contact your internet provider'), findsNothing);
    expect(find.text('Check my speed'), findsOneWidget);
  });

  testWidgets('details and help pages are addressable routes; Back returns home',
      (tester) async {
    final router = await mount(tester, location: '$instantTestHome/network');
    expect(find.text('Network details'), findsOneWidget);
    expect(find.text('Internet Connection'), findsOneWidget);
    await tapBack(tester);
    expect(topRoute(router), RouteNamed.menuInstantTest);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    router.go('$instantTestHome/help?flow=5');
    await tester.pumpAndSettle();
    expect(find.text('My connection keeps cutting out'), findsOneWidget);
    expect(find.text('Start connection test'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find
                .ancestor(
                    of: find.text('Start connection test'),
                    matching: find
                        .byWidgetPredicate((widget) => widget is FilledButton))
                .first)
            .onPressed,
        isNull);
    await tapBack(tester);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('route change dismisses a pending restart confirmation',
      (tester) async {
    final router = await mount(tester, location: '$instantTestHome/help?flow=3');
    await tapText(tester, 'My device uses an Ethernet cable');
    await tapText(tester, 'Restart Router');
    expect(find.text('Restart your router?'), findsOneWidget);
    router.go(instantTestHome);
    await tester.pumpAndSettle();
    expect(find.text('Restart your router?'), findsNothing);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('a flow is pushed over Instant-Test; Back returns to it, then to Menu',
      (tester) async {
    final router = await mount(tester, location: RoutePath.dashboardMenu);
    router.pushNamed(RouteNamed.menuInstantTest);
    await tester.pumpAndSettle();
    await tapText(tester, "Internet isn't working");
    expect(topRoute(router), RouteNamed.instantTestHelp);
    expect(topLocation(router).queryParameters['flow'], '1');
    expect(find.text("My internet isn't working"), findsOneWidget);
    expect(find.text('Whole internet is slow'), findsNothing);
    await tapBack(tester);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    await tapBack(tester);
    expect(find.text('Menu page'), findsOneWidget);
  });

  testWidgets('home actions scroll with diagnostics and only workflows are offered',
      (tester) async {
    // Short enough that the condensed home still has to scroll.
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.text('What needs help?'), findsOneWidget);
    expect(find.text('Device details'), findsNothing);
    expect(find.text('Network details'), findsNothing);
    expect(find.text('View devices'), findsNothing);
    expect(find.text('View network'), findsNothing);
    final chooserTop = tester.getTopLeft(find.text('What needs help?')).dy;
    await tester.ensureVisible(find.text('What does my router light mean?'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('What needs help?')).dy, lessThan(chooserTop));
  });

  testWidgets('six direct symptoms and full-page help hide home controls',
      (tester) async {
    await mount(tester);
    for (final label in [
      "Internet isn't working",
      'Whole internet is slow',
      'One device is slow',
      "Device won't connect",
      "Doesn't reach a room",
      'Keeps cutting out'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tapText(tester, 'One device is slow');
    expect(find.text('Which device needs help?'), findsOneWidget);
    expect(find.text('Everything in my home'), findsNothing);
    expect(find.text('Run Again'), findsNothing);
    await tapBack(tester);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('each device row is one control for keyboard and screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    await mount(tester);
    await tapText(tester, "Device won't connect");
    var radios = 0;
    bool visit(SemanticsNode node) {
      if (node.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup)) radios++;
      node.visitChildren(visit);
      return true;
    }
    tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!
        .visitChildren(visit);
    expect(radios, 0, reason: 'the radio is decoration; the row is the control');
    expect(find.bySemanticsLabel(RegExp('Office printer')), findsWidgets);
    handle.dispose();
  });

  testWidgets('answers stack above the current question in one column',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    await tapText(tester, "Device won't connect");
    // Nothing to read elsewhere before choosing: only the device question.
    expect(find.text('Which device needs help?'), findsOneWidget);
    expect(find.text('Start with the device that needs help'), findsNothing);
    await tapText(tester, 'Office printer');
    final device = tester.getRect(find.byWidgetPredicate(
        (w) => w is AnswerRow && w.label == 'Device'));
    final problem = tester.getRect(find.byWidgetPredicate(
        (w) => w is AnswerRow && w.label == 'Problem'));
    final question = tester.getRect(find.text('Yes — I can see it'));
    expect(problem.top, greaterThan(device.top));
    expect(question.top, greaterThan(problem.bottom));
    expect(problem.left, device.left);
    // The next action starts inside the answers' column, not beside it.
    expect(question.left, greaterThanOrEqualTo(device.left));
    expect(question.left, lessThan(device.left + 80));
  });

  testWidgets('cannot-connect entry keeps its symptom after choosing a device',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Device won't connect");
    await tapText(tester, 'Office printer');
    expect(find.text('Yes — I can see it'), findsOneWidget);
    expect(answer(tester, 'Device'), 'Office printer');
    expect(answer(tester, 'Problem'), "Won't connect");
  });

  testWidgets('drop entry keeps its symptom after choosing a device',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    await tapText(tester, 'Choose the affected device');
    await tapText(tester, 'Office printer');
    expect(answer(tester, 'Problem'), 'Keeps disconnecting');
    expect(find.text('Device keeps dropping WiFi'), findsOneWidget);
  });

  testWidgets('check again returns home and fetches fresh diagnostic data',
      (tester) async {
    final notifier = FixtureNotifier();
    final router = await mount(tester, notifier: notifier);
    final before = notifier.fetchCount;
    await tapText(tester, "Doesn't reach a room");
    expect(topRoute(router), RouteNamed.instantTestHelp);
    await tapText(tester, 'Check again');
    expect(notifier.fetchCount, before + 1);
    expect(topRoute(router), RouteNamed.menuInstantTest);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    expect(find.text('Improve coverage in that room'), findsNothing);
  });

  testWidgets('check again from a lateral flow returns to home, not the origin',
      (tester) async {
    final notifier = FixtureNotifier();
    final router = await mount(tester, notifier: notifier);
    final before = notifier.fetchCount;
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    await tapText(tester, 'Choose the affected device');
    expect(find.text('Device keeps disconnecting'), findsOneWidget);
    await tapText(tester, 'Check again');
    expect(notifier.fetchCount, before + 1);
    expect(topRoute(router), RouteNamed.menuInstantTest);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    await tapBack(tester);
    expect(find.text('Menu page'), findsOneWidget);
  });

  testWidgets('speed result and scope share a screen and Back preserves result',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'Whole internet is slow');
    await tapText(tester, 'Check my speed');
    if (find.text('View speed test details').evaluate().isNotEmpty) {
      await tapText(tester, 'View speed test details');
    }
    expect(find.textContaining('120 Mbps down'), findsOneWidget);
    expect(find.text('No — something still feels slow'), findsNothing);
    await tapText(tester, 'Just one specific device');
    expect(find.text('One device is slow'), findsOneWidget);
    // Back from the lateral flow returns to the speed check page.
    await tapBack(tester);
    if (find.text('View speed test details').evaluate().isNotEmpty) {
      await tapText(tester, 'View speed test details');
    }
    expect(find.textContaining('120 Mbps down'), findsOneWidget);
    await tapText(tester, 'Everything in my home is slow');
    // Back steps back within the flow before leaving it.
    await tapBack(tester);
    expect(find.text('My internet is slow'), findsOneWidget);
    if (find.text('View speed test details').evaluate().isNotEmpty) {
      await tapText(tester, 'View speed test details');
    }
    expect(find.textContaining('120 Mbps down'), findsOneWidget);
  });

  testWidgets('failed speed check offers retry instead of an empty result',
      (tester) async {
    final service = ProbeService()..speedFail = true;
    await mount(tester, service: service);
    await tapText(tester, 'Whole internet is slow');
    await tapText(tester, 'Check my speed');
    expect(find.textContaining('no speed conclusion'), findsOneWidget);
    service.speedFail = false;
    await tapText(tester, 'Check my speed');
    if (find.text('View speed test details').evaluate().isNotEmpty) {
      await tapText(tester, 'View speed test details');
    }
    expect(find.textContaining('120 Mbps down'), findsOneWidget);
  });

  testWidgets('leaving a pending speed check ignores its late result',
      (tester) async {
    final service = ProbeService()..pendingSpeed = Completer<SpeedTestResult>();
    await mount(tester, service: service);
    await tapText(tester, 'Whole internet is slow');
    await tester.tap(find.text('Check my speed'));
    await tester.pump();
    await tapBack(tester);
    service.pendingSpeed!.complete(const SpeedTestResult(
        downloadMbps: 120, uploadMbps: 45, latencyMs: 18, jitterMs: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets(
      'device details pass the selected device into help and restore origin',
      (tester) async {
    final router = await mount(tester, location: '$instantTestHome/devices');
    expect(find.text('Device details'), findsOneWidget);
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Troubleshoot this device');
    expect(topRoute(router), RouteNamed.instantTestHelp);
    expect(topLocation(router).queryParameters['flow'], '30');
    expect(find.text('Select a device'), findsNothing);
    expect(answer(tester, 'Device'), 'Office printer');
    await tapBack(tester);
    expect(find.text('Device details'), findsOneWidget);
    expect(find.text('Office printer'), findsOneWidget);
  });

  testWidgets('all bridge advice branches return to their choices',
      (tester) async {
    // Desktop width: Flow 6's ListTile options under-report their intrinsic
    // height when their titles wrap, which the scrollable page frame needs.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    tester.widget<OverviewTab>(find.byType(OverviewTab)).onNavigateToFlow!(5);
    await tester.pumpAndSettle();
    for (final label in [
      'Enable bridge mode on the ISP gateway',
      'Switch Linksys to WiFi access point mode',
      'Leave it as two routers — contact my internet provider',
      'Leave as-is — internet is working fine',
    ]) {
      await tapText(tester, label);
      await tapBack(tester);
      expect(find.text('Two routers detected'), findsOneWidget);
    }
  });

  testWidgets('network details and bridge finding remain reachable',
      (tester) async {
    // Desktop width for Flow 6's ListTiles, as above.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, location: '$instantTestHome/network');
    expect(find.text('Internet Connection'), findsOneWidget);
    await tapBack(tester);
    tester.widget<OverviewTab>(find.byType(OverviewTab)).onNavigateToFlow!(5);
    await tester.pumpAndSettle();
    expect(find.text('Two routers / Combo gateway'), findsOneWidget);
  });

  testWidgets(
      'WiFi visibility choices remain editable beside connection advice',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Device won't connect");
    await tapText(tester, "I don't see my device");
    await tapText(tester, 'Yes — I can see it');
    expect(find.text("No — I don't see it"), findsOneWidget);
    await tapText(tester, "No — I don't see it");
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, "No — I don't see it"))
            .selected,
        isTrue);
    await tapText(tester, 'Yes — I can see it');
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Yes — I can see it'))
            .selected,
        isTrue);
  });

  testWidgets(
      'visible device list caps at eight and supports paging and search',
      (tester) async {
    final clients = List.generate(
        12,
        (i) => DiagnosticClient(
            macAddress: '00:00:00:00:00:${i.toString().padLeft(2, '0')}',
            hostname: 'Test device $i',
            band: '5 GHz',
            isWireless: true));
    await mount(tester, notifier: FixtureNotifier(clients: clients));
    await tapText(tester, "Device won't connect");
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Test device 0'), findsOneWidget);
    expect(find.text('Test device 7'), findsOneWidget);
    expect(find.text('Test device 8'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Next devices'));
    await tester.tap(find.byTooltip('Next devices'));
    await tester.pumpAndSettle();
    expect(find.text('Test device 8'), findsOneWidget);
    expect(find.text('Test device 0'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Test device 11');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppListCard, 'Test device 11'), findsOneWidget);
    expect(find.text('Test device 8'), findsNothing);
    await tapText(tester, 'Test device 11');
    expect(answer(tester, 'Device'), 'Test device 11');
    await tapText(tester, 'Change device');
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No devices match your search.'), findsOneWidget);
    expect(answer(tester, 'Device'), 'Test device 11');
  });

  for (final width in [390.0, 800.0]) {
    testWidgets(
        'device picker and answers are kit list cards at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clients = List.generate(
          12,
          (i) => DiagnosticClient(
              macAddress: '00:00:00:00:00:${i.toString().padLeft(2, '0')}',
              hostname: 'A device with a long name that wraps $i',
              band: '5 GHz',
              isWireless: true));
      await mount(tester, notifier: FixtureNotifier(clients: clients));
      await tapText(tester, "Device won't connect");
      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsNothing);
      final row = find.byKey(const ValueKey('device-choice-00:00:00:00:00:00'));
      expect(tester.widget(row), isA<AppListCard>());
      final heading = tester.getSemantics(find.text('Which device needs help?'));
      expect(heading.hasFlag(SemanticsFlag.isHeader), isTrue);
      await tapText(tester, 'A device with a long name that wraps 3');
      expect(tester.takeException(), isNull);
      final device = find.byWidgetPredicate(
          (w) => w is AnswerRow && w.label == 'Device');
      expect(find.descendant(of: device, matching: find.byType(AppListCard)),
          findsOneWidget);
      await tapText(tester, 'Change device');
      expect(tester.takeException(), isNull);
      expect(row, findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  }

  testWidgets('selected device row reports its selected state',
      (tester) async {
    final handle = tester.ensureSemantics();
    await mount(tester);
    await tapText(tester, "Device won't connect");
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Change device');
    final node = tester.getSemantics(
        find.byKey(const ValueKey('device-choice-AA:BB:CC:DD:EE:01')));
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    handle.dispose();
  });

  testWidgets('workflow heading supports mouse text selection', (tester) async {
    await mount(tester);
    await tapText(tester, "Device won't connect");
    final heading = find.text('Which device needs help?');
    final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: heading, matching: find.byType(RichText)));
    final rect = tester.getRect(heading);
    final drag = await tester.startGesture(rect.centerLeft + const Offset(1, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pump();
    await drag.moveTo(rect.centerRight - const Offset(1, 0));
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(paragraph.selections.any((s) => !s.isCollapsed), isTrue);
  });

  testWidgets('device selection is inline and a lost list remains unknown',
      (tester) async {
    final notifier = FixtureNotifier();
    await mount(tester, notifier: notifier);
    await tapText(tester, "Device won't connect");
    expect(find.text('Can your device connect to your WiFi?'), findsNothing);
    await tapText(tester, 'Office printer');
    expect(find.text("Won't connect"), findsOneWidget);
    notifier.loseClientList();
    await tester.pumpAndSettle();
    expect(find.textContaining('connection status is unknown'), findsOneWidget);
    expect(find.textContaining('No device list is available'), findsOneWidget);
    await tapText(tester, "I don't see my device");
    expect(find.textContaining('incomplete information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverage advice precedes optional placement without Continue',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Doesn't reach a room");
    expect(
        find.textContaining('Bedroom has a weak connection'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    await tapText(tester, 'Inside a closet, cabinet, or behind the TV');
    expect(find.textContaining('Move your router out into the open'),
        findsOneWidget);
  });

  testWidgets('lateral help Back restores drop frequency and scope',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'Keeps cutting out');
    expect(find.text('Continue'), findsNothing);
    final start = find
        .ancestor(
            of: find.text('Start connection test'),
            matching: find.byWidgetPredicate((w) => w is FilledButton))
        .first;
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    await tapText(tester, 'Choose the affected device');
    expect(find.text('Which device needs help?'), findsOneWidget);
    await tapBack(tester);
    expect(find.text('My connection keeps cutting out'), findsOneWidget);
    expect(radioSelected(tester, 'A few times a day'), isTrue);
    expect(radioSelected(tester, 'Every few minutes'), isFalse);
    expect(radioSelected(tester, 'Specific devices'), isTrue);
    expect(radioSelected(tester, 'All devices'), isFalse);
    await tapBack(tester);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('closing a monitor ignores its pending result and stops probes',
      (tester) async {
    final service = ProbeService()..pending = Completer<GatewayPingResult>();
    await mount(tester, service: service);
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'Every few minutes');
    await tapText(tester, 'All devices');
    await tester.ensureVisible(find.text('Start connection test'));
    await tester.tap(find.text('Start connection test'));
    await tester.pump(const Duration(seconds: 24));
    expect(service.calls, 1);
    await tester.pump(const Duration(seconds: 24));
    expect(service.calls, 1, reason: 'pending probes must not overlap');
    await tapBack(tester);
    service.pending!.complete(const GatewayPingResult(reachable: false));
    await tester.pump(const Duration(seconds: 48));
    expect(service.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed monitor stays inconclusive and can be retried',
      (tester) async {
    final service = ProbeService()..fail = true;
    await mount(tester, service: service);
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'Every few minutes');
    await tapText(tester, 'All devices');
    await tester.ensureVisible(find.text('Start connection test'));
    await tester.tap(find.text('Start connection test'));
    await tester.pump(const Duration(seconds: 24));
    await tester.pumpAndSettle();
    expect(find.textContaining('no conclusion is available'), findsOneWidget);
    expect(find.text('Start connection test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed monitor results are cleared when scope changes',
      (tester) async {
    final service = ProbeService();
    await mount(tester, service: service);
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'All devices');
    await tester.ensureVisible(find.text('Start connection test'));
    await tester.tap(find.text('Start connection test'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 24));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(service.calls, 5);
    expect(find.text('No drops detected right now.'), findsOneWidget);
    await tapText(tester, 'Specific devices');
    expect(find.text('No drops detected right now.'), findsNothing);
    await tapText(tester, 'All devices');
    expect(find.text('Start connection test'), findsOneWidget);
  });

  testWidgets('overview diagnostic summary fits a mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountPage(tester, const OverviewTab(showProblemCards: false));
  });

  testWidgets('mobile symptoms and workflow controls fit the viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    for (final label in ['One device is slow', 'Keeps cutting out']) {
      expect(tester.getRect(find.text(label)).right, lessThanOrEqualTo(390));
    }
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    await tapText(tester, 'Choose the affected device');
    expect(find.text('Which device needs help?'), findsOneWidget);
    expect(find.text('Run Again'), findsNothing);
  });

  for (final width in [390.0, 800.0]) {
    testWidgets('speed and drops flows fit a ${width.toInt()}px viewport',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester);
      await tapText(tester, 'Whole internet is slow');
      await tapText(tester, 'Check my speed');
      final capability = find.textContaining('Plenty fast');
      expect(
          find.ancestor(of: capability, matching: find.byType(AppListCard)),
          findsOneWidget);
      expect(tester.getRect(capability).right, lessThanOrEqualTo(width));
      await tapText(tester, 'Everything in my home is slow');
      expect(find.text('Restart + Run Speed Test Again'), findsOneWidget);
      await tapBack(tester);
      await tapBack(tester);
      await tapText(tester, 'Keeps cutting out');
      await tapText(tester, 'Every few minutes');
      await tapText(tester, 'All devices');
      expect(radioSelected(tester, 'All devices'), isTrue);
      expect(tester.getRect(find.text('Start connection test')).right,
          lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    });
  }

  test('preview actions never resolve a router repository', () async {
    var repositoryReads = 0;
    final container = ProviderContainer(overrides: [
      instantVerifyPivotProvider
          .overrideWith(MockInstantVerifyPivotNotifier.new),
      routerRepositoryProvider.overrideWith((ref) {
        repositoryReads++;
        throw StateError('preview attempted router access');
      }),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(instantVerifyPivotProvider.notifier);
    await notifier.fetch();
    await notifier.restartRouter();
    await notifier.triggerFirmwareUpdate();
    await notifier.disableMacFilter();
    await notifier.setGuestNetworkEnabled(true);
    await notifier.deauthClient(printer.macAddress);
    await notifier.changeRadioChannel('radio', 6);
    await notifier.optimizeChannels();
    await notifier.startPing('example.invalid');
    await notifier.startTraceroute('example.invalid');
    expect(repositoryReads, 0);
    expect(container.read(instantVerifyPivotProvider).hasRestartedThisSession,
        isTrue);
    await notifier.fetch();
    expect(container.read(instantVerifyPivotProvider).hasRestartedThisSession,
        isTrue);
    final browser = MockBrowserDiagnosticService();
    expect((await browser.runAll()).speedTest!.downloadMbps, 120);
    expect((await browser.runRouterSpeedTest()).throughputMbps, 240);
    expect((await browser.pingPublicIp()).reachable, isTrue);
    expect((await browser.checkPublicDns()).resolved, isTrue);
  });
}
