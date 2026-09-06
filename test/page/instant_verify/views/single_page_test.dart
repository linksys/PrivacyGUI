import 'dart:async';

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
  @override
  InstantVerifyPivotState build() => const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        clients: [printer],
        meshNodes: [
          MeshNodeInfo(
              deviceId: 'node',
              name: 'Bedroom',
              isController: false,
              backhaulType: 'Wireless',
              backhaulRssi: -80)
        ],
      );
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}
  void loseClientList() => state = state.copyWith(clients: []);
}

class ProbeService extends MockBrowserDiagnosticService {
  int calls = 0;
  Completer<GatewayPingResult>? pending;
  bool fail = false;
  @override
  Future<GatewayPingResult> pingGateway() async {
    calls++;
    if (fail) throw StateError('test probe unavailable');
    return pending == null ? super.pingGateway() : pending!.future;
  }
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
      {FixtureNotifier? notifier, BrowserDiagnosticService? service,
      Widget child = const InstantTestPage()}) async {
    await tester.pumpWidget(testableWidget(overrides: [
      instantVerifyPivotProvider
          .overrideWith(() => notifier ?? FixtureNotifier()),
      browserDiagnosticServiceProvider
          .overrideWithValue(service ?? MockBrowserDiagnosticService()),
    ], child: child));
    await tester.pumpAndSettle();
  }

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
    await tapText(tester, 'Done — back to Instant-Test');
    expect(find.text('Whole internet is slow'), findsOneWidget);
  });

  testWidgets('device selection is inline and a lost list remains unknown',
      (tester) async {
    final notifier = FixtureNotifier();
    await mount(tester, notifier: notifier);
    await tapText(tester, "Device won't connect");
    expect(find.text('Can your device connect to your WiFi?'), findsNothing);
    await tapText(tester, 'Select a device');
    await tapText(tester, 'Office printer');
    expect(find.text('Slow connection'), findsOneWidget);
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
    await tester.tap(find.byTooltip('Back to flows'));
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
    await tapText(tester, 'Done — back to Instant-Test');
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
    await tester.ensureVisible(find.text('Done — back to Instant-Test'));
    await tester.tap(find.text('Done — back to Instant-Test'));
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

  testWidgets('overview diagnostic summary fits a mobile viewport', (tester) async {
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
    expect(find.text('Which device needs help?'), findsOneWidget);
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
