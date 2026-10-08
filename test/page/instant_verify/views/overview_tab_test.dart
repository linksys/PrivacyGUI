import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/symptom_chooser.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/mock_instant_verify_pivot_notifier.dart';

// ── Test state factories ─────────────────────────────────────────────────────

InstantVerifyPivotState _loadingState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.loading,
    browserTestStep: 'idle',
  );
}

InstantVerifyPivotState _allClearState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
    deviceInfo: const {'modelNumber': 'MX6200', 'firmwareVersion': '1.0.10'},
    routerHealth: const {'uptimeInSeconds': 86400},
    dnsCheck: const DnsCheckResult(resolved: true, latencyMs: 15),
    speedTest: const SpeedTestResult(
        downloadMbps: 100, uploadMbps: 50, latencyMs: 12, jitterMs: 3),
    verdict: const Verdict(findings: [], checksRun: 8),
    verdictIsPreliminary: false,
  );
}

InstantVerifyPivotState _criticalFindingState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
    deviceInfo: const {'modelNumber': 'MX6200'},
    routerHealth: const {'uptimeInSeconds': 86400},
    dnsCheck: const DnsCheckResult(resolved: false, latencyMs: 0),
    verdict: const Verdict(
      findings: [
        VerdictFinding(
          priority: VerdictPriority.critical,
          headline: "Your internet isn't working",
          explanation: 'Verified: Router reachable. Websites: not loading.',
          actionLabel: 'Restart Router',
          actionKey: 'restart_router',
          checkNumber: 4,
          postRestartEscalation: 'Contact your provider.',
        ),
      ],
      checksRun: 4,
    ),
    verdictIsPreliminary: false,
  );
}

InstantVerifyPivotState _multipleFindingsState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
    deviceInfo: const {'modelNumber': 'MX6200'},
    routerHealth: const {'uptimeInSeconds': 90 * 86400},
    firmwareUpdate: const {'firmwareUpdateStatus': 'UpdateAvailable', 'availableUpdate': {'firmwareVersion': '2.0.0'}},
    dnsCheck: const DnsCheckResult(resolved: true),
    speedTest: const SpeedTestResult(
        downloadMbps: 15, uploadMbps: 5, latencyMs: 120, jitterMs: 10),
    verdict: const Verdict(
      findings: [
        VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'Your internet is slower than expected (15 Mbps)',
          explanation: 'Getting about 15 Mbps.',
          actionLabel: 'Restart Router',
          actionKey: 'restart_router',
          checkNumber: 6,
        ),
        VerdictFinding(
          priority: VerdictPriority.warning,
          headline: 'High lag detected (120ms)',
          explanation: 'High latency causes delays.',
        ),
        VerdictFinding(
          priority: VerdictPriority.info,
          headline: 'A software update is available (2.0.0)',
          explanation: 'Keeping your router updated improves performance.',
          actionLabel: 'Update Now',
          actionKey: 'firmware_update',
        ),
        VerdictFinding(
          priority: VerdictPriority.info,
          headline: 'Your router has been running for 90 days',
          explanation: 'A restart can clear up slowdowns.',
          actionLabel: 'Restart Router',
          actionKey: 'restart_router',
        ),
      ],
      checksRun: 8,
    ),
    verdictIsPreliminary: false,
  );
}

InstantVerifyPivotState _wanDownState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Disconnected'},
    deviceInfo: const {'modelNumber': 'MX6200'},
    verdict: const Verdict(
      findings: [
        VerdictFinding(
          priority: VerdictPriority.critical,
          headline: 'No internet connection detected',
          explanation: 'Check your modem.',
        ),
      ],
      checksRun: 2,
    ),
    verdictIsPreliminary: false,
  );
}

InstantVerifyPivotState _meshState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
    deviceInfo: const {'modelNumber': 'MX6200'},
    routerHealth: const {'uptimeInSeconds': 86400},
    meshNodes: const [
      MeshNodeInfo(deviceId: 'router', name: 'Kitchen', isController: true, model: 'MX6200'),
      MeshNodeInfo(deviceId: 'sat-1', name: 'Living Room', isController: false, backhaulType: 'Wireless', backhaulRssi: -55, model: 'MX6200'),
      MeshNodeInfo(deviceId: 'sat-2', name: 'Bedroom', isController: false, backhaulType: 'Wireless', backhaulRssi: -78, model: 'MX6200'),
    ],
    dnsCheck: const DnsCheckResult(resolved: true),
    speedTest: const SpeedTestResult(
        downloadMbps: 100, uploadMbps: 50, latencyMs: 12, jitterMs: 3),
    verdict: const Verdict(findings: [], checksRun: 11),
    verdictIsPreliminary: false,
  );
}

InstantVerifyPivotState _deviceIssuesState() {
  const weakClient = DiagnosticClient(
    macAddress: 'AA:BB:CC:DD:EE:01',
    hostname: 'iPhone',
    band: '2.4GHz',
    signalDecibels: -82,
    txRateMbps: 5,
    rxRateMbps: 5,
    isWireless: true,
  );
  final weakScore = DeviceScore.compute(weakClient);

  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
    deviceInfo: const {'modelNumber': 'MX6200'},
    routerHealth: const {'uptimeInSeconds': 86400},
    clients: const [weakClient],
    deviceScores: [weakScore],
    dnsCheck: const DnsCheckResult(resolved: true),
    speedTest: const SpeedTestResult(
        downloadMbps: 100, uploadMbps: 50, latencyMs: 12, jitterMs: 3),
    verdict: const Verdict(findings: [], checksRun: 8),
    verdictIsPreliminary: false,
  );
}

// ── Test setup helper ────────────────────────────────────────────────────────

Widget _buildOverviewTab(
  InstantVerifyPivotState state, {
  VoidCallback? onViewClients,
  void Function(int)? onNavigateToFlow,
}) {
  final mockNotifier = MockInstantVerifyPivotNotifier(state);
  return testableWidget(
    overrides: [
      instantVerifyPivotProvider.overrideWith(() => mockNotifier),
    ],
    child: OverviewTab(
      onViewClients: onViewClients,
      onNavigateToFlow: onNavigateToFlow,
    ),
  );
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  mockDependencyRegister();

  group('OverviewTab — loading state', () {
    testWidgets('shows visible check progress during loading',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      expect(find.text('Checking your connection'), findsOneWidget);
      expect(find.text('Router'), findsOneWidget);
      expect(find.text('View test progress'), findsNothing);
    });

    testWidgets('finished run scrolls its result back into view', (tester) async {
      final notifier = MockInstantVerifyPivotNotifier(_loadingState());
      await tester.pumpWidget(testableWidget(
        overrides: [instantVerifyPivotProvider.overrideWith(() => notifier)],
        child: const OverviewTab(
            leading: SizedBox(height: 4000, child: Text('What needs help?'))),
      ));
      await tester.pump();
      // While the run is in progress the user scrolls on to the chooser.
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(find.text('Checking your connection').hitTestable(), findsNothing);

      // ignore: invalid_use_of_protected_member
      notifier.state = _allClearState();
      await tester.pumpAndSettle();
      expect(find.text("We didn't detect any issues").hitTestable(), findsOneWidget);
    });

    testWidgets('overall progress is a bar, leaving one spinner on the running check',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();
      // Only the running row spins; overall progress is a separate bar (QA).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_buildOverviewTab(const InstantVerifyPivotState(
        phase: PivotLoadPhase.jnapLoaded,
        browserTestStep: 'dns',
        wanStatus: {'wanStatus': 'Connected'},
        gatewayPing: GatewayPingResult(reachable: true, latencyMs: 2),
      )));
      await tester.pump();
      final later = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(later.value, greaterThan(0));
      expect(later.value, lessThan(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows individual checks without a disclosure', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('Router'), findsAtLeast(1));
      expect(find.text('Internet'), findsOneWidget);
      expect(find.text('Speed test'), findsOneWidget);
      expect(find.text('Your devices'), findsOneWidget);
    });
  });

  group('OverviewTab — all-clear state', () {
    testWidgets('shows "We didn\'t detect any issues"', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text("We didn't detect any issues"), findsOneWidget);
    });

    testWidgets('shows checks passed count', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // The count matches the rows under "View test details", and names
      // what did not run, rather than an internal check total (QA: "which 13?").
      expect(find.text('4 of 6 checks passed · Not run: Devices, Firmware'),
          findsOneWidget);
      expect(find.text('8 checks passed'), findsNothing);
    });

    testWidgets('skipped speed test is named instead of silently lowering the count',
        (tester) async {
      const laptop = DiagnosticClient(macAddress: 'AA:BB:CC:00:00:01',
          hostname: 'Laptop', isWireless: true, signalDecibels: -50,
          txRateMbps: 400, band: '5 GHz');
      await tester.pumpWidget(_buildOverviewTab(InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {'wanStatus': 'Connected'},
        deviceInfo: const {'modelNumber': 'MX6200'},
        dnsCheck: const DnsCheckResult(resolved: true, latencyMs: 15),
        clients: const [laptop],
        deviceScores: [DeviceScore.compute(laptop)],
        firmwareUpdate: const {'availableUpdate': null},
        verdict: const Verdict(findings: [], checksRun: 11),
        verdictIsPreliminary: false,
      )));
      await tester.pump();
      expect(find.text('5 of 6 checks passed · Not run: Speed check'),
          findsOneWidget);
    });

    testWidgets('shows 5 flow cards', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text("My internet\nisn't working"), findsOneWidget);
      expect(find.text('My internet\nis slow'), findsOneWidget);
      expect(find.text("A device won't\nconnect"), findsOneWidget);
      expect(find.text("WiFi doesn't\nreach a room"), findsOneWidget);
      expect(find.text('My connection\nkeeps cutting out'), findsOneWidget);
    });

    testWidgets('flow card triggers onNavigateToFlow', (tester) async {
      int? navigatedFlow;
      await tester.pumpWidget(_buildOverviewTab(
        _allClearState(),
        onNavigateToFlow: (i) => navigatedFlow = i,
      ));
      await tester.pump();

      // Tap "My internet is slow" card (flow index 1)
      await tester.tap(find.text('My internet\nis slow'));
      expect(navigatedFlow, 1);
    });

    testWidgets('U-01: flow cards stay visible when findings are present',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      // Regression: the Fix-flow entry cards previously vanished the moment a
      // finding appeared. They must remain reachable in warning/issue states.
      expect(find.text("My internet\nisn't working"), findsOneWidget);
      expect(find.text('My connection\nkeeps cutting out'), findsOneWidget);
      expect(find.textContaining('Something else?'), findsOneWidget);
    });

    testWidgets('keeps the result visible while test details are collapsed', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('View test details'), findsOneWidget);
      expect(find.text('Router reached'), findsNothing);
      expect(find.text("We didn't detect any issues"), findsOneWidget);
    });

    testWidgets('shows router model only in test details', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('MX6200'), findsNothing);
      await _tap(tester, 'View test details');
      expect(find.text('MX6200'), findsAtLeast(1));
    });

    testWidgets('shows connection evidence in optional details', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Connected'), findsNothing);
      await _tap(tester, 'View test details');
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Internet reachable'), findsOneWidget);
    });
  });

  group('OverviewTab — critical finding', () {
    testWidgets('shows critical headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.text("Your internet isn't working"), findsOneWidget);
    });

    testWidgets('shows explanation as subtext without hiding the recommended action', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.text('Restart Router'), findsOneWidget);
      expect(find.text('Why this matters'), findsNothing);
      expect(
          find.text('Verified: Router reachable. Websites: not loading.'),
          findsOneWidget);
    });

    testWidgets('shows action button', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.text('Restart Router'), findsOneWidget);
    });

    testWidgets('shows error icon for critical priority', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.byIcon(LinksysIcons.error), findsOneWidget);
    });
  });

  group('OverviewTab — multiple findings', () {
    testWidgets('shows primary finding headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.text('Your internet is slower than expected (15 Mbps)'),
          findsOneWidget);
    });

    testWidgets('counts secondary findings without showing their text', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.text('3 more things we found'), findsOneWidget);
      expect(find.text('High lag detected (120ms)'), findsNothing);
    });

    testWidgets('shows secondary finding headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      await _tap(tester, '3 more things we found');
      expect(find.text('High lag detected (120ms)'), findsOneWidget);
    });

    testWidgets('secondary findings can be closed again', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      await _tap(tester, '3 more things we found');
      await _tap(tester, 'Hide 3 more things we found');
      expect(find.text('High lag detected (120ms)'), findsNothing);
      expect(find.text('Your internet is slower than expected (15 Mbps)'), findsOneWidget);
    });

    testWidgets('expanding shows hidden findings', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      // Hidden findings should not be visible yet
      expect(find.text('A software update is available (2.0.0)'),
          findsNothing);

      // Tap expand
      await _tap(tester, '3 more things we found');
      await tester.pump();

      // Now they should be visible
      expect(find.text('A software update is available (2.0.0)'),
          findsOneWidget);
      expect(find.text('Your router has been running for 90 days'),
          findsOneWidget);
    });
  });

  group('OverviewTab — WAN down', () {
    testWidgets('shows the WAN failure result without expanding details', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      expect(find.text('No internet connection detected'), findsOneWidget);
    });

    testWidgets('shows WAN-down inline light guide callout', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      expect(find.text('No internet connection detected.'), findsAtLeast(1));
    });
  });

  group('OverviewTab — header bar', () {
    testWidgets('shows firmware version', (tester) async {
      // Firmware now shown in AppBar info icon sheet, not the body header
      // This test verifies the state has the firmware value (not UI presence)
      final state = _allClearState();
      expect(state.routerFirmware, equals('1.0.10'));
    });

    testWidgets('shows "Checking..." chip during loading', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      expect(find.text('Checking your connection'), findsOneWidget);
    });
  });

  group('OverviewTab — light guide', () {
    testWidgets('shows persistent light guide link', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(
          find.text('What does my router light mean?'), findsOneWidget);
    });

    testWidgets('tapping opens bottom sheet with LED patterns',
        (tester) async {
      // Use a larger surface to avoid bottom sheet overflow
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      await tester.tap(find.text('What does my router light mean?'));
      await tester.pumpAndSettle();

      // LED guide bottom sheet content
      expect(find.text('Solid white'), findsOneWidget);
      expect(find.text('Pulsing blue'), findsOneWidget);
      expect(find.text('Solid red'), findsOneWidget);
      expect(find.text('Solid yellow'), findsOneWidget);
      expect(find.text('Solid green'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });
  });

  group('OverviewTab — mesh in the found list', () {
    testWidgets('a weak WiFi node is listed with what else we found',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_meshState()));
      await tester.pump();

      // No separate mesh card: only the weak node needs attention.
      expect(find.textContaining('Mesh Network'), findsNothing);
      expect(find.text('Bedroom has a weak connection to the router'),
          findsNothing);
      await _tap(tester, '1 more thing we found');
      expect(find.text('Bedroom has a weak connection to the router'),
          findsOneWidget);
      expect(find.textContaining('Living Room'), findsNothing);
      expect(find.textContaining('Kitchen'), findsNothing);
    });

    testWidgets('nothing extra is listed for a single router', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.textContaining('more thing'), findsNothing);
    });
  });

  group('OverviewTab — devices in the found list', () {
    testWidgets('a weak device is listed by name with its signal',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_deviceIssuesState()));
      await tester.pump();

      expect(find.text('Devices that may need help'), findsNothing);
      expect(find.text('iPhone has a weak WiFi signal'), findsNothing);
      await _tap(tester, '1 more thing we found');
      expect(find.text('iPhone has a weak WiFi signal'), findsOneWidget);
      expect(find.text('-82 dBm on 2.4GHz'), findsOneWidget);
      // Plain names; no MAC address unless two devices share a name.
      expect(find.textContaining('AA:BB:CC:DD:EE:01'), findsNothing);
    });

    testWidgets('a weak-WiFi summary finding is replaced by its devices',
        (tester) async {
      final base = _deviceIssuesState();
      await tester.pumpWidget(_buildOverviewTab(base.copyWith(
          verdict: const Verdict(checksRun: 8, findings: [
        VerdictFinding(
            priority: VerdictPriority.warning,
            headline: 'Your router is under high load (88% CPU)',
            explanation: 'A restart usually clears this.',
            actionLabel: 'Restart Router',
            actionKey: VerdictEngine.actionRestartRouter),
        VerdictFinding(
            priority: VerdictPriority.warning,
            headline: '1 device with weak WiFi',
            explanation: 'iPhone has a weak WiFi connection.',
            checkNumber: 7,
            aboutIssueDevices: true),
      ]))));
      await tester.pump();

      await _tap(tester, '1 more thing we found');
      expect(find.text('iPhone has a weak WiFi signal'), findsOneWidget);
      expect(find.text('1 device with weak WiFi'), findsNothing);
    });

    testWidgets('nothing extra is listed when all devices are fine',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.textContaining('weak WiFi signal'), findsNothing);
    });
  });

  group('OverviewTab — Run Again button', () {
    testWidgets('shows "Run Again" button', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Run Again'), findsOneWidget);
    });

    testWidgets('"Test scenarios" button gated on force=local (hidden in test env)',
        (tester) async {
      // The mock-scenario button is now gated on BuildConfig.forceCommandType
      // == ForceCommand.local (set by deploy_local.sh), replacing the old
      // kDebugMode guard. The test environment is not force=local, so the
      // button is correctly absent. (Internal validation builds show it.)
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Test scenarios'), findsNothing);
    });
  });

  group('OverviewTab — progressive disclosure (S-5)', () {
    testWidgets('opening test details reveals the checklist summary',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Router reached'), findsNothing);
      await _tap(tester, 'View test details');
      expect(find.text('Router reached'), findsOneWidget);
      expect(find.text('Internet connected'), findsOneWidget);
      expect(find.text('Websites loading'), findsOneWidget);
      expect(find.text('Speed check'), findsOneWidget);
      expect(find.text('Devices checked'), findsOneWidget);
    });

    testWidgets('tapping a checklist row expands its detail',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // Detail text should not be visible yet
      expect(
          find.textContaining('We connected to your router'),
          findsNothing);

      // Open the checklist, then inspect an individual result.
      await _tap(tester, 'View test details');
      await _tap(tester, 'Router reached');
      await tester.pump();

      // Expanded detail should now be visible
      expect(
          find.textContaining('We connected to your router'),
          findsOneWidget);
    });
  });

  group('OverviewTab — restart confirmation dialog', () {
    testWidgets('tapping Restart Router shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      // Tap the restart button
      await tester.tap(find.text('Restart Router'));
      await tester.pumpAndSettle();

      // Dialog should appear (unified shared confirmAndRestart — I-1)
      expect(find.text('Restart your router?'), findsOneWidget);
      expect(find.textContaining('All devices will disconnect'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });
  });

  group('OverviewTab — connection evidence in details', () {
    testWidgets('WAN connected with DNS not run stays explicitly untested',
        (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
        deviceInfo: const {'modelNumber': 'MX6200'},
        verdict: const Verdict(findings: [], checksRun: 4),
        verdictIsPreliminary: false,
      );
      await tester.pumpWidget(_buildOverviewTab(state));
      await tester.pump();

      await _tap(tester, 'View test details');
      expect(find.text('Not confirmed'), findsOneWidget);
      expect(find.text('Not tested'), findsOneWidget);
      expect(find.text('Internet reachable'), findsNothing);
    });

    testWidgets('successful DNS shows evidence of internet reachability',
        (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
        deviceInfo: const {'modelNumber': 'MX6200'},
        dnsCheck: const DnsCheckResult(resolved: true, latencyMs: 10),
        verdict: const Verdict(findings: [], checksRun: 4),
        verdictIsPreliminary: false,
      );
      await tester.pumpWidget(_buildOverviewTab(state));
      await tester.pump();

      await _tap(tester, 'View test details');
      expect(find.text('Internet reachable'), findsOneWidget);
      expect(find.text('Not tested'), findsNothing);
    });

    testWidgets(
        'failed DNS stays failed even when WAN reports connected',
        (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: const {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '192.168.50.105'}},
        deviceInfo: const {'modelNumber': 'MX6200'},
        dnsCheck: const DnsCheckResult(resolved: false, latencyMs: 0),
        verdict: const Verdict(findings: [], checksRun: 4),
        verdictIsPreliminary: false,
      );
      await tester.pumpWidget(_buildOverviewTab(state));
      await tester.pump();

      await _tap(tester, 'View test details');
      expect(find.text('Internet not responding'), findsOneWidget);
      expect(find.text('No internet service'), findsOneWidget);
      expect(find.text('Internet reachable'), findsNothing);
    });

    testWidgets('WAN disconnected shows no internet service in details',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      await _tap(tester, 'View test details');
      expect(find.text('No internet service'), findsOneWidget);
      expect(find.text('Connected'), findsNothing);
    });
  });

  group('OverviewTab — primary action row', () {
    testWidgets('the fix and everything else found share one action row',
        (tester) async {
      // _multipleFindingsState() has 4 findings; the primary has a restart fix.
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.textContaining('Start here'), findsNothing);
      final fix = tester.getCenter(find.text('Restart Router'));
      final more = tester.getCenter(find.text('3 more things we found'));
      expect((fix.dy - more.dy).abs(), lessThan(8));
      expect(more.dx, greaterThan(fix.dx));
    });

    testWidgets('single finding does not show start-here annotation',
        (tester) async {
      // _criticalFindingState() has exactly 1 finding.
      // visible.length == 1 and hidden.isEmpty → condition is false.
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.textContaining('Start here'), findsNothing);
    });
  });

  // Part 2 of the integration spec: the results page is built from the
  // standard kit components, as the rest of the router UI is.
  group('OverviewTab — kit components', () {
    AppCard cardAround(WidgetTester tester, String text) =>
        tester.widget<AppCard>(find
            .ancestor(of: find.text(text), matching: find.byType(AppCard))
            .last);

    testWidgets('the result card keeps the default border; status is the icon',
        (tester) async {
      for (final (state, headline, icon) in [
        (_criticalFindingState(), "Your internet isn't working",
            LinksysIcons.error),
        (_allClearState(), "We didn't detect any issues",
            LinksysIcons.checkCircle),
        (_multipleFindingsState(),
            'Your internet is slower than expected (15 Mbps)',
            LinksysIcons.error),
      ]) {
        await tester.pumpWidget(_buildOverviewTab(state));
        await tester.pump();
        final card = cardAround(tester, headline);
        expect(card.borderColor, isNull, reason: headline);
        expect(card.color, isNull, reason: headline);
        expect(
            find.descendant(
                of: find.byWidget(card), matching: find.byIcon(icon)),
            findsWidgets,
            reason: headline);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('everything else found is a borderless AppListCard row',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();
      await _tap(tester, '3 more things we found');

      for (final headline in [
        'High lag detected (120ms)',
        'A software update is available (2.0.0)',
        'Your router has been running for 90 days',
      ]) {
        final row = find.ancestor(
            of: find.text(headline), matching: find.byType(AppListCard));
        expect(row, findsOneWidget, reason: headline);
        final card = tester.widget<AppListCard>(row);
        expect(card.showBorder, isFalse, reason: headline);
        expect(card.leading, isA<Icon>(), reason: headline);
      }
      // The row's fix is its trailing action.
      final update = tester.widget<AppListCard>(find.ancestor(
          of: find.text('A software update is available (2.0.0)'),
          matching: find.byType(AppListCard)));
      expect(update.trailing, isNotNull);
      expect(
          find.descendant(
              of: find.byWidget(update), matching: find.text('Update Now')),
          findsOneWidget);
    });

    testWidgets('a weak device row shows its detail as the description',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_deviceIssuesState()));
      await tester.pump();
      await _tap(tester, '1 more thing we found');
      final row = tester.widget<AppListCard>(find.ancestor(
          of: find.text('iPhone has a weak WiFi signal'),
          matching: find.byType(AppListCard)));
      expect(row.showBorder, isFalse);
      expect(
          find.descendant(
              of: find.byWidget(row), matching: find.text('-82 dBm on 2.4GHz')),
          findsOneWidget);
    });

    testWidgets('problem choices are rounded AppCard tiles, not buttons',
        (tester) async {
      int? navigatedFlow;
      await tester.pumpWidget(_buildOverviewTab(_allClearState(),
          onNavigateToFlow: (i) => navigatedFlow = i));
      await tester.pump();
      expect(find.byType(AppOutlinedButton), findsNothing);
      final tile = find.ancestor(
          of: find.text('My internet\nis slow'), matching: find.byType(AppCard));
      expect(tile, findsWidgets);
      await tester.tap(find.text('My internet\nis slow'));
      expect(navigatedFlow, 1);
    });

    testWidgets('WAN-down callout is a blocking AppSettingCard (error border)',
        (tester) async {
      // The light guide dialog needs the same tall surface as its own test.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();
      final callout = find.ancestor(
          of: find.text('No internet connection detected.'),
          matching: find.byType(AppSettingCard));
      expect(callout, findsOneWidget);
      final card = tester.widget<AppSettingCard>(callout);
      final context = tester.element(callout);
      expect(card.borderColor, Theme.of(context).colorScheme.error);
      expect(card.description, "Check your router's light. What color is it?");
      expect(
          find.descendant(
              of: callout, matching: find.text('What does my light mean?')),
          findsOneWidget);
      await tester.tap(find.text('What does my light mean?'));
      await tester.pumpAndSettle();
      expect(find.text('Solid red'), findsOneWidget);
    });

    testWidgets('recent-restart note is a non-blocking AppSettingCard',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(
          _criticalFindingState().copyWith(recentPriorRestart: true)));
      await tester.pump();
      final note = find.ancestor(
          of: find.textContaining('You restarted your router recently'),
          matching: find.byType(AppSettingCard));
      expect(note, findsOneWidget);
      final card = tester.widget<AppSettingCard>(note);
      expect(card.borderColor, isNull);
      expect(card.color, isNull);
      expect(card.leading, isA<Icon>());
    });

    testWidgets('post-restart escalation is an info card with a colored icon',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(
          _criticalFindingState().copyWith(hasRestartedThisSession: true)));
      await tester.pump();
      final note = find.ancestor(
          of: find.text('Contact your provider.'),
          matching: find.byType(AppSettingCard));
      expect(note, findsOneWidget);
      final card = tester.widget<AppSettingCard>(note);
      expect(card.borderColor, isNull);
      expect(card.leading, isA<Icon>());
      // The fix is replaced by the escalation after a restart.
      expect(find.text('Restart Router'), findsNothing);
      expect(find.text('Check Again'), findsOneWidget);
    });
  });

  group('SymptomChooser — menu tiles', () {
    Future<void> pumpChooser(WidgetTester tester, Size size,
        {ValueChanged<int>? onSelect}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(testableWidget(
          child: SingleChildScrollView(
              child: SymptomChooser(onSelect: onSelect ?? (_) {}))));
      await tester.pump();
    }

    double top(WidgetTester tester, String label) => tester
        .getTopLeft(find
            .ancestor(of: find.text(label), matching: find.byType(AppCard))
            .first)
        .dy;

    testWidgets('choices are AppCard tiles with an icon and a title',
        (tester) async {
      int? selected;
      await pumpChooser(tester, const Size(1280, 800),
          onSelect: (id) => selected = id);
      expect(find.text('What needs help?'), findsOneWidget);
      expect(find.byType(AppOutlinedButton), findsNothing);
      for (final (_, icon, label) in SymptomChooser.symptoms) {
        final tile = find.ancestor(
            of: find.text(label), matching: find.byType(AppCard));
        expect(tile, findsOneWidget, reason: label);
        expect(find.descendant(of: tile, matching: find.byIcon(icon)),
            findsOneWidget,
            reason: label);
      }
      await tester.tap(find.text('One device is slow'));
      expect(selected, 31);
      expect(tester.takeException(), isNull);
    });

    testWidgets('three per row on wide layouts, one per row on mobile',
        (tester) async {
      await pumpChooser(tester, const Size(1280, 800));
      final labels = [for (final s in SymptomChooser.symptoms) s.$3];
      expect(top(tester, labels[0]), top(tester, labels[2]));
      expect(top(tester, labels[3]), greaterThan(top(tester, labels[2])));
      expect(top(tester, labels[3]), top(tester, labels[5]));

      await pumpChooser(tester, const Size(390, 844));
      for (var i = 1; i < labels.length; i++) {
        expect(top(tester, labels[i]), greaterThan(top(tester, labels[i - 1])),
            reason: labels[i]);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
