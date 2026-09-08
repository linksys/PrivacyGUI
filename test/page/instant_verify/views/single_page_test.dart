import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_location.dart';
import 'dart:ui' show PointerDeviceKind;
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
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';

const printer = DiagnosticClient(
    macAddress: 'AA:BB:CC:DD:EE:01',
    hostname: 'Office printer',
    band: '2.4 GHz',
    isWireless: true,
    signalDecibels: -80,
    txRateMbps: 20);

class FixtureNotifier extends InstantVerifyPivotNotifier {
  FixtureNotifier({this.clients = const [printer], this.meshNodes});
  final List<MeshNodeInfo>? meshNodes;
  final List<DiagnosticClient> clients;
  @override
  InstantVerifyPivotState build() => InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
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
  int fetchCount = 0;
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {
    fetchCount++;
  }

  void loseClientList() => state = state.copyWith(clients: []);
}

class ProbeService extends MockBrowserDiagnosticService {
  int calls = 0;
  Completer<GatewayPingResult>? pending;
  bool fail = false;
  bool speedFail = false;
  bool gatewayUnavailable = false;
  bool internetUnavailable = false;
  bool dnsUnavailable = false;
  Completer<SpeedTestResult>? pendingSpeed;
  @override
  Future<SpeedTestResult> runInternetSpeedTest(
      {void Function(String)? onStep}) async {
    if (speedFail) throw StateError('speed unavailable');
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

void main() {
  mockDependencyRegister();

  Future<void> mount(WidgetTester tester,
      {FixtureNotifier? notifier,
      BrowserDiagnosticService? service,
      Widget child = const InstantTestPage()}) async {
    await tester.pumpWidget(testableWidget(overrides: [
      instantVerifyPivotProvider
          .overrideWith(() => notifier ?? FixtureNotifier()),
      browserDiagnosticServiceProvider
          .overrideWithValue(service ?? MockBrowserDiagnosticService()),
    ], child: child));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'home keeps the result and action visible while preserving measured details',
      (tester) async {
    await tester.pumpWidget(testableWidget(overrides: [
      instantVerifyPivotProvider
          .overrideWith(MockInstantVerifyPivotNotifier.new),
      browserDiagnosticServiceProvider
          .overrideWithValue(MockBrowserDiagnosticService()),
    ], child: const InstantTestPage()));
    await tester.pumpAndSettle();
    expect(find.text('Your router is very busy'), findsOneWidget);
    expect(find.textContaining('88% CPU'), findsNothing);
    expect(find.text('Restart Router'), findsOneWidget);
    await tapText(tester, 'Why this matters');
    expect(find.textContaining('88% CPU'), findsOneWidget);
    await tapText(tester, 'Hide why this matters');
    expect(find.textContaining('88% CPU'), findsNothing);
    await tapText(tester, '3 other findings');
    expect(find.text('Restart Router'), findsWidgets);
  });

  testWidgets('wide layouts use available space and follow resizing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2048, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    final first = find.widgetWithText(AppOutlinedButton, "Internet isn't working");
    final last = find.widgetWithText(AppOutlinedButton, 'Keeps cutting out');
    expect(tester.getBottomRight(last).dx - tester.getTopLeft(first).dx, greaterThan(1800));
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(first).dx, lessThanOrEqualTo(390));
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
          matching: find.byWidgetPredicate((widget) => widget is OutlinedButton)).first;
      final labelWidth = tester.getSize(find.text('Yes — troubleshoot a specific device')).width;
      expect(tester.getSize(action).width, lessThanOrEqualTo(labelWidth + 100));
      expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    }
    await tapText(tester, 'Yes — troubleshoot a specific device');
    expect(find.text('1. Choose a device'), findsOneWidget);
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
    await tapText(tester, 'Troubleshoot these devices');
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Change problem');
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Slow connection'))
            .selected,
        isTrue);
    expect(find.text('Yes — I can see it'), findsNothing);
  });

  testWidgets('network detail health includes link speed and unknown telemetry',
      (tester) async {
    await mount(tester,
        child: const MyNetworkTab(),
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

  test('navigation URL accepts only known views and flows', () {
    expect(InstantTestLocation.parse('devices/5/32').value, 'devices/5/32');
    for (final invalid in [
      'devices/password',
      'restart',
      '999',
      '1/1/1/1/1/1/1/1/1'
    ]) {
      expect(InstantTestLocation.parse(invalid).value, isEmpty);
    }
  });

  testWidgets(
      'route restores details and return clears the navigation parameter',
      (tester) async {
    final router = GoRouter(
        initialLocation: '/instant-prototype?instant=network',
        routes: [
          GoRoute(
              path: '/instant-prototype',
              builder: (_, __) => const InstantTestPage()),
        ]);
    addTearDown(router.dispose);
    await mount(tester,
        child: Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ));
    expect(find.text('Internet Connection'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Instant-Test'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['instant'],
        isNull);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    router.go('/instant-prototype?instant=5/32');
    await tester.pumpAndSettle();
    expect(find.text('Device keeps disconnecting'), findsOneWidget);
    expect(find.byTooltip('Back to connection check'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to connection check'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['instant'],
        '5');
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
  });

  testWidgets('route change dismisses a pending restart confirmation',
      (tester) async {
    final router =
        GoRouter(initialLocation: '/instant-prototype?instant=3', routes: [
      GoRoute(
          path: '/instant-prototype',
          builder: (_, __) => const InstantTestPage()),
    ]);
    addTearDown(router.dispose);
    await mount(tester,
        child: Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ));
    await tapText(tester, 'My device uses an Ethernet cable');
    await tapText(tester, 'Restart Router');
    expect(find.text('Restart your router?'), findsOneWidget);
    router.go('/instant-prototype');
    await tester.pumpAndSettle();
    expect(find.text('Restart your router?'), findsNothing);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('home actions scroll with diagnostics and details follow results',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.text('What needs help?'), findsOneWidget);
    expect(find.text('Device details'), findsNothing);
    expect(find.text('Network details'), findsNothing);
    expect(
        tester.getTopLeft(find.text('View devices')).dy,
        greaterThan(
            tester.getBottomLeft(find.text("Doesn't reach a room")).dy));
    await tester.ensureVisible(find.text('View devices'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('What needs help?')).dy, lessThan(0));
    await tapText(tester, 'View devices');
    expect(find.text('Device details'), findsOneWidget);
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
    expect(find.text('1. Choose a device'), findsOneWidget);
    expect(find.text('Everything in my home'), findsNothing);
    expect(find.text('Run Again'), findsNothing);
    await tapText(tester, 'Back to Instant-Test');
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('cannot-connect entry keeps its symptom after choosing a device',
      (tester) async {
    await mount(tester);
    await tapText(tester, "Device won't connect");
    await tapText(tester, 'Office printer');
    expect(find.text('Yes — I can see it'), findsOneWidget);
    await tapText(tester, 'Change problem');
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, "Won't connect"))
            .selected,
        isTrue);
  });

  testWidgets('drop entry keeps its symptom after choosing a device',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'Keeps cutting out');
    await tapText(tester, 'A few times a day');
    await tapText(tester, 'Specific devices');
    await tapText(tester, 'Choose the affected device');
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Change problem');
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Keeps disconnecting'))
            .selected,
        isTrue);
    expect(find.text('Device keeps dropping WiFi'), findsOneWidget);
  });

  testWidgets('check again returns home and fetches fresh diagnostic data',
      (tester) async {
    final notifier = FixtureNotifier();
    await mount(tester, notifier: notifier);
    final before = notifier.fetchCount;
    await tapText(tester, "Doesn't reach a room");
    expect(find.byTooltip('Back to Instant-Test'), findsOneWidget);
    await tapText(tester, 'Check again');
    expect(notifier.fetchCount, before + 1);
    expect(find.text('Whole internet is slow'), findsOneWidget);
    expect(find.text('Improve coverage in that room'), findsNothing);
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
    await tester.tap(find.byTooltip('Back to speed check'));
    await tester.pumpAndSettle();
    if (find.text('View speed test details').evaluate().isNotEmpty) {
      await tapText(tester, 'View speed test details');
    }
    expect(find.textContaining('120 Mbps down'), findsOneWidget);
    await tapText(tester, 'Everything in my home is slow');
    expect(find.byTooltip('Back to previous step'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to previous step'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Back to Instant-Test'));
    await tester.tap(find.text('Back to Instant-Test'));
    await tester.pumpAndSettle();
    service.pendingSpeed!.complete(const SpeedTestResult(
        downloadMbps: 120, uploadMbps: 45, latencyMs: 18, jitterMs: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets(
      'device details pass the selected device into help and restore origin',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'View devices');
    await tapText(tester, 'Office printer');
    await tapText(tester, 'Troubleshoot this device');
    expect(find.text('Select a device'), findsNothing);
    expect(find.text('Help for Office printer'), findsOneWidget);
    expect(find.byTooltip('Back to device details'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to device details'));
    await tester.pumpAndSettle();
    expect(find.text('Device details'), findsOneWidget);
    expect(find.text('Office printer'), findsOneWidget);
  });

  testWidgets('all bridge advice branches return to their choices',
      (tester) async {
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
      await tester.tap(find.byTooltip('Back to previous step'));
      await tester.pumpAndSettle();
      expect(find.text('Two routers detected'), findsOneWidget);
    }
  });

  testWidgets('network details and bridge finding remain reachable',
      (tester) async {
    await mount(tester);
    await tapText(tester, 'View network');
    expect(find.text('Internet Connection'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Instant-Test'));
    await tester.pumpAndSettle();
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
    expect(find.widgetWithText(ListTile, 'Test device 11'), findsOneWidget);
    expect(find.text('Test device 8'), findsNothing);
    await tapText(tester, 'Test device 11');
    expect(find.text('Help for Test device 11'), findsOneWidget);
    await tapText(tester, 'Change device');
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No devices match your search.'), findsOneWidget);
    expect(find.text('Help for Test device 11'), findsOneWidget);
  });

  testWidgets('workflow heading supports mouse text selection', (tester) async {
    await mount(tester);
    await tapText(tester, "Device won't connect");
    final heading = find.text('1. Choose a device');
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
    expect(find.text('1. Choose a device'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to connection check'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'A few times a day'))
            .selected,
        isTrue);
    expect(
        tester
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Specific devices'))
            .selected,
        isTrue);
    await tapText(tester, 'Back to Instant-Test');
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
    await tester.ensureVisible(find.text('Back to Instant-Test'));
    await tester.tap(find.text('Back to Instant-Test'));
    await tester.pump();
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
    await mount(tester, child: const OverviewTab(showProblemCards: false));
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
    expect(find.text('1. Choose a device'), findsOneWidget);
    expect(find.text('Run Again'), findsNothing);
  });

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
