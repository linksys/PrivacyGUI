import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/internet_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_data/internet_settings_test_data_builder.dart';

class MockInternetSettingsService extends Mock
    implements InternetSettingsService {}

void main() {
  late MockInternetSettingsService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockInternetSettingsService();
    SharedPreferences.setMockInitialValues({});

    container = ProviderContainer(
      overrides: [
        internetSettingsServiceProvider.overrideWithValue(mockService),
      ],
    );

    // Register fallback values for mocktail
    registerFallbackValue(
        InternetSettingsTestDataBuilder.internetSettingsUIModel());
  });

  tearDown(() {
    container.dispose();
  });

  group('InternetSettingsNotifier - fetch', () {
    test('performFetch successfully fetches and updates state', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(mtu: 1400),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );
      final status =
          InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(
        duid: 'test-duid',
        hostname: 'test-router',
      );

      when(() =>
              mockService.fetchSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (settings, status));

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.fetch(forceRemote: true);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.mtu, 1400);
      expect(state.settings.current.macClone, true);
      expect(state.status.duid, 'test-duid');
      verify(() => mockService.fetchSettings(forceRemote: true)).called(1);
    });

    test('performFetch handles ServiceError correctly', () async {
      // Arrange
      when(() =>
              mockService.fetchSettings(forceRemote: any(named: 'forceRemote')))
          .thenThrow(UnexpectedError(message: 'Network error'));

      // Act & Assert
      final notifier = container.read(internetSettingsProvider.notifier);
      expect(
        () => notifier.fetch(forceRemote: false),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('InternetSettingsNotifier - save', () {
    test('performSave successfully saves settings', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
      );

      container.read(internetSettingsProvider.notifier).state =
          container.read(internetSettingsProvider).copyWith(
                settings: container
                    .read(internetSettingsProvider)
                    .settings
                    .update(settings),
              );

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => {'hostName': 'myrouter', 'domain': 'local'});

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.save();

      // Assert
      verify(() => mockService.saveSettings(any())).called(1);
    });

    test('performSave handles bridge mode redirection', () async {
      // Arrange
      final bridgeSettings =
          InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel()
            .copyWith(ipv4ConnectionType: 'Bridge'),
      );

      container.read(internetSettingsProvider.notifier).state =
          container.read(internetSettingsProvider).copyWith(
                settings: container
                    .read(internetSettingsProvider)
                    .settings
                    .update(bridgeSettings),
              );

      when(() => mockService.saveSettings(any())).thenAnswer((_) async => null);

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.save();

      // Assert - Bridge mode should use hardcoded redirection
      verify(() => mockService.saveSettings(any())).called(1);
    });

    test('performSave handles ServiceError', () async {
      // Arrange
      when(() => mockService.saveSettings(any()))
          .thenThrow(UnexpectedError(message: 'Save failed'));

      // Act & Assert
      final notifier = container.read(internetSettingsProvider.notifier);
      expect(
        () => notifier.save(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('InternetSettingsNotifier - savePnpIpv4', () {
    test('savePnpIpv4 successfully saves and fetches', () async {
      // Arrange
      final settings =
          InternetSettingsTestDataBuilder.internetSettingsUIModel();
      final status =
          InternetSettingsTestDataBuilder.internetSettingsStatusUIModel();

      when(() => mockService.saveSettings(any())).thenAnswer((_) async => null);
      when(() =>
              mockService.fetchSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (settings, status));

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.savePnpIpv4(settings);

      // Assert
      verify(() => mockService.saveSettings(settings)).called(1);
      verify(() => mockService.fetchSettings(forceRemote: false)).called(1);
    });

    test('savePnpIpv4 handles ServiceError', () async {
      // Arrange
      final settings =
          InternetSettingsTestDataBuilder.internetSettingsUIModel();
      when(() => mockService.saveSettings(any()))
          .thenThrow(UnexpectedError(message: 'PnP save failed'));

      // Act & Assert
      final notifier = container.read(internetSettingsProvider.notifier);
      expect(
        () => notifier.savePnpIpv4(settings),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('InternetSettingsNotifier - utility methods', () {
    test('getMyMACAddress returns MAC address', () async {
      // Arrange
      when(() => mockService.getMyMACAddress())
          .thenAnswer((_) async => 'AA:BB:CC:DD:EE:FF');

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      final macAddress = await notifier.getMyMACAddress();

      // Assert
      expect(macAddress, 'AA:BB:CC:DD:EE:FF');
      verify(() => mockService.getMyMACAddress()).called(1);
    });

    test('renewDHCPWANLease calls service', () async {
      // Arrange
      when(() => mockService.renewDHCPWANLease())
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.renewDHCPWANLease();

      // Assert
      verify(() => mockService.renewDHCPWANLease()).called(1);
    });

    test('renewDHCPIPv6WANLease calls service', () async {
      // Arrange
      when(() => mockService.renewDHCPIPv6WANLease())
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(internetSettingsProvider.notifier);
      await notifier.renewDHCPIPv6WANLease();

      // Assert
      verify(() => mockService.renewDHCPIPv6WANLease()).called(1);
    });
  });

  group('InternetSettingsNotifier - state updates', () {
    test('updateStatus updates status in state', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final newStatus =
          InternetSettingsTestDataBuilder.internetSettingsStatusUIModel(
        duid: 'new-duid',
      );

      // Act
      notifier.updateStatus(newStatus);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.status.duid, 'new-duid');
      expect(state.isDirty, false); // Status update doesn't mark as dirty
    });

    test('updateMtu updates MTU value', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);

      // Act
      notifier.updateMtu(1500);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.mtu, 1500);
      expect(state.isDirty, true);
    });

    test('updateMacAddressCloneEnable enables MAC clone', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);

      // Act
      notifier.updateMacAddressCloneEnable(true);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.macClone, true);
      expect(state.isDirty, true);
    });

    test('updateMacAddressClone updates MAC address', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);

      // Act
      notifier.updateMacAddressClone('AA:BB:CC:DD:EE:FF');

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.macCloneAddress, 'AA:BB:CC:DD:EE:FF');
      expect(state.isDirty, true);
    });
  });

  group('InternetSettingsNotifier - updateIpv4Settings', () {
    test('updateIpv4Settings for DHCP', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final dhcpSetting =
          InternetSettingsTestDataBuilder.dhcpUIModel(mtu: 1400);

      // Act
      notifier.updateIpv4Settings(dhcpSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'DHCP');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings for PPPoE', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final pppoeSetting = InternetSettingsTestDataBuilder.pppoeUIModel(
        username: 'user',
        password: 'pass',
      );

      // Act
      notifier.updateIpv4Settings(pppoeSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'PPPoE');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings for Static', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final staticSetting = InternetSettingsTestDataBuilder.staticUIModel(
        ipAddress: '192.168.1.100',
        gateway: '192.168.1.1',
      );

      // Act
      notifier.updateIpv4Settings(staticSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'Static');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings for PPTP', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final pptpSetting =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'PPTP',
        username: () => 'user',
        password: () => 'pass',
        serverIp: () => '10.0.0.1',
      );

      // Act
      notifier.updateIpv4Settings(pptpSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'PPTP');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings for L2TP', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final l2tpSetting =
          InternetSettingsTestDataBuilder.pppoeUIModel().copyWith(
        ipv4ConnectionType: 'L2TP',
        username: () => 'user',
        password: () => 'pass',
        serverIp: () => '10.0.0.2',
      );

      // Act
      notifier.updateIpv4Settings(l2tpSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'L2TP');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings for Bridge', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final bridgeSetting = InternetSettingsTestDataBuilder.dhcpUIModel()
          .copyWith(ipv4ConnectionType: 'Bridge');

      // Act
      notifier.updateIpv4Settings(bridgeSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, 'Bridge');
      expect(state.isDirty, true);
    });

    test('updateIpv4Settings ignores invalid WAN type', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final invalidSetting = InternetSettingsTestDataBuilder.dhcpUIModel()
          .copyWith(ipv4ConnectionType: 'InvalidType');

      // Act
      notifier.updateIpv4Settings(invalidSetting);

      // Assert
      final state = container.read(internetSettingsProvider);
      // Should not update
      expect(state.settings.current.ipv4Setting.ipv4ConnectionType, '');
    });
  });

  group('InternetSettingsNotifier - updateIpv6Settings', () {
    test('updateIpv6Settings for Automatic', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final ipv6Setting = InternetSettingsTestDataBuilder.automaticIPv6UIModel(
        isAutomatic: false,
      );

      // Act
      notifier.updateIpv6Settings(ipv6Setting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(
          state.settings.current.ipv6Setting.ipv6ConnectionType, 'Automatic');
      expect(state.isDirty, true);
    });

    test('updateIpv6Settings for other types uses DefaultIpv6Converter', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);
      final ipv6Setting = InternetSettingsTestDataBuilder.defaultIPv6UIModel(
        connectionType: 'PPPoE',
      );

      // Act
      notifier.updateIpv6Settings(ipv6Setting);

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv6Setting.ipv6ConnectionType, 'PPPoE');
      expect(state.isDirty, true);
    });
  });

  group('InternetSettingsNotifier - setSettingsDefaultOnBridgeMode', () {
    test('setSettingsDefaultOnBrigdeMode resets to defaults', () {
      // Arrange
      final notifier = container.read(internetSettingsProvider.notifier);

      // Set some non-default values first
      notifier.updateMtu(1500);
      notifier.updateMacAddressCloneEnable(true);
      notifier.updateMacAddressClone('AA:BB:CC:DD:EE:FF');

      // Act
      notifier.setSettingsDefaultOnBrigdeMode();

      // Assert
      final state = container.read(internetSettingsProvider);
      expect(state.settings.current.ipv4Setting.mtu, 0);
      expect(state.settings.current.macClone, false);
      expect(state.settings.current.macCloneAddress, null);
      expect(
          state.settings.current.ipv6Setting.ipv6ConnectionType, 'Automatic');
    });
  });
}
