import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

void main() {
  group('DashboardSpeedUIModel', () {
    group('construction & defaults', () {
      test('creates instance with required fields', () {
        // Act
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Assert
        expect(item.unit, 'Mbps');
        expect(item.value, '100');
      });
    });

    group('copyWith', () {
      test('creates new instance (not same reference)', () {
        // Arrange
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Act
        final copied = item.copyWith(value: '200');

        // Assert
        expect(identical(copied, item), false);
        expect(copied.value, '200');
        expect(item.value, '100');
      });

      test('preserves unmodified fields', () {
        // Arrange
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Act
        final copied = item.copyWith(value: '200');

        // Assert
        expect(copied.unit, 'Mbps');
        expect(copied.value, '200');
      });

      test('updates unit', () {
        // Arrange
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Act
        final updated = item.copyWith(unit: 'Kbps');

        // Assert
        expect(updated.unit, 'Kbps');
        expect(updated.value, '100');
      });
    });

    group('equality (Equatable)', () {
      test('identical items are equal', () {
        // Arrange
        const item1 = DashboardSpeedUIModel(unit: 'Mbps', value: '100');
        const item2 = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Assert
        expect(item1, item2);
        expect(item1.hashCode, item2.hashCode);
      });

      test('different items are not equal', () {
        // Arrange
        const item1 = DashboardSpeedUIModel(unit: 'Mbps', value: '100');
        const item2 = DashboardSpeedUIModel(unit: 'Mbps', value: '200');

        // Assert
        expect(item1, isNot(item2));
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Act
        final map = item.toMap();

        // Assert
        expect(map['unit'], 'Mbps');
        expect(map['value'], '100');
        expect(map.length, 2);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const original = DashboardSpeedUIModel(unit: 'Mbps', value: '100');
        final map = original.toMap();

        // Act
        final restored = DashboardSpeedUIModel.fromMap(map);

        // Assert
        expect(restored, original);
      });

      test('toJson returns valid JSON string', () {
        // Arrange
        const item = DashboardSpeedUIModel(unit: 'Mbps', value: '100');

        // Act
        final json = item.toJson();

        // Assert
        expect(json, isNotNull);
        expect(json, isA<String>());
        final decoded = jsonDecode(json);
        expect(decoded, isA<Map>());
        expect(decoded['unit'], 'Mbps');
        expect(decoded['value'], '100');
      });

      test('fromJson correctly parses JSON string', () {
        // Arrange
        const original = DashboardSpeedUIModel(unit: 'Mbps', value: '100');
        final json = original.toJson();

        // Act
        final restored = DashboardSpeedUIModel.fromJson(json);

        // Assert
        expect(restored, original);
      });
    });
  });

  group('DashboardWiFiUIModel', () {
    group('construction & defaults', () {
      test('creates instance with all required fields', () {
        // Act
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Assert
        expect(item.ssid, 'TestNetwork');
        expect(item.password, 'password123');
        expect(item.radios, ['RADIO_2.4GHz', 'RADIO_5GHz']);
        expect(item.isGuest, false);
        expect(item.isEnabled, true);
        expect(item.numOfConnectedDevices, 5);
      });

      test('creates guest network item', () {
        // Act
        const item = DashboardWiFiUIModel(
          ssid: 'Guest-Network',
          password: 'guestpass',
          radios: ['RADIO_2.4GHz'],
          isGuest: true,
          isEnabled: true,
          numOfConnectedDevices: 2,
        );

        // Assert
        expect(item.ssid, 'Guest-Network');
        expect(item.isGuest, true);
      });
    });

    group('copyWith', () {
      test('creates new instance (not same reference)', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final copied = item.copyWith(ssid: 'NewNetwork');

        // Assert
        expect(identical(copied, item), false);
        expect(copied.ssid, 'NewNetwork');
        expect(item.ssid, 'TestNetwork');
      });

      test('preserves unmodified fields', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final copied = item.copyWith(ssid: 'NewNetwork');

        // Assert
        expect(copied.ssid, 'NewNetwork');
        expect(copied.password, 'password123');
        expect(copied.radios, ['RADIO_2.4GHz', 'RADIO_5GHz']);
        expect(copied.isGuest, false);
        expect(copied.isEnabled, true);
        expect(copied.numOfConnectedDevices, 5);
      });

      test('updates password', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final updated = item.copyWith(password: 'newpassword');

        // Assert
        expect(updated.password, 'newpassword');
      });

      test('updates isEnabled', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final updated = item.copyWith(isEnabled: false);

        // Assert
        expect(updated.isEnabled, false);
      });

      test('updates numOfConnectedDevices', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final updated = item.copyWith(numOfConnectedDevices: 10);

        // Assert
        expect(updated.numOfConnectedDevices, 10);
      });

      test('updates multiple fields at once', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final updated = item.copyWith(
          ssid: 'NewNetwork',
          password: 'newpass',
          isEnabled: false,
        );

        // Assert
        expect(updated.ssid, 'NewNetwork');
        expect(updated.password, 'newpass');
        expect(updated.isEnabled, false);
        expect(updated.isGuest, false);
        expect(updated.numOfConnectedDevices, 5);
      });
    });

    group('equality (Equatable)', () {
      test('identical items are equal', () {
        // Arrange
        const item1 = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );
        const item2 = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Assert
        expect(item1, item2);
        expect(item1.hashCode, item2.hashCode);
      });

      test('different ssid makes items unequal', () {
        // Arrange
        const item1 = DashboardWiFiUIModel(
          ssid: 'TestNetwork1',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );
        const item2 = DashboardWiFiUIModel(
          ssid: 'TestNetwork2',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Assert
        expect(item1, isNot(item2));
      });

      test('different isGuest makes items unequal', () {
        // Arrange
        const item1 = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );
        const item2 = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: true,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Assert
        expect(item1, isNot(item2));
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const item = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        final map = item.toMap();

        // Assert
        expect(map['ssid'], 'TestNetwork');
        expect(map['password'], 'password123');
        expect(map['radios'], ['RADIO_2.4GHz', 'RADIO_5GHz']);
        expect(map['isGuest'], false);
        expect(map['isEnabled'], true);
        expect(map['numOfConnectedDevices'], 5);
        expect(map.length, 6);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const original = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );
        final map = original.toMap();

        // Act
        final restored = DashboardWiFiUIModel.fromMap(map);

        // Assert
        expect(restored, original);
      });

      test('round-trip: object → toJson() → fromJson() → equals(original)', () {
        // Arrange
        const original = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'],
          isGuest: true,
          isEnabled: false,
          numOfConnectedDevices: 3,
        );

        // Act
        final json = original.toJson();
        final restored = DashboardWiFiUIModel.fromJson(json);

        // Assert
        expect(restored, original);
      });
    });
  });

  group('DashboardHomeState', () {
    group('construction & defaults', () {
      test('creates instance with default values', () {
        // Act
        const state = DashboardHomeState();

        // Assert
        expect(state.isFirstPolling, false);
        expect(state.isHorizontalLayout, false);
        expect(state.masterIcon, '');
        expect(state.isAnyNodesOffline, false);
        expect(state.uptime, isNull);
        expect(state.wanPortConnection, isNull);
        expect(state.lanPortConnections, const []);
        expect(state.wifis, const []);
        expect(state.wanType, isNull);
        expect(state.detectedWANType, isNull);
      });

      test('creates instance with all fields provided', () {
        // Arrange
        const wifiItem = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );

        // Act
        const state = DashboardHomeState(
          isFirstPolling: true,
          isHorizontalLayout: true,
          masterIcon: 'routerMx5300',
          isAnyNodesOffline: true,
          uptime: 86400,
          wanPortConnection: 'Linked-1000Mbps',
          lanPortConnections: ['Linked-1000Mbps', 'None', 'None'],
          wifis: [wifiItem],
          wanType: 'DHCP',
          detectedWANType: 'DHCP',
        );

        // Assert
        expect(state.isFirstPolling, true);
        expect(state.isHorizontalLayout, true);
        expect(state.masterIcon, 'routerMx5300');
        expect(state.isAnyNodesOffline, true);
        expect(state.uptime, 86400);
        expect(state.wanPortConnection, 'Linked-1000Mbps');
        expect(state.lanPortConnections, ['Linked-1000Mbps', 'None', 'None']);
        expect(state.wifis, [wifiItem]);
        expect(state.wanType, 'DHCP');
        expect(state.detectedWANType, 'DHCP');
      });
    });

    group('copyWith', () {
      test('updates isFirstPolling', () {
        // Arrange
        const state = DashboardHomeState(isFirstPolling: false);

        // Act
        final updated = state.copyWith(isFirstPolling: true);

        // Assert
        expect(updated.isFirstPolling, true);
      });

      test('updates isHorizontalLayout', () {
        // Arrange
        const state = DashboardHomeState(isHorizontalLayout: false);

        // Act
        final updated = state.copyWith(isHorizontalLayout: true);

        // Assert
        expect(updated.isHorizontalLayout, true);
      });

      test('updates masterIcon', () {
        // Arrange
        const state = DashboardHomeState(masterIcon: 'routerMx5300');

        // Act
        final updated = state.copyWith(masterIcon: 'routerMx6200');

        // Assert
        expect(updated.masterIcon, 'routerMx6200');
      });

      test('updates isAnyNodesOffline', () {
        // Arrange
        const state = DashboardHomeState(isAnyNodesOffline: false);

        // Act
        final updated = state.copyWith(isAnyNodesOffline: true);

        // Assert
        expect(updated.isAnyNodesOffline, true);
      });

      test('updates uptime with ValueGetter', () {
        // Arrange
        const state = DashboardHomeState(uptime: 1000);

        // Act
        final updated = state.copyWith(uptime: () => 2000);

        // Assert
        expect(updated.uptime, 2000);
      });

      test('updates uptime to null with ValueGetter', () {
        // Arrange
        const state = DashboardHomeState(uptime: 1000);

        // Act
        final updated = state.copyWith(uptime: () => null);

        // Assert
        expect(updated.uptime, isNull);
      });

      test('updates wanPortConnection', () {
        // Arrange
        const state = DashboardHomeState(wanPortConnection: 'Linked-100Mbps');

        // Act
        final updated =
            state.copyWith(wanPortConnection: () => 'Linked-1000Mbps');

        // Assert
        expect(updated.wanPortConnection, 'Linked-1000Mbps');
      });

      test('updates lanPortConnections', () {
        // Arrange
        const state = DashboardHomeState(lanPortConnections: ['None', 'None']);

        // Act
        final updated = state.copyWith(
          lanPortConnections: ['Linked-1000Mbps', 'None', 'None', 'None'],
        );

        // Assert
        expect(updated.lanPortConnections.length, 4);
        expect(updated.lanPortConnections[0], 'Linked-1000Mbps');
      });

      test('updates wifis list', () {
        // Arrange
        const state = DashboardHomeState(wifis: []);
        const newWifi = DashboardWiFiUIModel(
          ssid: 'NewNetwork',
          password: 'pass',
          radios: ['RADIO_5GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 3,
        );

        // Act
        final updated = state.copyWith(wifis: [newWifi]);

        // Assert
        expect(updated.wifis.length, 1);
        expect(updated.wifis[0].ssid, 'NewNetwork');
      });

      test('updates wanType', () {
        // Arrange
        const state = DashboardHomeState(wanType: 'DHCP');

        // Act
        final updated = state.copyWith(wanType: () => 'PPPoE');

        // Assert
        expect(updated.wanType, 'PPPoE');
      });

      test('updates detectedWANType', () {
        // Arrange
        const state = DashboardHomeState(detectedWANType: 'DHCP');

        // Act
        final updated = state.copyWith(detectedWANType: () => 'Bridge');

        // Assert
        expect(updated.detectedWANType, 'Bridge');
      });

      test('preserves unmodified fields', () {
        // Arrange
        const state = DashboardHomeState(
          isFirstPolling: true,
          isHorizontalLayout: true,
          masterIcon: 'routerMx5300',
          uptime: 86400,
        );

        // Act
        final updated = state.copyWith(isFirstPolling: false);

        // Assert
        expect(updated.isFirstPolling, false);
        expect(updated.isHorizontalLayout, true);
        expect(updated.masterIcon, 'routerMx5300');
        expect(updated.uptime, 86400);
      });
    });

    group('equality (Equatable)', () {
      test('identical states are equal', () {
        // Arrange
        const state1 = DashboardHomeState(
          isFirstPolling: true,
          masterIcon: 'routerMx5300',
          uptime: 86400,
        );
        const state2 = DashboardHomeState(
          isFirstPolling: true,
          masterIcon: 'routerMx5300',
          uptime: 86400,
        );

        // Assert
        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('different states are not equal', () {
        // Arrange
        const state1 = DashboardHomeState(isFirstPolling: true);
        const state2 = DashboardHomeState(isFirstPolling: false);

        // Assert
        expect(state1, isNot(state2));
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const state = DashboardHomeState(
          isFirstPolling: true,
          isHorizontalLayout: true,
          masterIcon: 'routerMx5300',
          isAnyNodesOffline: false,
          uptime: 86400,
          wanPortConnection: 'Linked-1000Mbps',
          lanPortConnections: ['Linked-1000Mbps', 'None'],
          wifis: [],
          wanType: 'DHCP',
          detectedWANType: 'DHCP',
        );

        // Act
        final map = state.toMap();

        // Assert
        expect(map['isFirstPolling'], true);
        expect(map['isHorizontalLayout'], true);
        expect(map['masterIcon'], 'routerMx5300');
        expect(map['isAnyNodesOffline'], false);
        expect(map['uptime'], 86400);
        expect(map['wanPortConnection'], 'Linked-1000Mbps');
        expect(map['lanPortConnections'], ['Linked-1000Mbps', 'None']);
        expect(map['wifis'], []);
        expect(map['wanType'], 'DHCP');
        expect(map['detectedWANType'], 'DHCP');
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const wifiItem = DashboardWiFiUIModel(
          ssid: 'TestNetwork',
          password: 'password123',
          radios: ['RADIO_2.4GHz'],
          isGuest: false,
          isEnabled: true,
          numOfConnectedDevices: 5,
        );
        const originalState = DashboardHomeState(
          isFirstPolling: true,
          isHorizontalLayout: true,
          masterIcon: 'routerMx5300',
          isAnyNodesOffline: true,
          uptime: 86400,
          wanPortConnection: 'Linked-1000Mbps',
          lanPortConnections: ['Linked-1000Mbps', 'None'],
          wifis: [wifiItem],
          wanType: 'DHCP',
          detectedWANType: 'DHCP',
        );
        final map = originalState.toMap();

        // Act
        final restored = DashboardHomeState.fromMap(map);

        // Assert
        expect(restored.isFirstPolling, originalState.isFirstPolling);
        expect(restored.isHorizontalLayout, originalState.isHorizontalLayout);
        expect(restored.masterIcon, originalState.masterIcon);
        expect(restored.isAnyNodesOffline, originalState.isAnyNodesOffline);
        expect(restored.uptime, originalState.uptime);
        expect(restored.wanPortConnection, originalState.wanPortConnection);
        expect(restored.lanPortConnections, originalState.lanPortConnections);
        expect(restored.wifis.length, originalState.wifis.length);
        expect(restored.wanType, originalState.wanType);
        expect(restored.detectedWANType, originalState.detectedWANType);
      });

      test('round-trip: object → toJson() → fromJson() → equals(original)', () {
        // Arrange
        const originalState = DashboardHomeState(
          isFirstPolling: false,
          isHorizontalLayout: true,
          masterIcon: 'routerMx5300',
          isAnyNodesOffline: false,
          uptime: 172800,
          wanPortConnection: 'Linked-1000Mbps',
          lanPortConnections: ['Linked-1000Mbps', 'None', 'None', 'None'],
          wifis: [],
          wanType: 'DHCP',
          detectedWANType: 'DHCP',
        );

        // Act
        final json = originalState.toJson();
        final restored = DashboardHomeState.fromJson(json);

        // Assert
        expect(restored, originalState);
      });
    });
  });

  group('DashboardHomeStateExt', () {
    test('mainSSID returns first WiFi SSID', () {
      // Arrange
      const wifiItem = DashboardWiFiUIModel(
        ssid: 'MyNetwork',
        password: 'password123',
        radios: ['RADIO_2.4GHz'],
        isGuest: false,
        isEnabled: true,
        numOfConnectedDevices: 5,
      );
      const state = DashboardHomeState(wifis: [wifiItem]);

      // Act & Assert
      expect(state.mainSSID, 'MyNetwork');
    });

    test('mainSSID returns empty string when no WiFi', () {
      // Arrange
      const state = DashboardHomeState(wifis: []);

      // Act & Assert
      expect(state.mainSSID, '');
    });

    test('isBridgeMode returns true when wanType is Bridge', () {
      // Arrange
      const state = DashboardHomeState(wanType: 'Bridge');

      // Act & Assert
      expect(state.isBridgeMode, true);
    });

    test('isBridgeMode returns true when detectedWANType is Bridge', () {
      // Arrange
      const state = DashboardHomeState(detectedWANType: 'Bridge');

      // Act & Assert
      expect(state.isBridgeMode, true);
    });

    test('isBridgeMode returns false when neither is Bridge', () {
      // Arrange
      const state = DashboardHomeState(
        wanType: 'DHCP',
        detectedWANType: 'DHCP',
      );

      // Act & Assert
      expect(state.isBridgeMode, false);
    });

    test('isBridgeMode returns false when both are null', () {
      // Arrange
      const state = DashboardHomeState();

      // Act & Assert
      expect(state.isBridgeMode, false);
    });
  });
}
