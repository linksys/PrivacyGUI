import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

void main() {
  group('NodeDetailState', () {
    group('copyWith', () {
      test('returns same state when no arguments provided', () {
        const state = NodeDetailState(
          deviceId: 'device-1',
          location: 'Living Room',
          isMaster: true,
          isOnline: true,
          signalStrength: -50,
        );

        final copied = state.copyWith();

        expect(copied, state);
        expect(copied.deviceId, 'device-1');
        expect(copied.location, 'Living Room');
        expect(copied.isMaster, true);
      });

      test('updates only specified fields', () {
        const state = NodeDetailState(
          deviceId: 'device-1',
          location: 'Living Room',
          isMaster: false,
          isOnline: true,
          signalStrength: -50,
          modelNumber: 'MR7500',
        );

        final copied = state.copyWith(
          location: 'Bedroom',
          signalStrength: -60,
        );

        expect(copied.deviceId, 'device-1');
        expect(copied.location, 'Bedroom');
        expect(copied.isMaster, false);
        expect(copied.signalStrength, -60);
        expect(copied.modelNumber, 'MR7500');
      });

      test('updates blinkingStatus correctly', () {
        const state = NodeDetailState(
          blinkingStatus: BlinkingStatus.blinkNode,
        );

        final blinking =
            state.copyWith(blinkingStatus: BlinkingStatus.blinking);
        final stopBlinking =
            state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);

        expect(blinking.blinkingStatus, BlinkingStatus.blinking);
        expect(stopBlinking.blinkingStatus, BlinkingStatus.stopBlinking);
      });

      test('updates connectedDevices correctly', () {
        const state = NodeDetailState(connectedDevices: []);

        final devices = [
          const DeviceListItem(
            deviceId: 'client-1',
            name: 'iPhone',
            icon: '',
            isOnline: true,
            macAddress: 'AA:BB:CC:DD:EE:FF',
          ),
        ];

        final copied = state.copyWith(connectedDevices: devices);

        expect(copied.connectedDevices.length, 1);
        expect(copied.connectedDevices.first.deviceId, 'client-1');
      });
    });

    group('equality', () {
      test('two states with same values are equal', () {
        const state1 = NodeDetailState(
          deviceId: 'device-1',
          location: 'Living Room',
          isMaster: true,
          isOnline: true,
          signalStrength: -50,
          modelNumber: 'MR7500',
        );

        const state2 = NodeDetailState(
          deviceId: 'device-1',
          location: 'Living Room',
          isMaster: true,
          isOnline: true,
          signalStrength: -50,
          modelNumber: 'MR7500',
        );

        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('two states with different values are not equal', () {
        const state1 = NodeDetailState(
          deviceId: 'device-1',
          location: 'Living Room',
        );

        const state2 = NodeDetailState(
          deviceId: 'device-2',
          location: 'Living Room',
        );

        expect(state1, isNot(state2));
      });

      test('default state equals another default state', () {
        const state1 = NodeDetailState();
        const state2 = NodeDetailState();

        expect(state1, state2);
      });
    });

    group('toJson/fromJson', () {
      test('serializes and deserializes correctly', () {
        const state = NodeDetailState(
          deviceId: 'device-123',
          location: 'Office',
          isMaster: false,
          isOnline: true,
          upstreamDevice: 'Main Router',
          isWiredConnection: false,
          signalStrength: -45,
          serialNumber: 'SN12345',
          modelNumber: 'MBE7000',
          firmwareVersion: '2.1.0',
          hardwareVersion: '1',
          lanIpAddress: '192.168.1.50',
          wanIpAddress: '100.0.0.1',
          blinkingStatus: BlinkingStatus.blinkNode,
          isMLO: true,
          macAddress: 'AA:BB:CC:DD:EE:FF',
        );

        final json = state.toJson();
        final restored = NodeDetailState.fromJson(json);

        expect(restored.deviceId, state.deviceId);
        expect(restored.location, state.location);
        expect(restored.isMaster, state.isMaster);
        expect(restored.isOnline, state.isOnline);
        expect(restored.upstreamDevice, state.upstreamDevice);
        expect(restored.isWiredConnection, state.isWiredConnection);
        expect(restored.signalStrength, state.signalStrength);
        expect(restored.serialNumber, state.serialNumber);
        expect(restored.modelNumber, state.modelNumber);
        expect(restored.firmwareVersion, state.firmwareVersion);
        expect(restored.hardwareVersion, state.hardwareVersion);
        expect(restored.lanIpAddress, state.lanIpAddress);
        expect(restored.wanIpAddress, state.wanIpAddress);
        expect(restored.blinkingStatus, state.blinkingStatus);
        expect(restored.isMLO, state.isMLO);
        expect(restored.macAddress, state.macAddress);
      });

      test('serializes connectedDevices correctly', () {
        const state = NodeDetailState(
          deviceId: 'device-1',
          connectedDevices: [
            DeviceListItem(
              deviceId: 'client-1',
              name: 'iPhone',
              icon: 'phone',
              isOnline: true,
              macAddress: 'AA:BB:CC:DD:EE:FF',
            ),
            DeviceListItem(
              deviceId: 'client-2',
              name: 'iPad',
              icon: 'tablet',
              isOnline: false,
              macAddress: '11:22:33:44:55:66',
            ),
          ],
        );

        final json = state.toJson();
        final restored = NodeDetailState.fromJson(json);

        expect(restored.connectedDevices.length, 2);
        expect(restored.connectedDevices[0].deviceId, 'client-1');
        expect(restored.connectedDevices[0].name, 'iPhone');
        expect(restored.connectedDevices[1].deviceId, 'client-2');
        expect(restored.connectedDevices[1].name, 'iPad');
      });

      test('toMap produces expected structure', () {
        const state = NodeDetailState(
          deviceId: 'test-device',
          location: 'Test Location',
          isMaster: true,
          blinkingStatus: BlinkingStatus.stopBlinking,
        );

        final map = state.toMap();

        expect(map['deviceId'], 'test-device');
        expect(map['location'], 'Test Location');
        expect(map['isMaster'], true);
        expect(map['blinkingStatus'], 'Stop Blink');
      });
    });

    group('BlinkingStatus', () {
      test('resolve returns correct status for known values', () {
        expect(BlinkingStatus.resolve('Blink Node'), BlinkingStatus.blinkNode);
        expect(BlinkingStatus.resolve('Blinking'), BlinkingStatus.blinking);
        expect(
            BlinkingStatus.resolve('Stop Blink'), BlinkingStatus.stopBlinking);
      });

      test('resolve returns stopBlinking for unknown values', () {
        expect(BlinkingStatus.resolve('Unknown'), BlinkingStatus.stopBlinking);
        expect(BlinkingStatus.resolve(''), BlinkingStatus.stopBlinking);
      });

      test('value property returns correct string', () {
        expect(BlinkingStatus.blinkNode.value, 'Blink Node');
        expect(BlinkingStatus.blinking.value, 'Blinking');
        expect(BlinkingStatus.stopBlinking.value, 'Stop Blink');
      });
    });

    group('default values', () {
      test('has correct default values', () {
        const state = NodeDetailState();

        expect(state.deviceId, '');
        expect(state.location, '');
        expect(state.isMaster, false);
        expect(state.isOnline, false);
        expect(state.connectedDevices, isEmpty);
        expect(state.upstreamDevice, '');
        expect(state.isWiredConnection, false);
        expect(state.signalStrength, 0);
        expect(state.serialNumber, '');
        expect(state.modelNumber, '');
        expect(state.firmwareVersion, '');
        expect(state.hardwareVersion, '');
        expect(state.lanIpAddress, '');
        expect(state.wanIpAddress, '');
        expect(state.blinkingStatus, BlinkingStatus.blinkNode);
        expect(state.isMLO, false);
        expect(state.macAddress, '');
      });
    });
  });
}
