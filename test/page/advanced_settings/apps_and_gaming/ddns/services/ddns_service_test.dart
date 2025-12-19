import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/services/ddns_service.dart';

import '../../../../../mocks/test_data/ddns_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late DDNSService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.getDDNSSettings);
    registerFallbackValue(CommandType.local);
    registerFallbackValue(
        JNAPTransactionBuilder(commands: const [], auth: false));
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = DDNSService(mockRepository);
  });

  group('DDNSService - fetchDDNSData', () {
    test('returns DDNSDataResult with empty provider when no settings',
        () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess());

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.settings, isA<DDNSSettingsUIModel>());
      expect(result.settings.provider, isA<NoDDNSProviderUIModel>());
      expect(result.status, isA<DDNSStatusUIModel>());
      verify(() => mockRepository.transaction(any(),
          fetchRemote: any(named: 'fetchRemote'))).called(1);
    });

    test('returns DynDNS provider when configured', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                ddnsProvider: DDNSTestData.dynDNSProvider,
                dynDNSSettings: DDNSTestData.createDynDNSSettingsData(
                  username: 'dynuser',
                  password: 'dynpass',
                  hostName: 'my.dyndns.org',
                ),
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.settings.provider, isA<DynDNSProviderUIModel>());
      final provider = result.settings.provider as DynDNSProviderUIModel;
      expect(provider.username, 'dynuser');
      expect(provider.password, 'dynpass');
      expect(provider.hostName, 'my.dyndns.org');
    });

    test('returns NoIP provider when configured', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                ddnsProvider: DDNSTestData.noIPProvider,
                noIPSettings: DDNSTestData.createNoIPSettingsData(
                  username: 'noipuser',
                  password: 'noippass',
                  hostName: 'my.no-ip.org',
                ),
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.settings.provider, isA<NoIPDNSProviderUIModel>());
      final provider = result.settings.provider as NoIPDNSProviderUIModel;
      expect(provider.username, 'noipuser');
      expect(provider.password, 'noippass');
      expect(provider.hostName, 'my.no-ip.org');
    });

    test('returns TZO provider when configured', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                ddnsProvider: DDNSTestData.tzoProvider,
                tzoSettings: DDNSTestData.createTZOSettingsData(
                  username: 'tzouser',
                  password: 'tzopass',
                  hostName: 'my.tzo.com',
                ),
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.settings.provider, isA<TzoDNSProviderUIModel>());
      final provider = result.settings.provider as TzoDNSProviderUIModel;
      expect(provider.username, 'tzouser');
      expect(provider.password, 'tzopass');
      expect(provider.hostName, 'my.tzo.com');
    });

    test('returns supported providers list in status', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                supportedProviders: ['DynDNS', 'No-IP', 'TZO'],
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.status.supportedProviders, contains('DynDNS'));
      expect(result.status.supportedProviders, contains('No-IP'));
      expect(result.status.supportedProviders, contains('TZO'));
      expect(result.status.supportedProviders,
          contains(noDNSProviderName)); // disabled option
    });

    test('returns WAN IP address in status', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                wanIP: '203.0.113.42',
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.status.ipAddress, '203.0.113.42');
    });

    test('returns DDNS status string', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess(
                status: 'Successful',
              ));

      // Act
      final result = await service.fetchDDNSData();

      // Assert
      expect(result.status.status, 'Successful');
    });

    test('passes forceRemote flag correctly', () async {
      // Arrange
      when(() => mockRepository.transaction(any(), fetchRemote: true))
          .thenAnswer((_) async => DDNSTestData.createFetchDDNSDataSuccess());

      // Act
      await service.fetchDDNSData(forceRemote: true);

      // Assert
      verify(() => mockRepository.transaction(any(), fetchRemote: true))
          .called(1);
    });
  });

  group('DDNSService - saveDDNSSettings', () {
    test('sends correct JNAP action for DynDNS provider', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => DDNSTestData.createSetDDNSSettingsSuccess());

      final settings = DDNSSettingsUIModel(
        provider: DynDNSProviderUIModel(
          username: 'user1',
          password: 'pass1',
          hostName: 'host1.dyndns.org',
          isWildcardEnabled: true,
          mode: 'Static',
          isMailExchangeEnabled: false,
        ),
      );

      // Act
      await service.saveDDNSSettings(settings);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setDDNSSetting,
            data: any(named: 'data'),
            auth: true,
          )).called(1);
    });

    test('sends correct JNAP action for NoIP provider', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => DDNSTestData.createSetDDNSSettingsSuccess());

      final settings = DDNSSettingsUIModel(
        provider: const NoIPDNSProviderUIModel(
          username: 'noipuser',
          password: 'noippass',
          hostName: 'host.no-ip.org',
        ),
      );

      // Act
      await service.saveDDNSSettings(settings);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setDDNSSetting,
            data: any(named: 'data'),
            auth: true,
          )).called(1);
    });

    test('sends correct JNAP action for TZO provider', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => DDNSTestData.createSetDDNSSettingsSuccess());

      final settings = DDNSSettingsUIModel(
        provider: const TzoDNSProviderUIModel(
          username: 'tzouser',
          password: 'tzopass',
          hostName: 'host.tzo.com',
        ),
      );

      // Act
      await service.saveDDNSSettings(settings);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setDDNSSetting,
            data: any(named: 'data'),
            auth: true,
          )).called(1);
    });

    test('sends correct JNAP action for disabled DDNS', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => DDNSTestData.createSetDDNSSettingsSuccess());

      const settings = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );

      // Act
      await service.saveDDNSSettings(settings);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setDDNSSetting,
            data: any(named: 'data'),
            auth: true,
          )).called(1);
    });
  });

  group('DDNSService - refreshStatus', () {
    test('returns status string from JNAP response', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              DDNSTestData.createGetDDNSStatusSuccess(status: 'Connected'));

      // Act
      final result = await service.refreshStatus();

      // Assert
      expect(result, 'Connected');
      verify(() => mockRepository.send(
            JNAPAction.getDDNSStatus,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });

    test('returns empty string when status is null', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) async => DDNSTestData.createGetDDNSStatusSuccess());

      // Act
      final result = await service.refreshStatus();

      // Assert
      expect(result, 'Unknown');
    });
  });

  group('DDNSService - validateSettings', () {
    test('returns true for NoDDNSProvider', () {
      // Arrange
      const provider = NoDDNSProviderUIModel();

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, true);
    });

    test('returns true for DynDNS with all fields filled', () {
      // Arrange
      final provider = DynDNSProviderUIModel(
        username: 'user',
        password: 'pass',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, true);
    });

    test('returns false for DynDNS with empty username', () {
      // Arrange
      final provider = DynDNSProviderUIModel(
        username: '',
        password: 'pass',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, false);
    });

    test('returns false for DynDNS with empty password', () {
      // Arrange
      final provider = DynDNSProviderUIModel(
        username: 'user',
        password: '',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, false);
    });

    test('returns false for DynDNS with empty hostname', () {
      // Arrange
      final provider = DynDNSProviderUIModel(
        username: 'user',
        password: 'pass',
        hostName: '',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, false);
    });

    test('returns true for NoIP with all fields filled', () {
      // Arrange
      const provider = NoIPDNSProviderUIModel(
        username: 'user',
        password: 'pass',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, true);
    });

    test('returns false for NoIP with empty fields', () {
      // Arrange
      const provider = NoIPDNSProviderUIModel(
        username: '',
        password: 'pass',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, false);
    });

    test('returns true for TZO with all fields filled', () {
      // Arrange
      const provider = TzoDNSProviderUIModel(
        username: 'user',
        password: 'pass',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, true);
    });

    test('returns false for TZO with empty fields', () {
      // Arrange
      const provider = TzoDNSProviderUIModel(
        username: 'user',
        password: '',
        hostName: 'host.com',
      );

      // Act
      final result = service.validateSettings(provider);

      // Assert
      expect(result, false);
    });
  });
}
