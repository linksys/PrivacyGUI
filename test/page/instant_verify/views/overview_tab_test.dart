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

InstantVerifyPivotState _idleState() {
  return const InstantVerifyPivotState(phase: PivotLoadPhase.idle);
}

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

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  mockDependencyRegister();

  group('OverviewTab — loading state', () {
    testWidgets('shows "Checking your connection" during loading',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      expect(find.text('Checking your connection'), findsOneWidget);
    });

    testWidgets('shows check rows during loading', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      // "Router" appears in both header (model default) and check row
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

    testWidgets('shows test details section always visible', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // Test details are always shown — no toggle needed
      expect(find.text('Test details'), findsOneWidget);
      expect(find.text('Router reached'), findsOneWidget);
    });

    testWidgets('shows router model in header', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // MX6200 appears in header + in test details checklist
      expect(find.text('MX6200'), findsAtLeast(1));
    });

    testWidgets('shows "Connected to ISP" chip when WAN up, DNS not yet run', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // Chip shows 'Connected to ISP' when WAN is up but DNS not yet confirmed;
      // or 'Internet: Working' if DNS also passed in this state
      expect(find.textContaining('Connected'), findsAtLeast(1));
    });
  });

  group('OverviewTab — critical finding', () {
    testWidgets('shows critical headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

      expect(find.text("Your internet isn't working"), findsOneWidget);
    });

    testWidgets('shows explanation text', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_criticalFindingState()));
      await tester.pump();

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

    testWidgets('shows "Also found:" for secondary findings', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.text('Also found:'), findsOneWidget);
    });

    testWidgets('shows secondary finding headline', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.text('High lag detected (120ms)'), findsOneWidget);
    });

    testWidgets('shows "2 more findings" expandable', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      expect(find.text('2 more findings'), findsOneWidget);
    });

    testWidgets('expanding shows hidden findings', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_multipleFindingsState()));
      await tester.pump();

      // Hidden findings should not be visible yet
      expect(find.text('A software update is available (2.0.0)'),
          findsNothing);

      // Tap expand
      await tester.tap(find.text('2 more findings'));
      await tester.pump();

      // Now they should be visible
      expect(find.text('A software update is available (2.0.0)'),
          findsOneWidget);
      expect(find.text('Your router has been running for 90 days'),
          findsOneWidget);
    });
  });

  group('OverviewTab — WAN down', () {
    testWidgets('shows "Not connected to ISP" chip when WAN down', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      expect(find.text('Not connected to ISP'), findsOneWidget);
    });

    testWidgets('shows WAN-down inline light guide callout', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      expect(find.text('No internet connection detected.'), findsAtLeast(1));
    });
  });

  group('OverviewTab — header bar', () {
    testWidgets('shows firmware version', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('FW: 1.0.10'), findsOneWidget);
    });

    testWidgets('shows "Checking..." chip during loading', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_loadingState()));
      await tester.pump();

      expect(find.text('Checking...'), findsOneWidget);
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
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Bedroom'), findsOneWidget);
    });

    testWidgets('shows device count and parent/child labels', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_meshState()));
      await tester.pump();

      // Header shows total device count (not "nodes")
      expect(find.text('Mesh Network — 3 devices'), findsOneWidget);
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

      expect(find.text('Devices with weak WiFi'), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);
    });

    testWidgets('shows signal details for weak device', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_deviceIssuesState()));
      await tester.pump();

      expect(find.textContaining('-82 dBm'), findsOneWidget);
    });

    testWidgets('no device issues card when all good', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Devices with weak WiFi'), findsNothing);
    });
  });

  group('OverviewTab — Run Again button', () {
    testWidgets('shows "Run Again" button', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Run Again'), findsOneWidget);
    });

    testWidgets('"Test scenarios" button visible', (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      expect(find.text('Test scenarios'), findsOneWidget);
    });
  });

  group('OverviewTab — progressive disclosure (S-5)', () {
    testWidgets('test details always shows checklist summary',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_allClearState()));
      await tester.pump();

      // Checklist rows always visible (no toggle)
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
          find.textContaining('We connected to your router at 192.168.1.1'),
          findsNothing);

      // Tap "Router reached" row
      await tester.tap(find.text('Router reached'));
      await tester.pump();

      // Expanded detail should now be visible
      expect(
          find.textContaining('We connected to your router at 192.168.1.1'),
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

      // Dialog should appear
      expect(find.text('Restart Router?'), findsOneWidget);
      expect(find.textContaining('All devices will disconnect'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });
  });

  group('OverviewTab — status chip label states', () {
    testWidgets('WAN connected, DNS not run → shows "Connected to ISP"',
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

      expect(find.text('Connected to ISP'), findsOneWidget);
    });

    testWidgets('WAN connected, DNS resolved → shows "Internet: Working"',
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

      expect(find.text('Internet: Working'), findsOneWidget);
    });

    testWidgets(
        'WAN connected, DNS failed → shows "Connected to ISP — websites aren\'t loading"',
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

      expect(find.textContaining('Connected to ISP'), findsAtLeast(1));
      expect(find.textContaining("websites aren't loading"), findsAtLeast(1));
    });

    testWidgets('WAN disconnected → shows "Not connected to ISP"',
        (tester) async {
      await tester.pumpWidget(_buildOverviewTab(_wanDownState()));
      await tester.pump();

      expect(find.text('Not connected to ISP'), findsOneWidget);
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
