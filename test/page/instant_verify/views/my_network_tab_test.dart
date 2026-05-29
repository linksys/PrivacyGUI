import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/mock_instant_verify_pivot_notifier.dart';

// ── State factories ────────────────────────────────────────────────────────

InstantVerifyPivotState _connectedState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {
      'wanStatus': 'Connected',
      'wanConnection': {'ipAddress': '73.12.45.89', 'gateway': '73.12.0.1'},
      'detectedWANType': 'DHCP',
    },
    deviceInfo: {'modelNumber': 'MX6200', 'firmwareVersion': '1.0.6.215469'},
    routerHealth: {'uptimeInSeconds': 172800}, // 2 days
    firmwareUpdate: {'firmwareUpdateStatus': 'UpToDate'},
    clients: [],
  );
}

InstantVerifyPivotState _disconnectedState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Disconnected'},
    deviceInfo: {'modelNumber': 'MX6200'},
    routerHealth: {'uptimeInSeconds': 86400},
    clients: [],
  );
}

InstantVerifyPivotState _firmwareUpdateState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
    deviceInfo: {'modelNumber': 'MX6200', 'firmwareVersion': '1.0.6.215469'},
    routerHealth: {'uptimeInSeconds': 3600},
    firmwareUpdate: {
      'firmwareUpdateStatus': 'UpdateAvailable',
      'availableUpdate': {'firmwareVersion': '1.0.8.220100'},
    },
    clients: [],
  );
}

InstantVerifyPivotState _highUptimeState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
    deviceInfo: {'modelNumber': 'MX6200'},
    routerHealth: {'uptimeInSeconds': 2592000 + 86400}, // 31 days
    firmwareUpdate: {'firmwareUpdateStatus': 'UpToDate'},
    clients: [],
  );
}

InstantVerifyPivotState _meshState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
    deviceInfo: {'modelNumber': 'MX6200'},
    routerHealth: {'uptimeInSeconds': 3600},
    firmwareUpdate: {'firmwareUpdateStatus': 'UpToDate'},
    meshNodes: [
      MeshNodeInfo(deviceId: 'router', name: 'Router', isController: true),
      MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -55,
      ),
      MeshNodeInfo(
        deviceId: 'sat-2',
        name: 'Bedroom',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -75,
      ),
      MeshNodeInfo(
        deviceId: 'sat-3',
        name: 'Office',
        isController: false,
        backhaulType: 'Wired',
      ),
    ],
    clientToNodeId: {
      '00:00:00:00:00:01': 'router',
      '00:00:00:00:00:02': 'sat-1',
      '00:00:00:00:00:03': 'sat-1',
    },
    clients: [],
  );
}

InstantVerifyPivotState _guestEnabledState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
    deviceInfo: {'modelNumber': 'MX6200'},
    routerHealth: {'uptimeInSeconds': 3600},
    clients: [],
    guestNetwork: {
      'isGuestNetworkEnabled': true,
      'guestDeviceCount': 3,
    },
  );
}

InstantVerifyPivotState _guestDisabledState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
    deviceInfo: {'modelNumber': 'MX6200'},
    routerHealth: {'uptimeInSeconds': 3600},
    clients: [],
    guestNetwork: {
      'isGuestNetworkEnabled': false,
    },
  );
}

Widget _buildTab(InstantVerifyPivotState state) {
  final notifier = MockInstantVerifyPivotNotifier(state);
  return testableWidget(
    overrides: [
      instantVerifyPivotProvider.overrideWith(() => notifier),
    ],
    child: const MyNetworkTab(),
  );
}

void main() {
  mockDependencyRegister();

  group('MyNetworkTab — loading', () {
    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(_buildTab(
        const InstantVerifyPivotState(phase: PivotLoadPhase.loading),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('MyNetworkTab — Internet Connection', () {
    testWidgets('shows Connected status when WAN up', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('Internet Connection'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('shows connection type', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('DHCP'), findsOneWidget);
    });

    testWidgets('shows full IP address unmasked', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('73.12.45.89'), findsOneWidget);
    });

    testWidgets('shows Not Connected and restart button when WAN down',
        (tester) async {
      await tester.pumpWidget(_buildTab(_disconnectedState()));
      await tester.pumpAndSettle();
      expect(find.text('Not Connected'), findsOneWidget);
      expect(find.text('Restart Router'), findsOneWidget);
    });

    testWidgets('no restart button when connected', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      // Internet section should not show restart button
      expect(find.text('Restart Router'), findsNothing);
    });
  });

  group('MyNetworkTab — Your Router', () {
    testWidgets('shows router model', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('Your Router'), findsOneWidget);
      expect(find.text('MX6200'), findsOneWidget);
    });

    testWidgets('shows Up to date when no firmware update', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('Up to date'), findsOneWidget);
    });

    testWidgets('shows Update available with button', (tester) async {
      await tester.pumpWidget(_buildTab(_firmwareUpdateState()));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
    });

    testWidgets('shows uptime warning at 30+ days', (tester) async {
      await tester.pumpWidget(_buildTab(_highUptimeState()));
      await tester.pumpAndSettle();
      expect(find.textContaining('31 days'), findsOneWidget);
      expect(find.textContaining('restart may help'), findsOneWidget);
      expect(find.text('Restart Router'), findsOneWidget);
    });

    testWidgets('no uptime warning under 30 days', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.textContaining('restart may help'), findsNothing);
    });
  });

  group('MyNetworkTab — Satellite Nodes', () {
    testWidgets('not shown for single router', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('Your Child Nodes'), findsNothing);
    });

    testWidgets('shows satellite nodes in mesh', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      expect(find.text('Your Child Nodes'), findsOneWidget);
      expect(find.text('Child Node 1'), findsOneWidget);
      expect(find.text('Child Node 2'), findsOneWidget);
      expect(find.text('Child Node 3'), findsOneWidget);
    });

    testWidgets('shows backhaul quality labels', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // sat-1: -55 = Good wireless, sat-2: -75 = Weak wireless, sat-3: Wired
      expect(find.textContaining('Good'), findsAtLeast(1));
      expect(find.textContaining('Weak'), findsAtLeast(1));
      expect(find.text('Connected by Ethernet'), findsOneWidget);
    });

    testWidgets('weak backhaul shows move advice', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('weak connection to your router'), findsOneWidget);
    });

    testWidgets('shows device count per node', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // sat-1 has 2 devices, others have 0
      expect(find.text('2 devices connected'), findsOneWidget);
      expect(find.text('0 devices connected'), findsAtLeast(1));
    });

    testWidgets('backhaul speed shown when available', (tester) async {
      final state = const InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        wanStatus: {'wanStatus': 'Connected', 'wanConnection': {'ipAddress': '10.0.0.1'}},
        deviceInfo: {'modelNumber': 'MX6200'},
        routerHealth: {'uptimeInSeconds': 3600},
        firmwareUpdate: {'firmwareUpdateStatus': 'UpToDate'},
        meshNodes: [
          MeshNodeInfo(deviceId: 'router', name: 'Router', isController: true),
          MeshNodeInfo(
            deviceId: 'sat-1',
            name: 'Living Room',
            isController: false,
            backhaulType: 'Wireless',
            backhaulRssi: -55,
            backhaulSpeedMbps: 350,
          ),
        ],
        clients: [],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.textContaining('350 Mbps'), findsAtLeast(1));
    });
  });

  group('MyNetworkTab — WiFi Overview', () {
    testWidgets('shows WiFi Overview section', (tester) async {
      await tester.pumpWidget(_buildTab(_connectedState()));
      await tester.pumpAndSettle();
      expect(find.text('WiFi Overview'), findsOneWidget);
    });
  });

  group('MyNetworkTab — Guest Network', () {
    testWidgets('shows guest toggle enabled with device count',
        (tester) async {
      await tester.pumpWidget(_buildTab(_guestEnabledState()));
      await tester.pumpAndSettle();
      expect(find.text('Guest Network'), findsOneWidget);
      expect(find.text('3 guest devices connected'), findsOneWidget);
    });

    testWidgets('guest card hidden when disabled', (tester) async {
      await tester.pumpWidget(_buildTab(_guestDisabledState()));
      await tester.pumpAndSettle();
      // When guest network is disabled, the entire card is hidden
      expect(find.text('Guest Network'), findsNothing);
    });

    testWidgets('shows confirmation dialog when disabling', (tester) async {
      await tester.pumpWidget(_buildTab(_guestEnabledState()));
      await tester.pumpAndSettle();
      // Find the Switch and tap it to disable
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.text('Turn off guest network?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Turn Off'), findsOneWidget);
    });

    testWidgets('cancel dismisses dialog without change', (tester) async {
      await tester.pumpWidget(_buildTab(_guestEnabledState()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Turn off guest network?'), findsNothing);
    });
  });
}
