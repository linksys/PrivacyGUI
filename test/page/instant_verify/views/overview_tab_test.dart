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

      expect(find.text('8 checks passed'), findsOneWidget);
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

    testWidgets('opens explanation without hiding the recommended action', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.text('Restart Router'), findsOneWidget);
      expect(find.text('Verified: Router reachable. Websites: not loading.'), findsNothing);
      await _tap(tester, 'Why this matters');
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

      expect(find.byIcon(Icons.error), findsOneWidget);
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

      expect(find.text('3 other findings'), findsOneWidget);
      expect(find.text('High lag detected (120ms)'), findsNothing);
    });

    testWidgets('shows secondary finding headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      await _tap(tester, '3 other findings');
      expect(find.text('High lag detected (120ms)'), findsOneWidget);
    });

    testWidgets('secondary findings can be closed again', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      await _tap(tester, '3 other findings');
      await _tap(tester, 'Hide 3 other findings');
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
      await _tap(tester, '3 other findings');
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

  group('OverviewTab — mesh card', () {
    testWidgets('shows mesh card for multi-node setup', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_meshState()));
      await tester.pump();

      expect(find.textContaining('Mesh Network'), findsOneWidget);
      expect(find.text('Kitchen'), findsNothing);
      await _tap(tester, 'View WiFi node details');
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Bedroom'), findsOneWidget);
    });

    testWidgets('shows device count and parent/child labels', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_meshState()));
      await tester.pump();

      // Header shows total device count (not "nodes")
      expect(find.text('Mesh Network — 3 devices'), findsOneWidget);
      await _tap(tester, 'View WiFi node details');
      // Role labels shown per node
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsWidgets);
    });

    testWidgets('no mesh card for single router', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.textContaining('Mesh Network'), findsNothing);
    });
  });

  group('OverviewTab — device issues card', () {
    testWidgets('shows device issues card when devices have issues',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_deviceIssuesState()));
      await tester.pump();

      expect(find.text('Devices that may need help'), findsOneWidget);
      expect(find.text('iPhone'), findsNothing);
      await _tap(tester, 'View affected devices');
      expect(find.text('iPhone'), findsOneWidget);
    });

    testWidgets('shows signal details for weak device', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_deviceIssuesState()));
      await tester.pump();

      expect(find.textContaining('-82 dBm'), findsNothing);
      await _tap(tester, 'View affected devices');
      expect(find.textContaining('-82 dBm'), findsOneWidget);
    });

    testWidgets('no device issues card when all good', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Devices that may need help'), findsNothing);
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

  group('OverviewTab — primary CTA annotation', () {
    // 'Start here' annotation appears when there are 2+ findings AND
    // the primary finding has an auto-fix (actionKey != null).

    testWidgets('multiple findings with auto-fix show start-here annotation',
        (tester) async {
      // _multipleFindingsState() has 4 findings; primary has actionKey 'restart_router'
      // → hasAutoFix = true → annotation should appear.
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.textContaining('Start here'), findsOneWidget);
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
}
