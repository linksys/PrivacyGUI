import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/services/_services.dart';

class MockDDNSService extends Mock implements DDNSService {}

void main() {
  late MockDDNSService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockDDNSService();
    container = ProviderContainer(
      overrides: [
        ddnsServiceProvider.overrideWithValue(mockService),
      ],
    );

    // Register fallback values
    registerFallbackValue(
        const DDNSSettingsUIModel(provider: NoDDNSProviderUIModel()));
    registerFallbackValue(const NoDDNSProviderUIModel() as DDNSProviderUIModel);
  });

  tearDown(() {
    container.dispose();
  });

  group('DDNSNotifier - fetch', () {
    test('performFetch updates state with data from service', () async {
      // Arrange
      final settings = DDNSSettingsUIModel(
        provider: DynDNSProviderUIModel(
          username: 'user',
          password: 'pass',
          hostName: 'host.com',
        ),
      );
      final status = DDNSStatusUIModel(
        supportedProviders: const ['', 'DynDNS'],
        status: 'Connected',
        ipAddress: '192.168.1.1',
      );

      when(() =>
              mockService.fetchDDNSData(forceRemote: any(named: 'forceRemote')))
          .thenAnswer(
              (_) async => DDNSDataResult(settings: settings, status: status));

      // Act
      // We need to trigger the fetch via the PreservableNotifierMixin's fetchData
      // But since that's protected/mixed-in logic, we can also test performFetch directly if accessible,
      // or trigger via the init/refresh mechanism if exposed.
      // However, performFetch is exposed via the mixin interface or directly on the notifier class mechanism in testing.
      // Let's use the notifier to call performFetch directly via the mixin's public facing methods or just
      // observe the state change after calling refresh.
      // The standard way for our codebase seems to be calling fetch() from the mixin.

      final notifier = container.read(ddnsProvider.notifier);
      await notifier.fetch(forceRemote: true);

      // Assert
      final state = container.read(ddnsProvider);
      expect(state.current.provider, isA<DynDNSProviderUIModel>());
      expect(state.status.status, 'Connected');
      verify(() => mockService.fetchDDNSData(forceRemote: true)).called(1);
    });
  });

  group('DDNSNotifier - modifications', () {
    test('setProvider updates provider in state', () {
      // Arrange
      final notifier = container.read(ddnsProvider.notifier);

      // Act
      notifier.setProvider('DynDNS');

      // Assert
      final state = container.read(ddnsProvider);
      expect(state.current.provider, isA<DynDNSProviderUIModel>());
      expect(state.isDirty, true);
    });

    test('setProvider to None updates state', () {
      // Arrange
      final notifier = container.read(ddnsProvider.notifier);

      // Act
      notifier.setProvider(noDNSProviderName);

      // Assert
      final state = container.read(ddnsProvider);
      expect(state.current.provider, isA<NoDDNSProviderUIModel>());
    });

    test('setProviderSettings updates specific settings', () {
      // Arrange
      final notifier = container.read(ddnsProvider.notifier);
      notifier.setProvider('DynDNS'); // Set initial type

      final newSettings = DynDNSProviderUIModel(
        username: 'newuser',
        password: 'newpass',
        hostName: 'newhost.com',
      );

      // Act
      notifier.setProviderSettings(newSettings);

      // Assert
      final state = container.read(ddnsProvider);
      final provider = state.current.provider as DynDNSProviderUIModel;
      expect(provider.username, 'newuser');
      expect(provider.password, 'newpass');
      expect(provider.hostName, 'newhost.com');
      expect(state.isDirty, true);
    });
  });

  group('DDNSNotifier - save', () {
    test('performSave calls service saveDDNSSettings', () async {
      // Arrange
      when(() => mockService.saveDDNSSettings(any())).thenAnswer((_) async {});
      when(() =>
              mockService.fetchDDNSData(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => const DDNSDataResult(
              settings: DDNSSettingsUIModel(provider: NoDDNSProviderUIModel()),
              status: DDNSStatusUIModel(
                  supportedProviders: [], status: '', ipAddress: '')));

      final notifier = container.read(ddnsProvider.notifier);
      notifier.setProvider('DynDNS'); // Make it dirty so save is valid

      // Act
      await notifier.save();

      // Assert
      verify(() => mockService.saveDDNSSettings(any())).called(1);
    });
  });

  group('DDNSNotifier - status', () {
    test('getStatus refreshes status from service', () async {
      // Arrange
      when(() => mockService.refreshStatus())
          .thenAnswer((_) async => 'Updated Status');

      final notifier = container.read(ddnsProvider.notifier);

      // Act
      await notifier.getStatus();

      // Assert
      final state = container.read(ddnsProvider);
      expect(state.status.status, 'Updated Status');
      verify(() => mockService.refreshStatus()).called(1);
    });
  });

  group('DDNSNotifier - validation', () {
    test('isDataValid delegates to service', () {
      // Arrange
      when(() => mockService.validateSettings(any())).thenReturn(true);
      final notifier = container.read(ddnsProvider.notifier);

      // Act
      final result = notifier.isDataValid();

      // Assert
      expect(result, true);
      verify(() => mockService.validateSettings(any())).called(1);
    });

    test('isDataValid returns false when service validation fails', () {
      // Arrange
      when(() => mockService.validateSettings(any())).thenReturn(false);
      final notifier = container.read(ddnsProvider.notifier);

      // Act
      final result = notifier.isDataValid();

      // Assert
      expect(result, false);
      verify(() => mockService.validateSettings(any())).called(1);
    });
  });
}
