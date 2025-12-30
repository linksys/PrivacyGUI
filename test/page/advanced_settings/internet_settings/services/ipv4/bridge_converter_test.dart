import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/bridge_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('BridgeConverter', () {
    group('fromJNAP', () {
      test('converts Bridge JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.bridgeWanSettings();

        // Act
        final result = BridgeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'Bridge');
        expect(result.mtu, 0);
      });
    });

    group('toJNAP', () {
      test('converts Bridge UI model to JNAP model', () {
        // Arrange
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'Bridge',
          mtu: 0,
        );

        // Act
        final result = BridgeConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'Bridge');
        expect(result.mtu, 0);
        expect(result.bridgeSettings, isNotNull);
      });
    });

    group('updateFromForm', () {
      test('updates connection type from form data', () {
        // Arrange
        final currentSettings = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'Bridge',
          mtu: 0,
        );
        final formData = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'Bridge',
          mtu: 0,
        );

        // Act
        final result = BridgeConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.ipv4ConnectionType, 'Bridge');
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.bridgeWanSettings();

        // Act
        final uiModel = BridgeConverter.fromJNAP(originalJnap);
        final convertedJnap = BridgeConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
      });
    });
  });
}