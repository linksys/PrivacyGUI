import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/ipv4/l2tp_converter.dart';

import '../../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  group('L2tpConverter', () {
    group('fromJNAP', () {
      test('converts L2TP JNAP model to UI model', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.l2tpWanSettings(
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: 'KeepAlive',
          reconnectAfterSeconds: 30,
        );

        // Act
        final result = L2tpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.ipv4ConnectionType, 'L2TP');
        expect(result.username, 'testuser');
        expect(result.password, 'testpass');
        expect(result.serverIp, '192.168.1.1');
        expect(result.behavior, PPPConnectionBehavior.keepAlive);
        expect(result.reconnectAfterSeconds, 30);
      });

      test('converts L2TP JNAP model with ConnectOnDemand', () {
        // Arrange
        final jnapModel = InternetSettingsTestDataBuilder.l2tpWanSettings(
          behavior: 'ConnectOnDemand',
          maxIdleMinutes: 10,
        );

        // Act
        final result = L2tpConverter.fromJNAP(jnapModel);

        // Assert
        expect(result.behavior, PPPConnectionBehavior.connectOnDemand);
        expect(result.maxIdleMinutes, 10);
      });
    });

    group('toJNAP', () {
      test('converts L2TP UI model to JNAP model', () {
        // Arrange
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'L2TP',
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: PPPConnectionBehavior.keepAlive,
          reconnectAfterSeconds: 30,
        );

        // Act
        final result = L2tpConverter.toJNAP(uiModel);

        // Assert
        expect(result.wanType, 'L2TP');
        expect(result.mtu, 1460);
        expect(result.tpSettings?.username, 'testuser');
        expect(result.tpSettings?.password, 'testpass');
        expect(result.tpSettings?.server, '192.168.1.1');
        expect(result.tpSettings?.behavior, 'KeepAlive');
        expect(result.tpSettings?.reconnectAfterSeconds, 30);
        expect(result.tpSettings?.maxIdleMinutes, isNull);
      });

      test('L2TP does not support static settings', () {
        // Arrange - even with useStaticSettings=true, L2TP ignores it
        final uiModel = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'L2TP',
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: PPPConnectionBehavior.keepAlive,
          useStaticSettings: true, // This should be ignored for L2TP
          staticIpAddress: '10.0.0.100',
        );

        // Act
        final result = L2tpConverter.toJNAP(uiModel);

        // Assert
        // L2TP should always have useStaticSettings=false
        expect(result.tpSettings?.useStaticSettings, false);
        expect(result.tpSettings?.staticSettings, isNull);
      });
    });

    group('updateFromForm', () {
      test('updates all L2TP-specific fields from form data', () {
        // Arrange
        final currentSettings = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'L2TP',
          mtu: 1460,
          username: 'olduser',
          serverIp: '192.168.1.1',
        );
        final formData = Ipv4SettingsUIModel(
          ipv4ConnectionType: 'L2TP',
          mtu: 1460,
          username: 'newuser',
          password: 'newpass',
          serverIp: '10.0.0.1',
          behavior: PPPConnectionBehavior.connectOnDemand,
          maxIdleMinutes: 20,
        );

        // Act
        final result = L2tpConverter.updateFromForm(currentSettings, formData);

        // Assert
        expect(result.username, 'newuser');
        expect(result.password, 'newpass');
        expect(result.serverIp, '10.0.0.1');
        expect(result.behavior, PPPConnectionBehavior.connectOnDemand);
        expect(result.maxIdleMinutes, 20);
      });
    });

    group('round-trip conversion', () {
      test('JNAP -> UI -> JNAP maintains data integrity', () {
        // Arrange
        final originalJnap = InternetSettingsTestDataBuilder.l2tpWanSettings(
          mtu: 1460,
          username: 'testuser',
          password: 'testpass',
          serverIp: '192.168.1.1',
          behavior: 'KeepAlive',
          reconnectAfterSeconds: 45,
        );

        // Act
        final uiModel = L2tpConverter.fromJNAP(originalJnap);
        final convertedJnap = L2tpConverter.toJNAP(uiModel);

        // Assert
        expect(convertedJnap.wanType, originalJnap.wanType);
        expect(convertedJnap.mtu, originalJnap.mtu);
        expect(convertedJnap.tpSettings?.username,
            originalJnap.tpSettings?.username);
        expect(convertedJnap.tpSettings?.password,
            originalJnap.tpSettings?.password);
        expect(
            convertedJnap.tpSettings?.server, originalJnap.tpSettings?.server);
        expect(convertedJnap.tpSettings?.behavior,
            originalJnap.tpSettings?.behavior);
      });
    });
  });
}