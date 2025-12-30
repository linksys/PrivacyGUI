import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/pppoe_converter.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('PppoeConverter', () {
    group('fromJNAP', () {
      test('converts PPPoE JNAP model with KeepAlive to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pppoeWanSettings(
          mtu: 1492,
          behavior: 'KeepAlive',
          reconnectAfterSeconds: 30,
          username: 'testuser',
          password: 'testpass',
          serviceName: 'testservice',
        );

        // Act
        final result = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'PPPoE');
        expect(result.mtu, 1492);
        expect(result.behavior, PPPConnectionBehavior.keepAlive);
        expect(result.reconnectAfterSeconds, 30);
        expect(result.username, 'testuser');
        expect(result.password, 'testpass');
        expect(result.serviceName, 'testservice');
      });

      test('converts PPPoE JNAP model with ConnectOnDemand to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pppoeWanSettings(
          behavior: 'ConnectOnDemand',
          maxIdleMinutes: 10,
          username: 'user2',
          password: 'pass2',
        );

        // Act
        final result = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.behavior, PPPConnectionBehavior.connectOnDemand);
        expect(result.maxIdleMinutes, 10);
        expect(result.username, 'user2');
        expect(result.password, 'pass2');
      });

      test('handles PPPoE with VLAN tagging enabled', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pppoeWanSettings(
          wanTaggingEnabled: true,
          vlanId: 100,
        );

        // Act
        final result = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.wanTaggingSettingsEnable, true);
        expect(result.vlanId, 100);
      });

      test('handles PPPoE with VLAN tagging disabled', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.pppoeWanSettings(
          wanTaggingEnabled: false,
        );

        // Act
        final result = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.wanTaggingSettingsEnable, false);
      });

      test('uses default values for null PPPoE settings', () {
        // Arrange
        final jnapModel = RouterWANSettings(
          wanType: 'PPPoE',
          mtu: 0,
        );

        // Act
        final result = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'PPPoE');
        expect(result.behavior, PPPConnectionBehavior.keepAlive);
        expect(result.maxIdleMinutes, 15);
        expect(result.reconnectAfterSeconds, 30);
      });
    });

    group('toJNAP', () {
      test('converts PPPoE UI model with KeepAlive to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          mtu: 1492,
          behavior: PPPConnectionBehavior.keepAlive,
          reconnectAfterSeconds: 30,
          username: 'testuser',
          password: 'testpass',
          serviceName: 'testservice',
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'PPPoE');
        expect(result.mtu, 1492);
        expect(result.pppoeSettings?.behavior, 'KeepAlive');
        expect(result.pppoeSettings?.reconnectAfterSeconds, 30);
        expect(result.pppoeSettings?.maxIdleMinutes, isNull);
        expect(result.pppoeSettings?.username, 'testuser');
        expect(result.pppoeSettings?.password, 'testpass');
        expect(result.pppoeSettings?.serviceName, 'testservice');
      });

      test('converts PPPoE UI model with ConnectOnDemand to JNAP model', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          behavior: PPPConnectionBehavior.connectOnDemand,
          maxIdleMinutes: 10,
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.pppoeSettings?.behavior, 'ConnectOnDemand');
        expect(result.pppoeSettings?.maxIdleMinutes, 10);
        expect(result.pppoeSettings?.reconnectAfterSeconds, isNull);
      });

      test('converts PPPoE UI model with valid VLAN ID to enabled tagging', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          wanTaggingEnabled: true,
          vlanId: 100,
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanTaggingSettings?.isEnabled, true);
        expect(result.wanTaggingSettings?.vlanTaggingSettings?.vlanID, 100);
        expect(result.wanTaggingSettings?.vlanTaggingSettings?.vlanStatus,
            'Tagged');
      });

      test('disables VLAN tagging when VLAN ID is out of range (< 5)', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          vlanId: 4,
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanTaggingSettings?.isEnabled, false);
      });

      test('disables VLAN tagging when VLAN ID is out of range (> 4094)', () {
        // Arrange
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          vlanId: 4095,
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanTaggingSettings?.isEnabled, false);
      });

      test('uses empty strings for null credentials', () {
        // Arrange
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPPoE',
          mtu: 0,
          behavior: PPPConnectionBehavior.keepAlive,
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(result.pppoeSettings?.username, '');
        expect(result.pppoeSettings?.password, '');
        expect(result.pppoeSettings?.serviceName, '');
      });

      test('validates MTU and resets to 0 if invalid', () {
        // Arrange - MTU out of valid range for PPPoE
        final uiModel = InternetSettingsTestDataBuilder.pppoeUIModel(
          mtu: 10000, // Invalid MTU
        );

        // Act
        final result = PppoeConverter.toJNAP(uiModel);

        // Assert
        // MTU should be reset to 0 if invalid
        expect(result.mtu, 0);
      });
    });

    group('updateFromForm', () {
      test('updates all PPPoE-specific fields from form data', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
          username: 'olduser',
          password: 'oldpass',
          serviceName: 'oldservice',
          behavior: PPPConnectionBehavior.keepAlive,
          reconnectAfterSeconds: 30,
        );
        final formData = InternetSettingsTestDataBuilder.pppoeUIModel(
          username: 'newuser',
          password: 'newpass',
          serviceName: 'newservice',
          behavior: PPPConnectionBehavior.connectOnDemand,
          maxIdleMinutes: 20,
        );

        // Act
        final result = PppoeConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.ipv4ConnectionType, 'PPPoE');
        expect(result.username, 'newuser');
        expect(result.password, 'newpass');
        expect(result.serviceName, 'newservice');
        expect(result.behavior, PPPConnectionBehavior.connectOnDemand);
        expect(result.maxIdleMinutes, 20);
      });

      test('updates VLAN settings from form data', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
          wanTaggingEnabled: false,
          vlanId: 0,
        );
        final formData = InternetSettingsTestDataBuilder.pppoeUIModel(
          wanTaggingEnabled: true,
          vlanId: 100,
        );

        // Act
        final result = PppoeConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.wanTaggingSettingsEnable, true);
        expect(result.vlanId, 100);
      });

      test('uses default behavior when form data has null', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
          behavior: PPPConnectionBehavior.connectOnDemand,
        );
        final formData = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPPoE',
          mtu: 0,
          username: 'user',
          password: 'pass',
        );

        // Act
        final result = PppoeConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.behavior, PPPConnectionBehavior.keepAlive);
      });

      test('preserves non-PPPoE fields from current settings', () {
        // Arrange
        final currentSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
          mtu: 1492,
        );
        final formData = InternetSettingsTestDataBuilder.pppoeUIModel(
          username: 'newuser',
        );

        // Act
        final result = PppoeConverter.updateFromForm(currentSettings, formData);

        // Assert
        // MTU is not updated by updateFromForm
        expect(result.mtu, 1492);
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity for KeepAlive', () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.pppoeWanSettings(
          mtu: 1492,
          behavior: 'KeepAlive',
          reconnectAfterSeconds: 45,
          username: 'testuser',
          password: 'testpass',
          serviceName: 'myservice',
          wanTaggingEnabled: true,
          vlanId: 100,
        );

        // Act
        final uiModel = PppoeConverter.fromJNAP(originalJnap);
        final convertedJnap = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
        expect(convertedJnap.pppoeSettings?.behavior,
            originalJnap.pppoeSettings?.behavior);
        expect(convertedJnap.pppoeSettings?.reconnectAfterSeconds,
            originalJnap.pppoeSettings?.reconnectAfterSeconds);
        expect(convertedJnap.pppoeSettings?.username,
            originalJnap.pppoeSettings?.username);
        expect(convertedJnap.pppoeSettings?.password,
            originalJnap.pppoeSettings?.password);
        expect(convertedJnap.pppoeSettings?.serviceName,
            originalJnap.pppoeSettings?.serviceName);
        expect(convertedJnap.wanTaggingSettings?.isEnabled,
            originalJnap.wanTaggingSettings?.isEnabled);
      });

      test('JNAP -> UI -> JNAP maintains data integrity for ConnectOnDemand',
          () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.pppoeWanSettings(
          behavior: 'ConnectOnDemand',
          maxIdleMinutes: 20,
        );

        // Act
        final uiModel = PppoeConverter.fromJNAP(originalJnap);
        final convertedJnap = PppoeConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.pppoeSettings?.behavior, 'ConnectOnDemand');
        expect(convertedJnap.pppoeSettings?.maxIdleMinutes, 20);
      });

      test('UI -> JNAP -> UI maintains data integrity', () {
        // Arrange
        final originalUi = InternetSettingsTestDataBuilder.pppoeUIModel(
          mtu: 1492,
          behavior: PPPConnectionBehavior.keepAlive,
          reconnectAfterSeconds: 30,
          username: 'testuser',
          password: 'testpass',
          serviceName: 'myservice',
          wanTaggingEnabled: true,
          vlanId: 100,
        );

        // Act
        final jnapModel = PppoeConverter.toJNAP(originalUi);
        final convertedUi = PppoeConverter.fromJNAP(jnapModel);

        // Assert
        expect(convertedUi.ipv4ConnectionType, originalUi.ipv4ConnectionType);
        expect(convertedUi.mtu, originalUi.mtu);
        expect(convertedUi.behavior, originalUi.behavior);
        expect(convertedUi.reconnectAfterSeconds,
            originalUi.reconnectAfterSeconds);
        expect(convertedUi.username, originalUi.username);
        expect(convertedUi.password, originalUi.password);
        expect(convertedUi.serviceName, originalUi.serviceName);
        expect(convertedUi.wanTaggingSettingsEnable,
            originalUi.wanTaggingSettingsEnable);
        expect(convertedUi.vlanId, originalUi.vlanId);
      });
    });
  });
}
