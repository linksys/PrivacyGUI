// The node detail page: the router or node the user picked, built from what
// the router reports in a poll, and the node's blink and rename.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../instant_device/providers/home_network_poll.dart';

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  NodeDetailNotifier notifier() => container.read(nodeDetailProvider.notifier);
  NodeDetailState page() => container.read(nodeDetailProvider);

  void open(String deviceId,
      {List<Map<String, dynamic>>? devices,
      Map<JNAPAction, Map<String, dynamic>> extra = const {}}) {
    router = RouterBoundary()
      ..holds(JNAPAction.startBlinkNodeLed, {})
      ..holds(JNAPAction.stopBlinkNodeLed, {});
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() =>
          RecordingPolling(homeNetworkPoll(devices: devices, extra: extra))),
    ]);
    addTearDown(container.dispose);
    container.read(nodeDetailIdProvider.notifier).state = deviceId;
  }

  group('the details', () {
    test('shows nothing before a node is picked', () {
      open('');

      expect(page(), const NodeDetailState());
    });

    test('the router: its place, hardware, addresses and the Internet above it',
        () {
      open('master');

      expect(page().deviceId, 'master');
      expect(page().location, 'Living Room');
      expect(page().isMaster, isTrue);
      expect(page().isOnline, isTrue);
      expect(page().upstreamDevice, 'INTERNET');
      expect(page().isWiredConnection, isTrue);
      expect(page().modelNumber, 'MX4200');
      expect(page().hardwareVersion, '1');
      expect(page().serialNumber, '59A10M21C00042');
      expect(page().firmwareVersion, '1.0.13.216019');
      expect(page().lanIpAddress, '192.168.1.1');
      expect(page().wanIpAddress, '203.0.113.7');
      expect(page().macAddress, masterMac);
    });

    test("lists the clients on the router, as the device list shows them", () {
      open('master');

      expect(page().connectedDevices.map((d) => d.name),
          unorderedEquals(['Work Laptop', 'Guest Tablet']));
      expect(
          page()
              .connectedDevices
              .singleWhere((d) => d.deviceId == 'laptop')
              .ipv4Address,
          '192.168.1.100');
    });

    test('a node: under the router, on a wireless backhaul with its signal',
        () {
      open('bedroom');

      expect(page().location, 'Bedroom');
      expect(page().isMaster, isFalse);
      expect(page().upstreamDevice, 'Living Room');
      expect(page().isWiredConnection, isFalse);
      expect(page().signalStrength, -42);
      expect(page().hardwareVersion, '2');
      expect(page().firmwareVersion, '1.0.13.216020');
      expect(page().lanIpAddress, '192.168.1.194');
      expect(page().connectedDevices.map((d) => d.deviceId), ['phone']);
      expect(page().isMLO, isFalse);
    });

    test('a node on a multi-link backhaul is marked MLO', () {
      final backhaul = backhaulInfo();
      ((backhaul['backhaulDevices'] as List).single
              as Map<String, dynamic>)['wirelessConnectionInfo']
          ['isMultiLinkOperation'] = true;
      open('bedroom', extra: {JNAPAction.getBackhaulInfo: backhaul});

      expect(page().isMLO, isTrue);
    });

    test('an offline node is under the router, with no address', () {
      open('bedroom', devices: [masterDevice(), bedroomNode(online: false)]);

      expect(page().isOnline, isFalse);
      expect(page().upstreamDevice, 'Living Room');
      expect(page().lanIpAddress, '');
      expect(page().connectedDevices, isEmpty);
    });
  });

  group('blinking the node', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('starts the blink, then offers to stop it', (tester) async {
      open('bedroom');

      await notifier().toggleBlinkNode();
      expect(page().blinkingStatus, BlinkingStatus.blinking);
      await tester.pump();

      expect(router.payloadsOf(JNAPAction.startBlinkNodeLed).single,
          {'deviceID': 'bedroom'});
      expect(page().blinkingStatus, BlinkingStatus.stopBlinking);
      expect((await SharedPreferences.getInstance()).get(blinkingDeviceId),
          'bedroom');

      await tester.pump(const Duration(seconds: 24));
    });

    testWidgets('stops the blink by itself after 24 seconds', (tester) async {
      open('bedroom');
      await notifier().toggleBlinkNode();
      await tester.pump();

      await tester.pump(const Duration(seconds: 23));
      expect(router.actions, isNot(contains(JNAPAction.stopBlinkNodeLed)));

      await tester.pump(const Duration(seconds: 1));
      expect(router.actions.last, JNAPAction.stopBlinkNodeLed);
      expect(page().blinkingStatus, BlinkingStatus.blinkNode);
    });

    testWidgets('a second toggle stops the blink and forgets it',
        (tester) async {
      open('bedroom');
      await notifier().toggleBlinkNode();
      await tester.pump();

      await notifier().toggleBlinkNode();
      await tester.pump();

      expect(router.actions.last, JNAPAction.stopBlinkNodeLed);
      expect(page().blinkingStatus, BlinkingStatus.blinkNode);
      expect((await SharedPreferences.getInstance()).get(blinkingDeviceId),
          isNull);

      await tester.pump(const Duration(seconds: 24));
      expect(router.actions.where((a) => a == JNAPAction.stopBlinkNodeLed),
          hasLength(1),
          reason: 'the stop cancels the one that was due');
    });

    testWidgets('a stop-only toggle stops, whether or not a blink is on',
        (tester) async {
      open('bedroom');

      await notifier().toggleBlinkNode(true);
      await tester.pump();

      expect(router.actions, [JNAPAction.stopBlinkNodeLed]);
      expect(page().blinkingStatus, BlinkingStatus.blinkNode);
    });

    testWidgets('a refused start offers the blink again', (tester) async {
      open('bedroom');
      router.refuses(JNAPAction.startBlinkNodeLed);

      await notifier().toggleBlinkNode();
      await tester.pump();

      expect(page().blinkingStatus, BlinkingStatus.blinkNode);
      expect((await SharedPreferences.getInstance()).get(blinkingDeviceId),
          isNull);
    });

    testWidgets('a refused stop still offers to stop', (tester) async {
      open('bedroom');
      router.refuses(JNAPAction.stopBlinkNodeLed);

      await notifier().toggleBlinkNode(true);
      await tester.pump();

      expect(page().blinkingStatus, BlinkingStatus.stopBlinking);
    });
  });

  group('renaming the node', () {
    test('writes the new name as its name and its location', () async {
      open('bedroom');
      router.holds(JNAPAction.getDevices, {'revision': 31, 'devices': []});
      page();

      await notifier().updateDeviceName('Office');

      expect(router.payloadsOf(JNAPAction.setDeviceProperties).single, {
        'deviceID': 'bedroom',
        'propertiesToModify': [
          {'name': 'userDeviceName', 'value': 'Office'},
          {'name': 'userDeviceLocation', 'value': 'Office'},
        ],
      });
      expect(page().location, 'Office');
    });

    test('a refused rename reaches the caller and keeps the name', () async {
      open('bedroom');
      router.refuses(JNAPAction.setDeviceProperties);
      page();

      await expectLater(
          notifier().updateDeviceName('Office'), throwsA(isA<JNAPError>()));

      expect(page().location, 'Bedroom');
    });
  });
}
