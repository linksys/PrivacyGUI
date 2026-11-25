import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

/// `GetLedNightModeSetting` output as JSON text: the light off from 20:00 to
/// 08:00.
const _nightText = '{"Enable": true, "StartingTime": 20, "EndingTime": 8}';

void main() {
  test('reads night mode and its hours', () {
    final settings = NodeLightSettings.fromJson(_nightText);

    expect(settings.isNightModeEnable, isTrue);
    expect((settings.startHour, settings.endHour), (20, 8));
    expect(settings.allDayOff, isNull);
  });

  test('reads a router that keeps the light off all day', () {
    final settings = NodeLightSettings.fromMap(const {
      'Enable': true,
      'StartingTime': 0,
      'EndingTime': 24,
      'AllDayOff': true,
    });

    expect(settings.allDayOff, isTrue);
  });

  test(
      'writes the router\'s names, leaving out the hours the light on needs '
      'none of', () {
    expect(NodeLightSettings.fromJson(_nightText).toMap(),
        {'Enable': true, 'StartingTime': 20, 'EndingTime': 8});
    expect(NodeLightSettings.on().toMap(), {'Enable': false});
  });

  test('survives a trip through JSON text', () {
    final settings = NodeLightSettings.fromJson(_nightText);

    expect(NodeLightSettings.fromJson(settings.toJson()), settings);
  });

  test('turns each light setting the user picks into the router\'s hours', () {
    expect(NodeLightSettings.fromStatus(NodeLightStatus.on),
        const NodeLightSettings(isNightModeEnable: false));
    expect(
        NodeLightSettings.fromStatus(NodeLightStatus.night),
        const NodeLightSettings(
            isNightModeEnable: true, startHour: 20, endHour: 8));
    expect(
        NodeLightSettings.fromStatus(NodeLightStatus.off),
        const NodeLightSettings(
            isNightModeEnable: true, startHour: 0, endHour: 24));
  });

  test('copyWith changes only what it names', () {
    final settings = NodeLightSettings.night();

    final later = settings.copyWith(startHour: 22, allDayOff: false);

    expect((later.startHour, later.endHour, later.allDayOff), (22, 8, false));
    expect(later.isNightModeEnable, isTrue);
    expect(later, isNot(settings));
  });
}
