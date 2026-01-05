import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv6/default_ipv6_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('DefaultIpv6Converter', () {
    group('fromJNAP', () {
      test('converts PPPoE IPv6 JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.defaultIPv6Settings(
          wanType: 'PPPoE',
          isAutomatic: false,
        );

        // Act
        final result =
            DefaultIpv6Converter.fromJNAP(jnapModel, WanIPv6Type.pppoe);

        // Assert
        expect(result.ipv6ConnectionType, 'PPPoE');
        expect(result.isIPv6AutomaticEnabled, false);
      });

      test('converts Pass-through IPv6 JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.defaultIPv6Settings(
          wanType: 'Pass-through',
        );

        // Act
        final result =
            DefaultIpv6Converter.fromJNAP(jnapModel, WanIPv6Type.passThrough);

        // Assert
        expect(result.ipv6ConnectionType, 'Pass-through');
      });
    });

    group('toJNAP', () {
      test('converts PPPoE IPv6 UI model to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.defaultIPv6UIModel(
          connectionType: 'PPPoE',
        );

        // Act
        final result = DefaultIpv6Converter.toJNAP(uiModel, WanIPv6Type.pppoe);

        // Assert
        expect(result.wanType, 'PPPoE');
      });

      test('converts Pass-through IPv6 UI model to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.defaultIPv6UIModel(
          connectionType: 'Pass-through',
        );

        // Act
        final result =
            DefaultIpv6Converter.toJNAP(uiModel, WanIPv6Type.passThrough);

        // Assert
        expect(result.wanType, 'Pass-through');
      });
    });

    group('updateFromForm', () {
      test('updates connection type from form data', () {
        // Arrange
        final currentSettings =
            InternetSettingsTestDataBuilder.defaultIPv6UIModel(
          connectionType: 'PPPoE',
        );
        final formData = InternetSettingsTestDataBuilder.defaultIPv6UIModel(
          connectionType: 'Pass-through',
        );

        // Act
        final result =
            DefaultIpv6Converter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.ipv6ConnectionType, 'Pass-through');
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap =
            InternetSettingsTestDataBuilder.defaultIPv6Settings(
          wanType: 'PPPoE',
          duid: 'test-duid',
        );

        // Act
        final uiModel =
            DefaultIpv6Converter.fromJNAP(originalJnap, WanIPv6Type.pppoe);
        final convertedJnap =
            DefaultIpv6Converter.toJNAP(uiModel, WanIPv6Type.pppoe);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
      });
    });
  });
}
