import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';

void main() {
  group('WifiAdvancedSettingsState', () {
    test('creates instance with default null values', () {
      const state = WifiAdvancedSettingsState();
      expect(state.isIptvEnabled, isNull);
      expect(state.isClientSteeringEnabled, isNull);
      expect(state.isNodesSteeringEnabled, isNull);
      expect(state.isMLOEnabled, isNull);
      expect(state.isDFSEnabled, isNull);
      expect(state.isAirtimeFairnessEnabled, isNull);
    });

    test('creates instance with custom values', () {
      const state = WifiAdvancedSettingsState(
        isIptvEnabled: true,
        isClientSteeringEnabled: true,
        isNodesSteeringEnabled: false,
        isMLOEnabled: true,
        isDFSEnabled: false,
        isAirtimeFairnessEnabled: true,
      );
      expect(state.isIptvEnabled, true);
      expect(state.isClientSteeringEnabled, true);
      expect(state.isMLOEnabled, true);
      expect(state.isDFSEnabled, false);
    });

    test('copyWith updates specified fields', () {
      const original = WifiAdvancedSettingsState();
      final copied = original.copyWith(
        isIptvEnabled: true,
        isDFSEnabled: true,
      );
      expect(copied.isIptvEnabled, true);
      expect(copied.isDFSEnabled, true);
      expect(copied.isClientSteeringEnabled, isNull);
    });

    test('toMap converts to map correctly', () {
      const state = WifiAdvancedSettingsState(
        isIptvEnabled: true,
        isClientSteeringEnabled: false,
        isNodesSteeringEnabled: true,
        isMLOEnabled: false,
      );
      final map = state.toMap();
      expect(map['isIptvEnabled'], true);
      expect(map['isNodesSteeringEnabled'], true);
      expect(map['isMLOEnabled'], false);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'isIptvEnabled': true,
        'isClientSteeringEnabled': true,
        'isNodesSteeringEnabled': false,
        'isMLOEnabled': true,
        'isDFSEnabled': false,
        'isAirtimeFairnessEnabled': true,
      };
      final state = WifiAdvancedSettingsState.fromMap(map);
      expect(state.isIptvEnabled, true);
      expect(state.isMLOEnabled, true);
      expect(state.isDFSEnabled, false);
    });

    test('fromMap handles null values', () {
      final state = WifiAdvancedSettingsState.fromMap(<String, dynamic>{});
      expect(state.isIptvEnabled, isNull);
      expect(state.isMLOEnabled, isNull);
    });

    test('toJson/fromJson round-trip works', () {
      const original = WifiAdvancedSettingsState(
        isIptvEnabled: true,
        isClientSteeringEnabled: true,
        isNodesSteeringEnabled: true,
      );
      final json = original.toJson();
      final restored = WifiAdvancedSettingsState.fromJson(json);
      expect(restored.isIptvEnabled, true);
      expect(restored.isClientSteeringEnabled, true);
    });

    test('equality comparison works', () {
      const state1 = WifiAdvancedSettingsState(isIptvEnabled: true);
      const state2 = WifiAdvancedSettingsState(isIptvEnabled: true);
      expect(state1, state2);
    });

    test('distinguishes different states', () {
      const state1 = WifiAdvancedSettingsState(isIptvEnabled: true);
      const state2 = WifiAdvancedSettingsState(isIptvEnabled: false);
      expect(state1, isNot(state2));
    });

    test('stringify returns true', () {
      const state = WifiAdvancedSettingsState();
      expect(state.stringify, true);
    });

    test('props contains all fields', () {
      const state = WifiAdvancedSettingsState();
      expect(state.props, hasLength(6));
    });
  });
}
