import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/automatic_ipv6_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('AutomaticIpv6Converter', () {
    group('fromJNAP', () {
      test('converts Automatic IPv6 JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.automaticIPv6Settings(
          isAutomatic: true,
        );

        // Act
        final result = AutomaticIpv6Converter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv6ConnectionType, 'Automatic');
        expect(result.isIPv6AutomaticEnabled, true);
      });

      test('converts IPv6 with 6rd tunnel in Manual mode', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.automaticIPv6Settings(
          isAutomatic: true,
          ipv6rdTunnelMode: 'Manual',
          prefix: '2001:db8::',
          prefixLength: 32,
          borderRelay: '192.0.2.1',
          borderRelayPrefixLength: 24,
        );

        // Act
        final result = AutomaticIpv6Converter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
        expect(result.ipv6Prefix, '2001:db8::');
        expect(result.ipv6PrefixLength, 32);
        expect(result.ipv6BorderRelay, '192.0.2.1');
        expect(result.ipv6BorderRelayPrefixLength, 24);
      });

      test('handles disabled IPv6rdTunnel mode', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.automaticIPv6Settings(
          ipv6rdTunnelMode: 'Disabled',
        );

        // Act
        final result = AutomaticIpv6Converter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv6rdTunnelMode, IPv6rdTunnelMode.disabled);
      });
    });

    group('toJNAP', () {
      test('converts Automatic IPv6 UI model to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
          isAutomatic: true,
        );

        // Act
        final result = AutomaticIpv6Converter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'Automatic');
        expect(result.ipv6AutomaticSettings?.isIPv6AutomaticEnabled, true);
      });

      test('converts IPv6 UI model with Manual 6rd tunnel settings', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
          isAutomatic: false, // Must be false for manual tunnel
          tunnelMode: IPv6rdTunnelMode.manual,
          prefix: '2001:db8::',
          prefixLength: 32,
          borderRelay: '192.0.2.1',
          borderRelayPrefixLength: 24,
        );

        // Act
        final result = AutomaticIpv6Converter.toJNAP(uiModel);

        // Assert
        expect(result.ipv6AutomaticSettings?.ipv6rdTunnelMode, 'Manual');
        expect(result.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefix,
            '2001:db8::');
        expect(result.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.prefixLength,
            32);
        expect(result.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.borderRelay,
            '192.0.2.1');
        expect(
            result.ipv6AutomaticSettings?.ipv6rdTunnelSettings
                ?.borderRelayPrefixLength,
            24);
      });
    });

    group('updateFromForm', () {
      test('updates IPv6 automatic settings from form data', () {
        // Arrange
        final currentSettings =
            InternetSettingsTestDataBuilder.automaticIPv6UIModel(
          isAutomatic: false,
        );
        final formData = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
          isAutomatic: true,
          tunnelMode: IPv6rdTunnelMode.manual,
          prefix: '2001:db8::',
          prefixLength: 32,
        );

        // Act
        final result =
            AutomaticIpv6Converter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.isIPv6AutomaticEnabled, true);
        expect(result.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
        expect(result.ipv6Prefix, '2001:db8::');
        expect(result.ipv6PrefixLength, 32);
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap =
            InternetSettingsTestDataBuilder.automaticIPv6Settings(
          isAutomatic: false,
          ipv6rdTunnelMode: 'Manual',
          prefix: '2001:db8::',
          prefixLength: 32,
          borderRelay: '192.0.2.1',
          borderRelayPrefixLength: 24,
          duid: 'test-duid',
        );

        // Act
        final uiModel = AutomaticIpv6Converter.fromJNAP(originalJnap);
        final convertedJnap = AutomaticIpv6Converter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.ipv6AutomaticSettings?.isIPv6AutomaticEnabled,
            originalJnap.ipv6AutomaticSettings?.isIPv6AutomaticEnabled);
        expect(convertedJnap.ipv6AutomaticSettings?.ipv6rdTunnelMode,
            originalJnap.ipv6AutomaticSettings?.ipv6rdTunnelMode);
      });
    });
  });
}
