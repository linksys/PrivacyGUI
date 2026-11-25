import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

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
}
