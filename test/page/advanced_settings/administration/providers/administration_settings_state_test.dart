import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('AdministrationSettings', () {
    /// Test basic construction
    test('constructs with all required fields', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
        canDisAllowLocalMangementWirelessly: true,
      );

      expect(settings.managementSettings, managementSettings);
      expect(settings.enabledALG, false);
      expect(settings.isExpressForwardingSupported, true);
      expect(settings.enabledExpressForwarfing, false);
      expect(settings.isUPnPEnabled, true);
      expect(settings.canUsersConfigure, false);
      expect(settings.canUsersDisableWANAccess, true);
      expect(settings.canDisAllowLocalMangementWirelessly, true);
    });

    /// Test default value for canDisAllowLocalMangementWirelessly
    test('has default value for canDisAllowLocalMangementWirelessly', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: false,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: false,
        canManageRemotely: false,
      );

      const settings = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: false,
        enabledExpressForwarfing: false,
        isUPnPEnabled: false,
        canUsersConfigure: false,
        canUsersDisableWANAccess: false,
      );

      expect(settings.canDisAllowLocalMangementWirelessly, true);
    });

    /// Test copyWith creates new instance with updated fields
    test('copyWith creates new instance with updated fields', () {
      const managementSettings1 = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings1 = AdministrationSettings(
        managementSettings: managementSettings1,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      final settings2 = settings1.copyWith(
        enabledALG: true,
        isUPnPEnabled: false,
      );

      expect(settings2.enabledALG, true);
      expect(settings2.isUPnPEnabled, false);
      expect(settings2.managementSettings, managementSettings1);
      expect(settings2.isExpressForwardingSupported, true);
      expect(settings1, isNot(settings2));
    });

    /// Test toMap serialization
    test('toMap serializes correctly', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
        canDisAllowLocalMangementWirelessly: true,
      );

      final map = settings.toMap();

      expect(map['enabledALG'], false);
      expect(map['isExpressForwardingSupported'], true);
      expect(map['enabledExpressForwarfing'], false);
      expect(map['isUPnPEnabled'], true);
      expect(map['canUsersConfigure'], false);
      expect(map['canUsersDisableWANAccess'], true);
      expect(map['canDisAllowLocalMangementWirelessly'], true);
      expect(map['managementSettings'], isA<Map<String, dynamic>>());
    });

    /// Test fromMap deserialization
    test('fromMap deserializes correctly', () {
      final map = <String, dynamic>{
        'managementSettings': <String, dynamic>{
          'canManageUsingHTTP': true,
          'canManageUsingHTTPS': false,
          'isManageWirelesslySupported': true,
          'canManageRemotely': false,
        },
        'enabledALG': false,
        'isExpressForwardingSupported': true,
        'enabledExpressForwarfing': false,
        'isUPnPEnabled': true,
        'canUsersConfigure': false,
        'canUsersDisableWANAccess': true,
        'canDisAllowLocalMangementWirelessly': true,
      };

      final settings = AdministrationSettings.fromMap(map);

      expect(settings.enabledALG, false);
      expect(settings.isExpressForwardingSupported, true);
      expect(settings.enabledExpressForwarfing, false);
      expect(settings.isUPnPEnabled, true);
      expect(settings.canUsersConfigure, false);
      expect(settings.canUsersDisableWANAccess, true);
      expect(settings.canDisAllowLocalMangementWirelessly, true);
    });

    /// Test toJson serialization
    test('toJson serializes to valid JSON string', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      final jsonString = settings.toJson();
      expect(jsonString, isA<String>());

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['enabledALG'], false);
      expect(decoded['isUPnPEnabled'], true);
    });

    /// Test fromJson deserialization
    test('fromJson deserializes from JSON string', () {
      final map = <String, dynamic>{
        'managementSettings': <String, dynamic>{
          'canManageUsingHTTP': true,
          'canManageUsingHTTPS': false,
          'isManageWirelesslySupported': true,
          'canManageRemotely': false,
        },
        'enabledALG': true,
        'isExpressForwardingSupported': false,
        'enabledExpressForwarfing': true,
        'isUPnPEnabled': false,
        'canUsersConfigure': true,
        'canUsersDisableWANAccess': false,
        'canDisAllowLocalMangementWirelessly': false,
      };

      final jsonString = json.encode(map);
      final settings = AdministrationSettings.fromJson(jsonString);

      expect(settings.enabledALG, true);
      expect(settings.isExpressForwardingSupported, false);
      expect(settings.enabledExpressForwarfing, true);
      expect(settings.isUPnPEnabled, false);
    });

    /// Test equality via Equatable
    test('equality comparison via Equatable', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings1 = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      const settings2 = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      expect(settings1, equals(settings2));
    });

    /// Test inequality when fields differ
    test('inequality when fields differ', () {
      const managementSettings = ManagementSettings(
        canManageUsingHTTP: true,
        canManageUsingHTTPS: false,
        isManageWirelesslySupported: true,
        canManageRemotely: false,
      );

      const settings1 = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      const settings2 = AdministrationSettings(
        managementSettings: managementSettings,
        enabledALG: true,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
      );

      expect(settings1, isNot(equals(settings2)));
    });
  });

  group('AdministrationStatus', () {
    /// Test basic construction
    test('constructs successfully', () {
      const status = AdministrationStatus();
      expect(status, isNotNull);
    });

    /// Test copyWith returns new identical instance
    test('copyWith returns new instance', () {
      const status1 = AdministrationStatus();
      final status2 = status1.copyWith();

      expect(status1, equals(status2));
    });

    /// Test toMap serialization
    test('toMap returns empty map', () {
      const status = AdministrationStatus();
      final map = status.toMap();

      expect(map, isEmpty);
    });

    /// Test fromMap deserialization
    test('fromMap deserializes correctly', () {
      const expectedStatus = AdministrationStatus();
      final status = AdministrationStatus.fromMap(const <String, dynamic>{});

      expect(status, equals(expectedStatus));
    });

    /// Test toJson serialization
    test('toJson serializes to empty JSON object', () {
      const status = AdministrationStatus();
      final jsonString = status.toJson();

      expect(jsonString, '{}');
    });

    /// Test fromJson deserialization
    test('fromJson deserializes from JSON string', () {
      const expectedStatus = AdministrationStatus();
      final status = AdministrationStatus.fromJson('{}');

      expect(status, equals(expectedStatus));
    });

    /// Test equality
    test('all instances are equal', () {
      const status1 = AdministrationStatus();
      const status2 = AdministrationStatus();

      expect(status1, equals(status2));
    });
  });

  group('AdministrationSettingsState', () {
    const managementSettings = ManagementSettings(
      canManageUsingHTTP: true,
      canManageUsingHTTPS: false,
      isManageWirelesslySupported: true,
      canManageRemotely: false,
    );

    const administrationSettings = AdministrationSettings(
      managementSettings: managementSettings,
      enabledALG: false,
      isExpressForwardingSupported: true,
      enabledExpressForwarfing: false,
      isUPnPEnabled: true,
      canUsersConfigure: false,
      canUsersDisableWANAccess: true,
    );

    /// Test basic construction
    test('constructs with settings and status', () {
      final preservable = Preservable(
        original: administrationSettings,
        current: administrationSettings,
      );
      const status = AdministrationStatus();

      final state = AdministrationSettingsState(
        settings: preservable,
        status: status,
      );

      expect(state.settings, preservable);
      expect(state.status, status);
    });

    /// Test copyWith creates new instance
    test('copyWith creates new instance with updated fields', () {
      final preservable1 = Preservable(
        original: administrationSettings,
        current: administrationSettings,
      );
      const status1 = AdministrationStatus();

      final state1 = AdministrationSettingsState(
        settings: preservable1,
        status: status1,
      );

      final newAdministrationSettings = administrationSettings.copyWith(
        enabledALG: true,
      );
      final preservable2 = Preservable(
        original: administrationSettings,
        current: newAdministrationSettings,
      );

      final state2 = state1.copyWith(settings: preservable2);

      expect(state2.settings, isNot(equals(state1.settings)));
      expect(state1, isNot(equals(state2)));
    });

    /// Test toMap serialization
    test('toMap serializes correctly', () {
      final preservable = Preservable(
        original: administrationSettings,
        current: administrationSettings,
      );
      const status = AdministrationStatus();

      final state = AdministrationSettingsState(
        settings: preservable,
        status: status,
      );

      final map = state.toMap();

      expect(map['settings'], isA<Map<String, dynamic>>());
      expect(map['status'], isA<Map<String, dynamic>>());
    });

    /// Test fromMap deserialization
    test('fromMap deserializes correctly', () {
      final map = <String, dynamic>{
        'settings': <String, dynamic>{
          'original': <String, dynamic>{
            'managementSettings': <String, dynamic>{
              'canManageUsingHTTP': true,
              'canManageUsingHTTPS': false,
              'isManageWirelesslySupported': true,
              'canManageRemotely': false,
            },
            'enabledALG': false,
            'isExpressForwardingSupported': true,
            'enabledExpressForwarfing': false,
            'isUPnPEnabled': true,
            'canUsersConfigure': false,
            'canUsersDisableWANAccess': true,
            'canDisAllowLocalMangementWirelessly': true,
          },
          'current': <String, dynamic>{
            'managementSettings': <String, dynamic>{
              'canManageUsingHTTP': true,
              'canManageUsingHTTPS': false,
              'isManageWirelesslySupported': true,
              'canManageRemotely': false,
            },
            'enabledALG': false,
            'isExpressForwardingSupported': true,
            'enabledExpressForwarfing': false,
            'isUPnPEnabled': true,
            'canUsersConfigure': false,
            'canUsersDisableWANAccess': true,
            'canDisAllowLocalMangementWirelessly': true,
          },
        },
        'status': <String, dynamic>{},
      };

      final state = AdministrationSettingsState.fromMap(map);

      expect(state.settings, isNotNull);
      expect(state.status, isNotNull);
    });

    /// Test fromJson deserialization
    test('fromJson deserializes from JSON string', () {
      final map = <String, dynamic>{
        'settings': <String, dynamic>{
          'original': <String, dynamic>{
            'managementSettings': <String, dynamic>{
              'canManageUsingHTTP': false,
              'canManageUsingHTTPS': false,
              'isManageWirelesslySupported': false,
              'canManageRemotely': false,
            },
            'enabledALG': false,
            'isExpressForwardingSupported': false,
            'enabledExpressForwarfing': false,
            'isUPnPEnabled': false,
            'canUsersConfigure': false,
            'canUsersDisableWANAccess': false,
            'canDisAllowLocalMangementWirelessly': true,
          },
          'current': <String, dynamic>{
            'managementSettings': <String, dynamic>{
              'canManageUsingHTTP': false,
              'canManageUsingHTTPS': false,
              'isManageWirelesslySupported': false,
              'canManageRemotely': false,
            },
            'enabledALG': false,
            'isExpressForwardingSupported': false,
            'enabledExpressForwarfing': false,
            'isUPnPEnabled': false,
            'canUsersConfigure': false,
            'canUsersDisableWANAccess': false,
            'canDisAllowLocalMangementWirelessly': true,
          },
        },
        'status': <String, dynamic>{},
      };

      final jsonString = json.encode(map);
      final state = AdministrationSettingsState.fromJson(jsonString);

      expect(state.settings, isNotNull);
      expect(state.status, isNotNull);
    });

    /// Test stringify property
    test('has stringify enabled for debugging', () {
      final preservable = Preservable(
        original: administrationSettings,
        current: administrationSettings,
      );
      const status = AdministrationStatus();

      final state = AdministrationSettingsState(
        settings: preservable,
        status: status,
      );

      expect(state.stringify, true);
    });

    /// Test equality
    test('equality comparison', () {
      final preservable = Preservable(
        original: administrationSettings,
        current: administrationSettings,
      );
      const status = AdministrationStatus();

      final state1 = AdministrationSettingsState(
        settings: preservable,
        status: status,
      );

      final state2 = AdministrationSettingsState(
        settings: preservable,
        status: status,
      );

      expect(state1, equals(state2));
    });
  });
}
