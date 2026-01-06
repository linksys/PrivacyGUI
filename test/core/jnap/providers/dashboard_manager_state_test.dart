import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';

import '../../../mocks/test_data/dashboard_manager_test_data.dart';

void main() {
  group('DashboardManagerState - default values', () {
    test('has correct default values', () {
      // Arrange & Act
      const state = DashboardManagerState();

      // Assert
      expect(state.deviceInfo, isNull);
      expect(state.mainRadios, isEmpty);
      expect(state.guestRadios, isEmpty);
      expect(state.isGuestNetworkEnabled, isFalse);
      expect(state.uptimes, equals(0));
      expect(state.wanConnection, isNull);
      expect(state.lanConnections, isEmpty);
      expect(state.skuModelNumber, isNull);
      expect(state.localTime, equals(0));
      expect(state.cpuLoad, isNull);
      expect(state.memoryLoad, isNull);
    });

    test('stringify is enabled', () {
      // Arrange
      const state = DashboardManagerState();

      // Assert
      expect(state.stringify, isTrue);
    });
  });

  group('DashboardManagerState - equality and copyWith', () {
    test('two states with same values are equal', () {
      // Arrange
      final deviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess().output,
      );
      final state1 = DashboardManagerState(
        deviceInfo: deviceInfo,
        uptimes: 1000,
        wanConnection: 'Linked-1000Mbps',
      );
      final state2 = DashboardManagerState(
        deviceInfo: deviceInfo,
        uptimes: 1000,
        wanConnection: 'Linked-1000Mbps',
      );

      // Assert
      expect(state1, equals(state2));
    });

    test('two states with different values are not equal', () {
      // Arrange
      const state1 = DashboardManagerState(uptimes: 1000);
      const state2 = DashboardManagerState(uptimes: 2000);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('states with different mainRadios are not equal', () {
      // Arrange
      final radios = DashboardManagerTestData.createRadioInfoSuccess();
      final radioList = (radios.output['radios'] as List)
          .map((e) => RouterRadio.fromMap(e as Map<String, dynamic>))
          .toList();

      final state1 = DashboardManagerState(mainRadios: radioList);
      const state2 = DashboardManagerState(mainRadios: []);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('states with different guestRadios are not equal', () {
      // Arrange
      final guestSettings =
          DashboardManagerTestData.createGuestRadioSettingsSuccess();
      final guestRadioList = (guestSettings.output['radios'] as List)
          .map((e) => GuestRadioInfo.fromMap(e as Map<String, dynamic>))
          .toList();

      final state1 = DashboardManagerState(guestRadios: guestRadioList);
      const state2 = DashboardManagerState(guestRadios: []);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('copyWith preserves unmodified values', () {
      // Arrange
      final deviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess().output,
      );
      final original = DashboardManagerState(
        deviceInfo: deviceInfo,
        uptimes: 1000,
        wanConnection: 'Linked-1000Mbps',
        localTime: 1234567890,
      );

      // Act
      final copied = original.copyWith(uptimes: 2000);

      // Assert
      expect(copied.deviceInfo, equals(deviceInfo));
      expect(copied.uptimes, equals(2000));
      expect(copied.wanConnection, equals('Linked-1000Mbps'));
      expect(copied.localTime, equals(1234567890));
    });

    test('copyWith can update all fields', () {
      // Arrange
      const original = DashboardManagerState();
      final newDeviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess().output,
      );

      // Act
      final copied = original.copyWith(
        deviceInfo: newDeviceInfo,
        uptimes: 5000,
        wanConnection: 'Linked-100Mbps',
        lanConnections: ['Port1', 'Port2'],
        skuModelNumber: 'MX5300',
        localTime: 9999999999,
        cpuLoad: '50%',
        memoryLoad: '70%',
        isGuestNetworkEnabled: true,
      );

      // Assert
      expect(copied.deviceInfo, equals(newDeviceInfo));
      expect(copied.uptimes, equals(5000));
      expect(copied.wanConnection, equals('Linked-100Mbps'));
      expect(copied.lanConnections, equals(['Port1', 'Port2']));
      expect(copied.skuModelNumber, equals('MX5300'));
      expect(copied.localTime, equals(9999999999));
      expect(copied.cpuLoad, equals('50%'));
      expect(copied.memoryLoad, equals('70%'));
      expect(copied.isGuestNetworkEnabled, isTrue);
    });

    test('copyWith can update mainRadios and guestRadios', () {
      // Arrange
      const original = DashboardManagerState();
      final radios = DashboardManagerTestData.createRadioInfoSuccess();
      final radioList = (radios.output['radios'] as List)
          .map((e) => RouterRadio.fromMap(e as Map<String, dynamic>))
          .toList();
      final guestSettings =
          DashboardManagerTestData.createGuestRadioSettingsSuccess();
      final guestRadioList = (guestSettings.output['radios'] as List)
          .map((e) => GuestRadioInfo.fromMap(e as Map<String, dynamic>))
          .toList();

      // Act
      final copied = original.copyWith(
        mainRadios: radioList,
        guestRadios: guestRadioList,
      );

      // Assert
      expect(copied.mainRadios.length, equals(2));
      expect(copied.guestRadios.length, equals(2));
      expect(copied.mainRadios[0].band, equals('2.4GHz'));
      expect(copied.mainRadios[1].band, equals('5GHz'));
    });
  });

  group('DashboardManagerState - serialization', () {
    test('toMap produces correct map structure', () {
      // Arrange
      final deviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess().output,
      );
      final state = DashboardManagerState(
        deviceInfo: deviceInfo,
        uptimes: 1000,
        skuModelNumber: 'MX5300',
        localTime: 1234567890,
        isGuestNetworkEnabled: false,
      );

      // Act
      final map = state.toMap();

      // Assert
      expect(map['deviceInfo'], isNotNull);
      expect(map['uptimes'], equals(1000));
      expect(map['skuModelNumber'], equals('MX5300'));
      expect(map['localTime'], equals(1234567890));
      expect(map['isGuestNetworkEnabled'], equals(false));
    });

    test('toMap removes null values', () {
      // Arrange
      const state = DashboardManagerState(uptimes: 100);

      // Act
      final map = state.toMap();

      // Assert
      expect(map.containsKey('deviceInfo'), isFalse);
      expect(map.containsKey('wanConnection'), isFalse);
      expect(map.containsKey('skuModelNumber'), isFalse);
      expect(map.containsKey('cpuLoad'), isFalse);
      expect(map.containsKey('memoryLoad'), isFalse);
      expect(map['uptimes'], equals(100));
    });

    test('toMap includes mainRadios and guestRadios', () {
      // Arrange
      final radios = DashboardManagerTestData.createRadioInfoSuccess();
      final radioList = (radios.output['radios'] as List)
          .map((e) => RouterRadio.fromMap(e as Map<String, dynamic>))
          .toList();
      final guestSettings =
          DashboardManagerTestData.createGuestRadioSettingsSuccess();
      final guestRadioList = (guestSettings.output['radios'] as List)
          .map((e) => GuestRadioInfo.fromMap(e as Map<String, dynamic>))
          .toList();

      final state = DashboardManagerState(
        mainRadios: radioList,
        guestRadios: guestRadioList,
      );

      // Act
      final map = state.toMap();

      // Assert
      expect(map['mainRadios'], isA<List>());
      expect((map['mainRadios'] as List).length, equals(2));
      expect(map['guestRadios'], isA<List>());
      expect((map['guestRadios'] as List).length, equals(2));
    });

    test('fromMap creates state from map', () {
      // Arrange
      final deviceInfoOutput =
          DashboardManagerTestData.createDeviceInfoSuccess().output;
      final map = {
        'deviceInfo': deviceInfoOutput,
        'mainRadios': <Map<String, dynamic>>[],
        'guestRadios': <Map<String, dynamic>>[],
        'isGuestNetworkEnabled': true,
        'uptimes': 5000,
        'skuModelNumber': 'MX5300',
        'localTime': 9876543210,
        'cpuLoad': '25%',
        'memoryLoad': '50%',
      };

      // Act
      final state = DashboardManagerState.fromMap(map);

      // Assert
      expect(state.deviceInfo?.serialNumber, equals('TEST123456'));
      expect(state.isGuestNetworkEnabled, isTrue);
      expect(state.uptimes, equals(5000));
      expect(state.skuModelNumber, equals('MX5300'));
      expect(state.localTime, equals(9876543210));
      expect(state.cpuLoad, equals('25%'));
      expect(state.memoryLoad, equals('50%'));
    });

    test('fromMap handles null deviceInfo', () {
      // Arrange
      final map = {
        'deviceInfo': null,
        'mainRadios': <Map<String, dynamic>>[],
        'guestRadios': <Map<String, dynamic>>[],
        'isGuestNetworkEnabled': false,
        'uptimes': 0,
        'localTime': 0,
      };

      // Act
      final state = DashboardManagerState.fromMap(map);

      // Assert
      expect(state.deviceInfo, isNull);
    });

    test('fromMap handles null radios lists', () {
      // Arrange
      final map = {
        'mainRadios': null,
        'guestRadios': null,
        'isGuestNetworkEnabled': false,
        'uptimes': 0,
        'localTime': 0,
      };

      // Act
      final state = DashboardManagerState.fromMap(map);

      // Assert
      expect(state.mainRadios, isEmpty);
      expect(state.guestRadios, isEmpty);
    });

    test('toJson and fromJson are reversible', () {
      // Arrange
      final deviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess().output,
      );
      final original = DashboardManagerState(
        deviceInfo: deviceInfo,
        uptimes: 1000,
        isGuestNetworkEnabled: true,
        localTime: 1234567890,
      );

      // Act
      final json = original.toJson();
      final restored = DashboardManagerState.fromJson(json);

      // Assert
      expect(restored.deviceInfo?.serialNumber,
          equals(original.deviceInfo?.serialNumber));
      expect(restored.uptimes, equals(original.uptimes));
      expect(restored.isGuestNetworkEnabled,
          equals(original.isGuestNetworkEnabled));
      expect(restored.localTime, equals(original.localTime));
    });

    test('toJson and fromJson preserve mainRadios and guestRadios', () {
      // Arrange
      final radios = DashboardManagerTestData.createRadioInfoSuccess();
      final radioList = (radios.output['radios'] as List)
          .map((e) => RouterRadio.fromMap(e as Map<String, dynamic>))
          .toList();
      final guestSettings =
          DashboardManagerTestData.createGuestRadioSettingsSuccess();
      final guestRadioList = (guestSettings.output['radios'] as List)
          .map((e) => GuestRadioInfo.fromMap(e as Map<String, dynamic>))
          .toList();

      final original = DashboardManagerState(
        mainRadios: radioList,
        guestRadios: guestRadioList,
        isGuestNetworkEnabled: true,
        uptimes: 0,
        localTime: 0,
      );

      // Act
      final json = original.toJson();
      final restored = DashboardManagerState.fromJson(json);

      // Assert
      expect(restored.mainRadios.length, equals(original.mainRadios.length));
      expect(restored.guestRadios.length, equals(original.guestRadios.length));
      expect(restored.mainRadios[0].band, equals('2.4GHz'));
      expect(restored.mainRadios[1].band, equals('5GHz'));
    });
  });
}
