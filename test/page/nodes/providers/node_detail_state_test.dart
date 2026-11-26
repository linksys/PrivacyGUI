import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

import '../../../test_data/node_details_data.dart';

void main() {
  group('NodeLightStatus.getStatus', () {
    test('reads a light the router has not reported as off', () {
      expect(NodeLightStatus.getStatus(null), NodeLightStatus.off);
    });

    test('reads night mode from 0 to 24 as off', () {
      expect(
        NodeLightStatus.getStatus(const NodeLightSettings(
            isNightModeEnable: true, startHour: 0, endHour: 24)),
        NodeLightStatus.off,
      );
    });

    test('reads a light off all day as off, whatever its hours', () {
      expect(
        NodeLightStatus.getStatus(
            const NodeLightSettings(isNightModeEnable: false, allDayOff: true)),
        NodeLightStatus.off,
      );
    });

    test('reads night mode off as on', () {
      expect(
        NodeLightStatus.getStatus(
            const NodeLightSettings(isNightModeEnable: false)),
        NodeLightStatus.on,
      );
    });

    test('reads night mode for part of the day as night', () {
      expect(
        NodeLightStatus.getStatus(const NodeLightSettings(
            isNightModeEnable: true, startHour: 20, endHour: 8)),
        NodeLightStatus.night,
      );
    });
  });

  test('an edit to the blink keeps the node it is for', () {
    const state = NodeDetailState(deviceId: 'bedroom', location: 'Bedroom');

    final blinking = state.copyWith(blinkingStatus: BlinkingStatus.blinking);

    expect(blinking.deviceId, 'bedroom');
    expect(blinking.location, 'Bedroom');
    expect(blinking.blinkingStatus, BlinkingStatus.blinking);
  });

  test('reads each blink status by its label, and anything else as stop', () {
    expect(BlinkingStatus.resolve('Blink Node'), BlinkingStatus.blinkNode);
    expect(BlinkingStatus.resolve('Blinking'), BlinkingStatus.blinking);
    expect(BlinkingStatus.resolve('Stop Blink'), BlinkingStatus.stopBlinking);
    expect(BlinkingStatus.resolve('blinking'), BlinkingStatus.stopBlinking);
  });

  group('as a map', () {
    test('reads the node as the test data writes it', () {
      final state = NodeDetailState.fromMap(nodeDetailsCherry7TestState);

      expect(state.deviceId, '6c73112b-b6d1-4bfd-9a8c-80691abb46cc');
      expect(state.isMaster, isTrue);
      expect(state.modelNumber, 'LN16');
      expect(state.serialNumber, '65G10M27E03041');
      expect(state.blinkingStatus, BlinkingStatus.blinkNode);
      expect(state.connectedDevices.first.name, 'ASTWP-29134');
    });

    test('writes back the map it was read from, and reads its JSON back', () {
      final state = NodeDetailState.fromMap(nodeDetailsCherry7TestState);

      expect(state.toMap(), nodeDetailsCherry7TestState);
      expect(NodeDetailState.fromJson(state.toJson()), state);
    });

    test('writes and reads each blink status', () {
      final state = NodeDetailState.fromMap(nodeDetailsCherry7TestState);

      for (final status in BlinkingStatus.values) {
        final blinking = state.copyWith(blinkingStatus: status);

        expect(
            NodeDetailState.fromJson(blinking.toJson()).blinkingStatus, status);
      }
    });

    test('reads a node written before MLO as not MLO', () {
      final state = NodeDetailState.fromMap(
          Map.of(nodeDetailsCherry7TestState)..remove('isMLO'));

      expect(state.isMLO, isFalse);
    });
  });

  test('a node read twice is the same node; a change to any field is not', () {
    final state = NodeDetailState.fromMap(nodeDetailsCherry7TestState);

    expect(NodeDetailState.fromMap(nodeDetailsCherry7TestState), state);
    final edits = [
      state.copyWith(deviceId: 'other'),
      state.copyWith(location: 'other'),
      state.copyWith(isMaster: false),
      state.copyWith(isOnline: false),
      state.copyWith(connectedDevices: []),
      state.copyWith(upstreamDevice: 'other'),
      state.copyWith(isWiredConnection: false),
      state.copyWith(signalStrength: -70),
      state.copyWith(serialNumber: 'other'),
      state.copyWith(modelNumber: 'other'),
      state.copyWith(firmwareVersion: 'other'),
      state.copyWith(hardwareVersion: 'other'),
      state.copyWith(lanIpAddress: 'other'),
      state.copyWith(wanIpAddress: 'other'),
      state.copyWith(blinkingStatus: BlinkingStatus.blinking),
      state.copyWith(isMLO: true),
      state.copyWith(macAddress: 'other'),
    ];
    for (final edited in edits) {
      expect(edited, isNot(state));
    }
  });
}
