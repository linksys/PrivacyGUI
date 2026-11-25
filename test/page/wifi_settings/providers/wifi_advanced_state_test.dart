// The Advanced tab holds the settings it loaded and calls itself changed while
// the settings it shows differ from them.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';

const _loaded = WifiAdvancedSettingsState(
  isIptvEnabled: false,
  isClientSteeringEnabled: true,
  isNodesSteeringEnabled: false,
  isMLOEnabled: true,
  isDFSEnabled: false,
  isAirtimeFairnessEnabled: true,
);

void main() {
  // Built at run time, as a fetch builds it, so that the comparison goes
  // through props and not through one canonical const instance.
  test('the same settings read twice are unchanged', () {
    final readAgain = const WifiAdvancedSettingsState().copyWith(
      isIptvEnabled: false,
      isClientSteeringEnabled: true,
      isNodesSteeringEnabled: false,
      isMLOEnabled: true,
      isDFSEnabled: false,
      isAirtimeFairnessEnabled: true,
    );

    expect(readAgain, isNot(same(_loaded)));
    expect(readAgain, _loaded);
  });

  test('a change to any switch is a change', () {
    final edits = [
      _loaded.copyWith(isIptvEnabled: true),
      _loaded.copyWith(isClientSteeringEnabled: false),
      _loaded.copyWith(isNodesSteeringEnabled: true),
      _loaded.copyWith(isMLOEnabled: false),
      _loaded.copyWith(isDFSEnabled: true),
      _loaded.copyWith(isAirtimeFairnessEnabled: false),
    ];

    for (final edited in edits) {
      expect(edited, isNot(_loaded));
    }
  });

  test('a change to one switch keeps the others', () {
    expect(
      _loaded.copyWith(isDFSEnabled: true),
      const WifiAdvancedSettingsState(
        isIptvEnabled: false,
        isClientSteeringEnabled: true,
        isNodesSteeringEnabled: false,
        isMLOEnabled: true,
        isDFSEnabled: true,
        isAirtimeFairnessEnabled: true,
      ),
    );
  });
}
