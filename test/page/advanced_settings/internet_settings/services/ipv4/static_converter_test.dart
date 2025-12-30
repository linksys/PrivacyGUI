import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/static_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('StaticConverter', () {
    group('fromJNAP', () {
      test('converts Static JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.staticWanSettings(
          mtu: 1500,
          ipAddress: '192.168.1.100',
          gateway: '192.168.1.1',
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          prefixLength: 24,
          domainName: 'test.com',
        );

        // Act
        final result = StaticConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'Static');
        expect(result.mtu, 1500);
        expect(result.staticIpAddress, '192.168.1.100');
        expect(result.staticGateway, '192.168.1.1');
        expect(result.staticDns1, '8.8.8.8');
        expect(result.staticDns2, '8.8.4.4');
        expect(result.networkPrefixLength, 24);
        expect(result.domainName, 'test.com');
      });

      test('handles Static with DNS3', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.staticWanSettings(
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          dns3: '1.1.1.1',
        );

        // Act
        final result = StaticConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.staticDns1, '8.8.8.8');
        expect(result.staticDns2, '8.8.4.4');
        expect(result.staticDns3, '1.1.1.1');
      });

      test('handles null static settings', () {
        // Arrange - JNAP model without static settings
        final jnapModel = InternetSettingsTestDataBuilder.dhcpWanSettings();

        // Act
        final result = StaticConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'Static');
        expect(result.staticIpAddress, isNull);
        expect(result.staticGateway, isNull);
      });
    });

    group('toJNAP', () {
      test('converts Static UI model to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.staticUIModel(
          mtu: 1500,
          ipAddress: '192.168.1.100',
          gateway: '192.168.1.1',
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          prefixLength: 24,
          domainName: 'test.com',
        );

        // Act
        final result = StaticConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'Static');
        expect(result.mtu, 1500);
        expect(result.staticSettings?.ipAddress, '192.168.1.100');
        expect(result.staticSettings?.gateway, '192.168.1.1');
        expect(result.staticSettings?.dnsServer1, '8.8.8.8');
        expect(result.staticSettings?.dnsServer2, '8.8.4.4');
        expect(result.staticSettings?.networkPrefixLength, 24);
        expect(result.staticSettings?.domainName, 'test.com');
      });

      test('uses default values for empty required fields', () {
        // Arrange - UI model with minimal data
        final uiModel = InternetSettingsTestDataBuilder.staticUIModel(
          ipAddress: '',
          gateway: '',
          dns1: '',
        );

        // Act
        final result = StaticConverter.toJNAP(uiModel);

        // Assert
        expect(result.staticSettings?.ipAddress, '');
        expect(result.staticSettings?.gateway, '');
        expect(result.staticSettings?.dnsServer1, '');
      });
    });

    group('updateFromForm', () {
      test('updates all Static-specific fields from form data', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.staticUIModel(
          ipAddress: '192.168.1.100',
          gateway: '192.168.1.1',
          dns1: '8.8.8.8',
          prefixLength: 24,
        );
        final formData = InternetSettingsTestDataBuilder.staticUIModel(
          ipAddress: '10.0.0.100',
          gateway: '10.0.0.1',
          dns1: '1.1.1.1',
          dns2: '1.0.0.1',
          prefixLength: 16,
          domainName: 'newdomain.com',
        );

        // Act
        final result =
            StaticConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.staticIpAddress, '10.0.0.100');
        expect(result.staticGateway, '10.0.0.1');
        expect(result.staticDns1, '1.1.1.1');
        expect(result.staticDns2, '1.0.0.1');
        expect(result.networkPrefixLength, 16);
        expect(result.domainName, 'newdomain.com');
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.staticWanSettings(
          mtu: 1500,
          ipAddress: '192.168.1.100',
          gateway: '192.168.1.1',
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          dns3: '1.1.1.1',
          prefixLength: 24,
          domainName: 'test.com',
        );

        // Act
        final uiModel = StaticConverter.fromJNAP(originalJnap);
        final convertedJnap = StaticConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
        expect(convertedJnap.staticSettings?.ipAddress,
            originalJnap.staticSettings?.ipAddress);
        expect(convertedJnap.staticSettings?.gateway,
            originalJnap.staticSettings?.gateway);
        expect(convertedJnap.staticSettings?.dnsServer1,
            originalJnap.staticSettings?.dnsServer1);
        expect(convertedJnap.staticSettings?.networkPrefixLength,
            originalJnap.staticSettings?.networkPrefixLength);
      });

      test('UI -> JNAP -> UI maintains data integrity', () {
        // Arrange
        final originalUi = InternetSettingsTestDataBuilder.staticUIModel(
          mtu: 1500,
          ipAddress: '192.168.1.100',
          gateway: '192.168.1.1',
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          prefixLength: 24,
          domainName: 'test.com',
        );

        // Act
        final jnapModel = StaticConverter.toJNAP(originalUi);
        final convertedUi = StaticConverter.fromJNAP(jnapModel);

        // Assert
        expect(convertedUi.ipv4ConnectionType, originalUi.ipv4ConnectionType);
        expect(convertedUi.mtu, originalUi.mtu);
        expect(convertedUi.staticIpAddress, originalUi.staticIpAddress);
        expect(convertedUi.staticGateway, originalUi.staticGateway);
        expect(convertedUi.staticDns1, originalUi.staticDns1);
        expect(convertedUi.staticDns2, originalUi.staticDns2);
        expect(convertedUi.networkPrefixLength, originalUi.networkPrefixLength);
        expect(convertedUi.domainName, originalUi.domainName);
      });
    });
  });
}
