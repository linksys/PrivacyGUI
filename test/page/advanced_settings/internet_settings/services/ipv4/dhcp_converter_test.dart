import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/dhcp_converter.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('DhcpConverter', () {
    group('fromJNAP', () {
      test('converts DHCP JNAP model to UI model with default MTU', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.dhcpWanSettings();

        // Act
        final result = DhcpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'DHCP');
        expect(result.mtu, 0);
      });

      test('converts DHCP JNAP model to UI model with custom MTU', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.dhcpWanSettings(
          mtu: 1492,
        );

        // Act
        final result = DhcpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'DHCP');
        expect(result.mtu, 1492);
      });

      test('handles DHCP JNAP model with WAN tagging settings', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.dhcpWanSettings(
          mtu: 1500,
          wanTaggingSettings: const SinglePortVLANTaggingSettings(
            isEnabled: true,
            vlanTaggingSettings: PortTaggingSettings(
              vlanID: 100,
              vlanStatus: 'Tagged',
            ),
          ),
        );

        // Act
        final result = DhcpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'DHCP');
        expect(result.mtu, 1500);
        // Note: DHCP converter doesn't extract VLAN settings
      });
    });

    group('toJNAP', () {
      test('converts DHCP UI model to JNAP model with default MTU', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.dhcpUIModel();

        // Act
        final result = DhcpConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'DHCP');
        expect(result.mtu, 0);
        expect(result.pppoeSettings, isNull);
        expect(result.tpSettings, isNull);
        expect(result.staticSettings, isNull);
        expect(result.bridgeSettings, isNull);
      });

      test('converts DHCP UI model to JNAP model with custom MTU', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1492,
        );

        // Act
        final result = DhcpConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'DHCP');
        expect(result.mtu, 1492);
      });
    });

    group('updateFromForm', () {
      test('updates connection type from form data', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1492,
        );
        final formData = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1500,
        );

        // Act
        final result = DhcpConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.ipv4ConnectionType, 'DHCP');
        // Note: updateFromForm currently only updates ipv4ConnectionType,
        // MTU and other fields are preserved from currentSettings
        expect(result.mtu, 1492); // unchanged from current
      });

      test('preserves all fields except connection type', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1492,
        );
        final formData = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1500,
        );

        // Act
        final result = DhcpConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.ipv4ConnectionType, 'DHCP');
        expect(result.mtu, 1492); // preserved from current settings
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.dhcpWanSettings(
          mtu: 1492,
        );

        // Act
        final uiModel = DhcpConverter.fromJNAP(originalJnap);
        final convertedJnap = DhcpConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
      });

      test('UI -> JNAP -> UI maintains data integrity', () {
        // Arrange
        final originalUi = InternetSettingsTestDataBuilder.dhcpUIModel(
          mtu: 1500,
        );

        // Act
        final jnapModel = DhcpConverter.toJNAP(originalUi);
        final convertedUi = DhcpConverter.fromJNAP(jnapModel);

        // Assert
        expect(convertedUi.ipv4ConnectionType, originalUi.ipv4ConnectionType);
        expect(convertedUi.mtu, originalUi.mtu);
      });
    });
  });
}