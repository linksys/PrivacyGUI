import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv4_settings_ui_model.dart';

void main() {
  group('Ipv4SettingsUIModel', () {
    test('creates model with required fields', () {
      // Act
      const model = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1500,
      );

      // Assert
      expect(model.ipv4ConnectionType, 'DHCP');
      expect(model.mtu, 1500);
      expect(model.behavior, null);
      expect(model.username, null);
      expect(model.staticIpAddress, null);
    });

    test('creates model with all fields', () {
      // Act
      const model = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'Static',
        mtu: 1400,
        behavior: PPPConnectionBehavior.keepAlive,
        maxIdleMinutes: 15,
        reconnectAfterSeconds: 30,
        staticIpAddress: '192.168.1.100',
        staticGateway: '192.168.1.1',
        staticDns1: '8.8.8.8',
        staticDns2: '8.8.4.4',
        staticDns3: '1.1.1.1',
        networkPrefixLength: 24,
        domainName: 'example.com',
        username: 'user',
        password: 'pass',
        serviceName: 'service',
        serverIp: '10.0.0.1',
        useStaticSettings: true,
        wanTaggingSettingsEnable: true,
        vlanId: 100,
      );

      // Assert
      expect(model.ipv4ConnectionType, 'Static');
      expect(model.mtu, 1400);
      expect(model.behavior, PPPConnectionBehavior.keepAlive);
      expect(model.maxIdleMinutes, 15);
      expect(model.reconnectAfterSeconds, 30);
      expect(model.staticIpAddress, '192.168.1.100');
      expect(model.staticGateway, '192.168.1.1');
      expect(model.staticDns1, '8.8.8.8');
      expect(model.staticDns2, '8.8.4.4');
      expect(model.staticDns3, '1.1.1.1');
      expect(model.networkPrefixLength, 24);
      expect(model.domainName, 'example.com');
      expect(model.username, 'user');
      expect(model.password, 'pass');
      expect(model.serviceName, 'service');
      expect(model.serverIp, '10.0.0.1');
      expect(model.useStaticSettings, true);
      expect(model.wanTaggingSettingsEnable, true);
      expect(model.vlanId, 100);
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      const original = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1500,
      );

      // Act
      final updated = original.copyWith(
        ipv4ConnectionType: 'Static',
        staticIpAddress: () => '192.168.1.100',
        staticGateway: () => '192.168.1.1',
      );

      // Assert
      expect(updated.ipv4ConnectionType, 'Static');
      expect(updated.mtu, 1500);
      expect(updated.staticIpAddress, '192.168.1.100');
      expect(updated.staticGateway, '192.168.1.1');
    });

    test('copyWith with null value removes optional fields', () {
      // Arrange
      const original = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'PPPoE',
        mtu: 1400,
        username: 'user',
        password: 'pass',
      );

      // Act
      final updated = original.copyWith(
        username: () => null,
        password: () => null,
      );

      // Assert
      expect(updated.username, null);
      expect(updated.password, null);
      expect(updated.ipv4ConnectionType, 'PPPoE');
    });

    test('toMap converts model to map', () {
      // Arrange
      const model = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'Static',
        mtu: 1500,
        staticIpAddress: '192.168.1.100',
        staticGateway: '192.168.1.1',
        staticDns1: '8.8.8.8',
        networkPrefixLength: 24,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['ipv4ConnectionType'], 'Static');
      expect(map['mtu'], 1500);
      expect(map['staticIpAddress'], '192.168.1.100');
      expect(map['staticGateway'], '192.168.1.1');
      expect(map['staticDns1'], '8.8.8.8');
      expect(map['networkPrefixLength'], 24);
    });

    test('toMap removes null values', () {
      // Arrange
      const model = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1500,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map.containsKey('username'), false);
      expect(map.containsKey('password'), false);
      expect(map.containsKey('staticIpAddress'), false);
    });

    test('toMap converts behavior enum to value', () {
      // Arrange
      const model = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'PPPoE',
        mtu: 1400,
        behavior: PPPConnectionBehavior.connectOnDemand,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['behavior'], 'ConnectOnDemand');
    });

    test('fromMap creates model from map', () {
      // Arrange
      final map = {
        'ipv4ConnectionType': 'Static',
        'mtu': 1500,
        'staticIpAddress': '192.168.1.100',
        'staticGateway': '192.168.1.1',
        'staticDns1': '8.8.8.8',
        'networkPrefixLength': 24,
      };

      // Act
      final model = Ipv4SettingsUIModel.fromMap(map);

      // Assert
      expect(model.ipv4ConnectionType, 'Static');
      expect(model.mtu, 1500);
      expect(model.staticIpAddress, '192.168.1.100');
      expect(model.staticGateway, '192.168.1.1');
      expect(model.staticDns1, '8.8.8.8');
      expect(model.networkPrefixLength, 24);
    });

    test('fromMap with behavior resolves enum', () {
      // Arrange
      final map = {
        'ipv4ConnectionType': 'PPPoE',
        'mtu': 1400,
        'behavior': 'KeepAlive',
        'username': 'user',
        'password': 'pass',
      };

      // Act
      final model = Ipv4SettingsUIModel.fromMap(map);

      // Assert
      expect(model.behavior, PPPConnectionBehavior.keepAlive);
      expect(model.username, 'user');
      expect(model.password, 'pass');
    });

    test('toJson and fromJson work correctly', () {
      // Arrange
      const original = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'PPPoE',
        mtu: 1400,
        behavior: PPPConnectionBehavior.keepAlive,
        maxIdleMinutes: 15,
        reconnectAfterSeconds: 30,
        username: 'testuser',
        password: 'testpass',
        serviceName: 'myservice',
      );

      // Act
      final json = original.toJson();
      final restored = Ipv4SettingsUIModel.fromJson(json);

      // Assert
      expect(restored, original);
    });

    test('equality works correctly', () {
      // Arrange
      const model1 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1500,
      );

      const model2 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1500,
      );

      const model3 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'DHCP',
        mtu: 1400,
      );

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });

    test('equality includes all optional fields', () {
      // Arrange
      const model1 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'Static',
        mtu: 1500,
        staticIpAddress: '192.168.1.100',
      );

      const model2 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'Static',
        mtu: 1500,
        staticIpAddress: '192.168.1.100',
      );

      const model3 = Ipv4SettingsUIModel(
        ipv4ConnectionType: 'Static',
        mtu: 1500,
        staticIpAddress: '192.168.1.101',
      );

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });
  });
}
