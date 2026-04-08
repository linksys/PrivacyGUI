import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/my_devices_tab.dart';

import '../../../common/di.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/mock_instant_verify_pivot_notifier.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

DiagnosticClient _client({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? hostname,
  String band = '5GHz',
  int? signal,
  int? txRate,
  bool wireless = true,
}) {
  return DiagnosticClient(
    macAddress: mac,
    hostname: hostname,
    band: band,
    signalDecibels: signal,
    txRateMbps: txRate,
    isWireless: wireless,
  );
}

InstantVerifyPivotState _emptyCompleteState() {
  return const InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    clients: [],
  );
}

InstantVerifyPivotState _flatListState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    clients: [
      _client(mac: '00:00:00:00:00:01', hostname: "Deven's iPhone", band: '5GHz', signal: -45, txRate: 866),
      _client(mac: '00:00:00:00:00:02', hostname: 'Samsung TV', band: '2.4GHz', signal: -73, txRate: 20),
      _client(mac: '00:00:00:00:00:03', hostname: 'Desktop PC', wireless: false),
      _client(mac: '00:00:00:00:00:04', hostname: 'Old Laptop', band: '2.4GHz', signal: -80, txRate: 5),
    ],
    deviceScores: [
      DeviceScore.compute(_client(mac: '00:00:00:00:00:01', signal: -45, txRate: 866)),
      DeviceScore.compute(_client(mac: '00:00:00:00:00:02', band: '2.4GHz', signal: -73, txRate: 20)),
      DeviceScore.compute(_client(mac: '00:00:00:00:00:03', wireless: false)),
      DeviceScore.compute(_client(mac: '00:00:00:00:00:04', band: '2.4GHz', signal: -80, txRate: 5)),
    ],
  );
}

InstantVerifyPivotState _meshState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    meshNodes: const [
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
    ],
    clientToNodeId: const {
      '00:00:00:00:00:01': 'router',
      '00:00:00:00:00:02': 'router',
      '00:00:00:00:00:03': 'sat-1',
    },
    clients: [
      _client(mac: '00:00:00:00:00:01', hostname: "Deven's iPhone", signal: -45, txRate: 866),
      _client(mac: '00:00:00:00:00:02', hostname: 'Samsung TV', band: '2.4GHz', signal: -73, txRate: 20),
      _client(mac: '00:00:00:00:00:03', hostname: 'Nest Hub', signal: -50, txRate: 400),
    ],
  );
}

InstantVerifyPivotState _guestDeviceState() {
  return InstantVerifyPivotState(
    phase: PivotLoadPhase.complete,
    browserTestStep: 'complete',
    meshNodes: const [
      MeshNodeInfo(deviceId: 'router', name: 'Router', isController: true),
      MeshNodeInfo(deviceId: 'sat-1', name: 'Office', isController: false, backhaulType: 'Wired'),
    ],
    clientToNodeId: const {
      '00:00:00:00:00:01': 'router',
    },
    clients: [
      _client(mac: '00:00:00:00:00:01', hostname: "Deven's iPhone", signal: -45, txRate: 866),
      _client(mac: 'GG:GG:GG:GG:GG:01', hostname: 'Guest Phone', signal: -50, txRate: 200),
    ],
  );
}

Widget _buildTab(InstantVerifyPivotState state, {ValueChanged<int>? onNavigateToFlow}) {
  final notifier = MockInstantVerifyPivotNotifier(state);
  return testableWidget(
    overrides: [
      instantVerifyPivotProvider.overrideWith(() => notifier),
    ],
    child: MyDevicesTab(onNavigateToFlow: onNavigateToFlow),
  );
}

void main() {
  mockDependencyRegister();
  group('MyDevicesTab — loading & empty', () {
    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(_buildTab(
        const InstantVerifyPivotState(phase: PivotLoadPhase.loading),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no clients', (tester) async {
      await tester.pumpWidget(_buildTab(_emptyCompleteState()));
      await tester.pumpAndSettle();
      expect(find.textContaining('No devices found'), findsOneWidget);
    });
  });

  group('MyDevicesTab — flat device list', () {
    testWidgets('shows device count header', (tester) async {
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      expect(find.text('4 devices connected'), findsOneWidget);
      expect(find.textContaining('wireless'), findsOneWidget);
    });

    testWidgets('shows all device names', (tester) async {
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      expect(find.text("Deven's iPhone"), findsOneWidget);
      expect(find.text('Samsung TV'), findsOneWidget);
      expect(find.text('Desktop PC'), findsOneWidget);
      expect(find.text('Old Laptop'), findsOneWidget);
    });

    testWidgets('shows signal badges', (tester) async {
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      // Old Laptop: -80dBm = Poor, Samsung TV: -73dBm = Weak,
      // Deven's iPhone: -45dBm = Good, Desktop: Wired
      expect(find.text('Poor'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Wired'), findsOneWidget);
    });

    testWidgets('poor devices sorted first', (tester) async {
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();

      // Find positions of device names in the widget tree
      final poorPos = tester.getTopLeft(find.text('Old Laptop'));
      final weakPos = tester.getTopLeft(find.text('Samsung TV'));
      final goodPos = tester.getTopLeft(find.text("Deven's iPhone"));
      final wiredPos = tester.getTopLeft(find.text('Desktop PC'));

      // Poor should be above Weak, which should be above Good, then Wired
      expect(poorPos.dy, lessThan(weakPos.dy));
      expect(weakPos.dy, lessThan(goodPos.dy));
      expect(goodPos.dy, lessThan(wiredPos.dy));
    });

    testWidgets('shows band for wireless devices', (tester) async {
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      expect(find.text('5GHz'), findsOneWidget);
      expect(find.text('2.4GHz'), findsAtLeast(1));
    });
  });

  group('MyDevicesTab — mesh grouped list', () {
    testWidgets('shows node groups', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      expect(find.text('Main Router'), findsOneWidget);
      expect(find.text('Satellite Node 1'), findsOneWidget);
      expect(find.text('Satellite Node 2'), findsOneWidget);
    });

    testWidgets('shows device count per node', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      expect(find.text('2 devices'), findsAtLeast(1)); // Main Router has 2
      expect(find.text('1 device'), findsAtLeast(1)); // Satellite Node 1 has 1
    });

    testWidgets('weak backhaul node shows warning icon', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // sat-2 has backhaul RSSI -75 which is < -70 → weak
      expect(find.byIcon(Icons.warning_amber), findsAtLeast(1));
    });

    testWidgets('node with issues auto-expanded', (tester) async {
      // Samsung TV has signal -73 = Weak, so Main Router group should be expanded
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // Samsung TV visible means group is expanded
      expect(find.text('Samsung TV'), findsOneWidget);
    });

    testWidgets('empty node shows no devices message', (tester) async {
      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // sat-2 has 0 devices and weak backhaul → auto-expanded → shows empty msg
      expect(find.text('No devices connected'), findsOneWidget);
    });
  });

  group('MyDevicesTab — guest devices', () {
    testWidgets('unmapped clients grouped as Guest Devices', (tester) async {
      await tester.pumpWidget(_buildTab(_guestDeviceState()));
      await tester.pumpAndSettle();
      expect(find.text('Guest Devices'), findsOneWidget);
    });

    testWidgets('guest device name visible when group expanded', (tester) async {
      await tester.pumpWidget(_buildTab(_guestDeviceState()));
      await tester.pumpAndSettle();
      // Guest Devices group won't auto-expand (signal is good)
      // Tap to expand
      await tester.tap(find.text('Guest Devices'));
      await tester.pumpAndSettle();
      expect(find.text('Guest Phone'), findsOneWidget);
    });
  });

  group('MyDevicesTab — device detail sheet', () {
    testWidgets('tapping wireless device opens detail sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Deven's iPhone"));
      await tester.pumpAndSettle();
      expect(find.text('Signal: Good'), findsOneWidget);
      expect(find.text('This device has a strong WiFi connection.'), findsOneWidget);
    });

    testWidgets('poor signal device shows move advice', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Old Laptop'));
      await tester.pumpAndSettle();
      expect(find.text('Signal: Poor'), findsOneWidget);
      expect(find.textContaining('Move this device closer'), findsOneWidget);
    });

    testWidgets('wired device shows Ethernet checklist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Desktop PC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desktop PC'));
      await tester.pumpAndSettle();
      expect(find.text('Connected by Ethernet cable'), findsOneWidget);
      expect(find.textContaining('firmly plugged in'), findsOneWidget);
      expect(find.textContaining('different cable'), findsOneWidget);
      expect(find.textContaining('different port'), findsOneWidget);
    });

    testWidgets('2.4GHz weak device suggests 5GHz', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Samsung TV'));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 GHz'), findsAtLeast(1));
    });

    testWidgets('Troubleshoot this device calls onNavigateToFlow with 3',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(() => tester.view.resetPhysicalSize());

      int? capturedFlow;
      await tester.pumpWidget(_buildTab(
        _flatListState(),
        onNavigateToFlow: (flow) { capturedFlow = flow; },
      ));
      await tester.pumpAndSettle();

      // Open device detail sheet for the first device (sorted: Poor first → Old Laptop)
      // Use "Deven's iPhone" which is a Good-signal device in the flat list
      await tester.tap(find.text("Deven's iPhone"));
      await tester.pumpAndSettle();

      // Scroll the sheet to make 'Troubleshoot this device' visible
      await tester.ensureVisible(find.text('Troubleshoot this device'));
      await tester.pumpAndSettle();

      // Tap 'Troubleshoot this device'
      await tester.tap(find.text('Troubleshoot this device'));
      await tester.pumpAndSettle();

      expect(capturedFlow, equals(3));
    });

    testWidgets('mesh device shows node connection info', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTab(_meshState()));
      await tester.pumpAndSettle();
      // Satellite Node 1 group not auto-expanded (no issues), tap to expand
      await tester.ensureVisible(find.text('Satellite Node 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Satellite Node 1'));
      await tester.pumpAndSettle();
      // Nest Hub should now be visible
      await tester.ensureVisible(find.text('Nest Hub'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nest Hub'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Satellite Node 1'), findsAtLeast(1));
    });
  });

  group('MyDevicesTab — signal badge thresholds', () {
    testWidgets('signal -69 dBm + rate 30 = Good', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -69, txRate: 30)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('signal -70 dBm = Weak (boundary)', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -70, txRate: 50)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('signal -75 dBm = Weak (not Poor)', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -75, txRate: 50)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('signal -76 dBm = Poor', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -76, txRate: 50)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Poor'), findsOneWidget);
    });

    testWidgets('good signal but rate < 10 = Poor', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -50, txRate: 5)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Poor'), findsOneWidget);
    });

    testWidgets('good signal but rate 20 = Weak', (tester) async {
      final state = InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [_client(mac: '00:00:00:00:00:01', hostname: 'Test', signal: -50, txRate: 20)],
      );
      await tester.pumpWidget(_buildTab(state));
      await tester.pumpAndSettle();
      expect(find.text('Weak'), findsOneWidget);
    });
  });

  group('MyDevicesTab — disconnect/reconnect handler', () {
    Future<void> _openWeakDeviceSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      // Old Laptop has signal -80 = Poor → weak, so disconnect button should show
      await tester.tap(find.text('Old Laptop'));
      await tester.pumpAndSettle();
    }

    testWidgets('disconnect button visible for wireless weak device', (tester) async {
      await _openWeakDeviceSheet(tester);
      expect(find.text('Disconnect and reconnect this device'), findsOneWidget);
    });

    testWidgets('disconnect button shows confirmation dialog', (tester) async {
      await _openWeakDeviceSheet(tester);
      await tester.ensureVisible(find.text('Disconnect and reconnect this device'));
      await tester.tap(find.text('Disconnect and reconnect this device'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect this device?'), findsOneWidget);
      expect(find.textContaining('briefly disconnect'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);
    });

    testWidgets('cancel dismisses disconnect dialog', (tester) async {
      await _openWeakDeviceSheet(tester);
      await tester.ensureVisible(find.text('Disconnect and reconnect this device'));
      await tester.tap(find.text('Disconnect and reconnect this device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect this device?'), findsNothing);
    });

    testWidgets('disconnect button not shown for wired device', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Desktop PC'));
      await tester.tap(find.text('Desktop PC'));
      await tester.pumpAndSettle();
      // Wired device — no disconnect button
      expect(find.text('Disconnect and reconnect this device'), findsNothing);
    });
  });

  group('MyDevicesTab — channel change handler', () {
    InstantVerifyPivotState _stateWithChannelData() {
      return InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        browserTestStep: 'complete',
        clients: [
          _client(mac: '00:00:00:00:00:01', hostname: 'Weak Device',
              band: '2.4GHz', signal: -80, txRate: 5),
        ],
        channelInfo: const {
          'selectedChannels': [
            {
              'deviceID': 'router-1',
              'channels': [
                {'radioID': 'RADIO_2.4GHz', 'band': '2.4GHz', 'channel': 13},
                {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'channel': 36},
              ],
            }
          ],
        },
      );
    }

    testWidgets('channel change button visible for weak wireless device with channel data',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTab(_stateWithChannelData()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weak Device'));
      await tester.pumpAndSettle();
      expect(find.text('Try a cleaner WiFi channel'), findsOneWidget);
    });

    testWidgets('channel change shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTab(_stateWithChannelData()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weak Device'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Try a cleaner WiFi channel'));
      await tester.tap(find.text('Try a cleaner WiFi channel'));
      await tester.pumpAndSettle();
      expect(find.text('Change WiFi channel?'), findsOneWidget);
      expect(find.textContaining('briefly disconnect and reconnect'), findsOneWidget);
    });

    testWidgets('channel change not shown without channel data', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // _flatListState has no channelInfo
      await tester.pumpWidget(_buildTab(_flatListState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Old Laptop'));
      await tester.pumpAndSettle();
      expect(find.text('Try a cleaner WiFi channel'), findsNothing);
    });
  });
}
