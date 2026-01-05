import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_form_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

import '../../../../test_data/internet_settings_test_data_builder.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('InternetSettingsIPv4FormValidityNotifier', () {
    test('DHCP connection type is always valid', () {
      // Arrange
      final dhcpSettings = InternetSettingsTestDataBuilder.dhcpUIModel();
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: dhcpSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Bridge connection type is always valid', () {
      // Arrange
      final bridgeSettings = InternetSettingsTestDataBuilder.dhcpUIModel()
          .copyWith(ipv4ConnectionType: 'Bridge');
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: bridgeSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Static connection type with valid data is valid', () {
      // Arrange
      final staticSettings = InternetSettingsTestDataBuilder.staticUIModel(
        ipAddress: '192.168.1.100',
        gateway: '192.168.1.1',
        dns1: '8.8.8.8',
        dns2: '8.8.4.4',
        prefixLength: 24,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: staticSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Static connection type with invalid IP is invalid', () {
      // Arrange
      final invalidStaticSettings =
          InternetSettingsTestDataBuilder.staticUIModel(
        ipAddress: '999.999.999.999', // Invalid IP
        gateway: '192.168.1.1',
        dns1: '8.8.8.8',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: invalidStaticSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('PPPoE with username and password is valid', () {
      // Arrange
      final pppoeSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
        username: 'testuser',
        password: 'testpass',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: pppoeSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('PPPoE without username is invalid', () {
      // Arrange
      final invalidPppoeSettings = InternetSettingsTestDataBuilder.pppoeUIModel(
        username: '', // Empty username
        password: 'testpass',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: invalidPppoeSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('PPTP with valid settings is valid', () {
      // Arrange
      final pptpSettings =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'PPTP',
        username: () => 'testuser',
        password: () => 'testpass',
        serverIp: () => '192.168.1.1',
        useStaticSettings: () => false,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: pptpSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('PPTP with invalid server IP is invalid', () {
      // Arrange
      final invalidPptpSettings =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'PPTP',
        username: () => 'testuser',
        password: () => 'testpass',
        serverIp: () => 'invalid-ip',
        useStaticSettings: () => false,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: invalidPptpSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('PPTP with useStaticSettings requires valid static fields', () {
      // Arrange
      final pptpStaticSettings =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'PPTP',
        username: () => 'testuser',
        password: () => 'testpass',
        serverIp: () => '192.168.1.1',
        useStaticSettings: () => true,
        staticIpAddress: () => '192.168.1.100',
        staticGateway: () => '192.168.1.1',
        staticDns1: () => '8.8.8.8',
        networkPrefixLength: () => 24,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: pptpStaticSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('L2TP with valid settings is valid', () {
      // Arrange
      final l2tpSettings =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'L2TP',
        username: () => 'testuser',
        password: () => 'testpass',
        serverIp: () => '192.168.1.1',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: l2tpSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('L2TP with empty password is invalid', () {
      // Arrange
      final invalidL2tpSettings =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'L2TP',
        username: () => 'testuser',
        password: () => '', // Empty password
        serverIp: () => '192.168.1.1',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv4Setting: invalidL2tpSettings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv4FormValidityProvider);

      // Assert
      expect(isValid, false);
    });
  });

  group('InternetSettingsIPv6FormValidityNotifier', () {
    test('Automatic IPv6 with automatic mode is valid', () {
      // Arrange
      final ipv6Settings = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
        isAutomatic: true,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv6Setting: ipv6Settings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv6FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Manual 6rd tunnel mode with valid data is valid', () {
      // Arrange
      final ipv6Settings = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
        isAutomatic: true,
        tunnelMode: IPv6rdTunnelMode.manual,
        prefix: '2001:0db8:85a3::',
        prefixLength: 48,
        borderRelay: '192.168.1.1',
        borderRelayPrefixLength: 16,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv6Setting: ipv6Settings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv6FormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Manual 6rd tunnel mode with invalid prefix is invalid', () {
      // Arrange
      final ipv6Settings = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
        isAutomatic: true,
        tunnelMode: IPv6rdTunnelMode.manual,
        prefix: 'invalid-ipv6-prefix',
        prefixLength: 48,
        borderRelay: '192.168.1.1',
        borderRelayPrefixLength: 16,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv6Setting: ipv6Settings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv6FormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('Non-automatic IPv6 types are always valid', () {
      // Arrange
      final ipv6Settings = InternetSettingsTestDataBuilder.defaultIPv6UIModel(
        connectionType: 'PPPoE',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings: container.read(internetSettingsProvider).settings.update(
              InternetSettingsTestDataBuilder.internetSettingsUIModel(
                ipv6Setting: ipv6Settings,
              ),
            ),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(internetSettingsIPv6FormValidityProvider);

      // Assert
      expect(isValid, true);
    });
  });

  group('OptionalSettingsFormValidityNotifier', () {
    test('Settings with no MAC clone and valid MTU is valid', () {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(mtu: 1500),
        macClone: false,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings:
            container.read(internetSettingsProvider).settings.update(settings),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(optionalSettingsFormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Settings with valid MAC clone is valid', () {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings:
            container.read(internetSettingsProvider).settings.update(settings),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(optionalSettingsFormValidityProvider);

      // Assert
      expect(isValid, true);
    });

    test('Settings with invalid MAC clone is invalid', () {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
        macClone: true,
        macCloneAddress: 'invalid-mac',
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings:
            container.read(internetSettingsProvider).settings.update(settings),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(optionalSettingsFormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('Settings with MTU below minimum is invalid', () {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting:
            InternetSettingsTestDataBuilder.dhcpUIModel(mtu: 500), // Below 576
        macClone: false,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings:
            container.read(internetSettingsProvider).settings.update(settings),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(optionalSettingsFormValidityProvider);

      // Assert
      expect(isValid, false);
    });

    test('Settings with MTU of 0 is valid (auto)', () {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(mtu: 0),
        macClone: false,
      );
      container.read(internetSettingsProvider.notifier).state =
          InternetSettingsState(
        settings:
            container.read(internetSettingsProvider).settings.update(settings),
        status: InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(),
      );

      // Act
      final isValid = container.read(optionalSettingsFormValidityProvider);

      // Assert
      expect(isValid, true);
    });
  });
}
