import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pptp_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('PptpConverter', () {
    group('fromJNAP', () {
      test('converts PPTP JNAP model with DHCP to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pptpWanSettings(
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          useStaticSettings: false,
        );

        // Act
        final result = PptpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'PPTP');
        expect(result.username, 'testuser');
        expect(result.password, 'testpass');
        expect(result.serverIp, '192.168.1.1');
        expect(result.useStaticSettings, false);
      });

      test('converts PPTP JNAP model with static settings to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pptpWanSettings(
          useStaticSettings: true,
          staticIpAddress: '10.0.0.100',
          staticGateway: '10.0.0.1',
          staticDns1: '8.8.8.8',
          staticDns2: '8.8.4.4',
          networkPrefixLength: 24,
        );

        // Act
        final result = PptpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.useStaticSettings, true);
        expect(result.staticIpAddress, '10.0.0.100');
        expect(result.staticGateway, '10.0.0.1');
        expect(result.staticDns1, '8.8.8.8');
        expect(result.staticDns2, '8.8.4.4');
      });
    });

    group('toJNAP', () {
      test('converts PPTP UI model with DHCP to JNAP model', () {
        // Arrange
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPTP',
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: PPPConnectionBehavior.keepAlive,
          reconnectAfterSeconds: 30,
          useStaticSettings: false,
        );

        // Act
        final result = PptpConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'PPTP');
        expect(result.mtu, 1460);
        expect(result.tpSettings?.username, 'testuser');
        expect(result.tpSettings?.password, 'testpass');
        expect(result.tpSettings?.server, '192.168.1.1');
        expect(result.tpSettings?.useStaticSettings, false);
        expect(result.tpSettings?.staticSettings, isNull);
      });

      test('converts PPTP UI model with static settings to JNAP model', () {
        // Arrange
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPTP',
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: PPPConnectionBehavior.keepAlive,
          useStaticSettings: true,
          staticIpAddress: '10.0.0.100',
          staticGateway: '10.0.0.1',
          staticDns1: '8.8.8.8',
          networkPrefixLength: 24,
        );

        // Act
        final result = PptpConverter.toJNAP(uiModel);

        // Assert
        expect(result.tpSettings?.useStaticSettings, true);
        expect(result.tpSettings?.staticSettings?.ipAddress, '10.0.0.100');
        expect(result.tpSettings?.staticSettings?.gateway, '10.0.0.1');
        expect(result.tpSettings?.staticSettings?.dnsServer1, '8.8.8.8');
        expect(result.tpSettings?.staticSettings?.networkPrefixLength, 24);
      });
    });

    group('updateFromForm', () {
      test('updates all PPTP-specific fields including static settings', () {
        // Arrange
        final currentSettings = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPTP',
          mtu: 1460,
          username: 'olduser',
          serverIp: '192.168.1.1',
          useStaticSettings: false,
        );
        final formData = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPTP',
          mtu: 1460,
          username: 'newuser',
          password: 'newpass',
          serverIp: '10.0.0.1',
          useStaticSettings: true,
          staticIpAddress: '10.0.0.100',
          staticGateway: '10.0.0.1',
          staticDns1: '1.1.1.1',
          networkPrefixLength: 16,
        );

        // Act
        final result = PptpConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.username, 'newuser');
        expect(result.password, 'newpass');
        expect(result.serverIp, '10.0.0.1');
        expect(result.useStaticSettings, true);
        expect(result.staticIpAddress, '10.0.0.100');
        expect(result.staticGateway, '10.0.0.1');
        expect(result.staticDns1, '1.1.1.1');
        expect(result.networkPrefixLength, 16);
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity with static settings',
          () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.pptpWanSettings(
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          useStaticSettings: true,
          staticIpAddress: '10.0.0.100',
          staticGateway: '10.0.0.1',
          staticDns1: '8.8.8.8',
          networkPrefixLength: 24,
        );

        // Act
        final uiModel = PptpConverter.fromJNAP(originalJnap);
        final convertedJnap = PptpConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
        expect(convertedJnap.tpSettings?.username,
            originalJnap.tpSettings?.username);
        expect(convertedJnap.tpSettings?.useStaticSettings,
            originalJnap.tpSettings?.useStaticSettings);
        expect(convertedJnap.tpSettings?.staticSettings?.ipAddress,
            originalJnap.tpSettings?.staticSettings?.ipAddress);
      });
    });
  });
}
