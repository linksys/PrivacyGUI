import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';

const _state = DMZSettingsState(
  settings: DMZSettings(
    isDMZEnabled: true,
    destinationMACAddress: 'AA:BB:CC:DD:EE:01',
  ),
  sourceType: DMZSourceType.auto,
  destinationType: DMZDestinationType.mac,
);

void main() {
  test('names the source and destination types by their enum names', () {
    expect(DMZSourceType.resolve('range'), DMZSourceType.range);
    expect(DMZDestinationType.resolve('ip'), DMZDestinationType.ip);
    expect(_state.toMap()['sourceType'], 'auto');
    expect(_state.toMap()['destinationType'], 'mac');
  });

  test('survives a trip through JSON text', () {
    expect(DMZSettingsState.fromJson(_state.toJson()), _state);
  });

  test('copyWith changes only what it names', () {
    final changed = _state.copyWith(sourceType: DMZSourceType.range);

    expect(changed.sourceType, DMZSourceType.range);
    expect(changed.copyWith(sourceType: DMZSourceType.auto), _state);
  });
}
