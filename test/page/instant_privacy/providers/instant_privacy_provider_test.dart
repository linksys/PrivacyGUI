import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

import '../../../common/di.dart';

// Mocks
class MockInstantPrivacyService extends Mock implements InstantPrivacyService {}

class MockDeviceManagerNotifier extends DeviceManagerNotifier {
  MockDeviceManagerNotifier();
}

// Fallback values for mocktail
class FakeInstantPrivacySettings extends Fake
    implements InstantPrivacySettings {}

class FakeLinksysDevice extends Fake implements LinksysDevice {}

void main() {
  late MockInstantPrivacyService mockService;
  late ProviderContainer container;

  setUpAll(() {
    mockDependencyRegister();
    registerFallbackValue(FakeInstantPrivacySettings());
    registerFallbackValue(<LinksysDevice>[]);
  });

  setUp(() {
    mockService = MockInstantPrivacyService();

    // Default stub for fetchMacFilterSettings (called during build)
    when(() => mockService.fetchMacFilterSettings(
          forceRemote: any(named: 'forceRemote'),
          updateStatusOnly: any(named: 'updateStatusOnly'),
        )).thenAnswer((_) async => (
          const InstantPrivacySettings(
            mode: MacFilterMode.disabled,
            macAddresses: [],
            denyMacAddresses: [],
            maxMacAddresses: 32,
            bssids: [],
          ),
          const InstantPrivacyStatus(mode: MacFilterMode.disabled),
        ));

    // Default stub for fetchMyMacAddress
    when(() => mockService.fetchMyMacAddress(any()))
        .thenAnswer((_) async => null);

    // Default stub for saveMacFilterSettings
    when(() => mockService.saveMacFilterSettings(any(), any()))
        .thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        instantPrivacyServiceProvider.overrideWithValue(mockService),
        deviceManagerProvider.overrideWith(() => MockDeviceManagerNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ===========================================================================
  // User Story 1 - Provider delegates to Service Tests (T027-T029)
  // ===========================================================================

  group('InstantPrivacyNotifier - delegates to service', () {
    test('performFetch delegates to service.fetchMacFilterSettings', () async {
      // Arrange
      const expectedSettings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: [],
      );
      const expectedStatus = InstantPrivacyStatus(mode: MacFilterMode.allow);

      when(() => mockService.fetchMacFilterSettings(
            forceRemote: any(named: 'forceRemote'),
            updateStatusOnly: any(named: 'updateStatusOnly'),
          )).thenAnswer((_) async => (expectedSettings, expectedStatus));

      when(() => mockService.fetchMyMacAddress(any()))
          .thenAnswer((_) async => 'AA:BB:CC:DD:EE:FF');

      // Act - get notifier and wait for initial fetch to complete
      final notifier = container.read(instantPrivacyProvider.notifier);
      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      // Clear interactions from initial build fetch
      clearInteractions(mockService);

      // Now call performFetch explicitly
      final result = await notifier.performFetch();

      // Assert - verify our explicit call
      verify(() => mockService.fetchMacFilterSettings(
            forceRemote: false,
            updateStatusOnly: false,
          )).called(1);

      expect(result.$1, isNotNull);
      expect(result.$2, isNotNull);
      expect(result.$1!.mode, MacFilterMode.allow);
    });

    test('performFetch passes forceRemote parameter to service', () async {
      // Arrange - get notifier first
      final notifier = container.read(instantPrivacyProvider.notifier);
      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      // Clear interactions from initial build fetch
      clearInteractions(mockService);

      when(() => mockService.fetchMacFilterSettings(
            forceRemote: true,
            updateStatusOnly: any(named: 'updateStatusOnly'),
          )).thenAnswer((_) async => (
            const InstantPrivacySettings(
              mode: MacFilterMode.allow,
              macAddresses: [],
              denyMacAddresses: [],
              maxMacAddresses: 32,
              bssids: [],
            ),
            const InstantPrivacyStatus(mode: MacFilterMode.allow),
          ));

      when(() => mockService.fetchMyMacAddress(any()))
          .thenAnswer((_) async => null);

      // Act
      await notifier.performFetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchMacFilterSettings(
            forceRemote: true,
            updateStatusOnly: false,
          )).called(1);
    });

    test('performFetch passes updateStatusOnly parameter to service', () async {
      // Arrange - get notifier first
      final notifier = container.read(instantPrivacyProvider.notifier);
      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      // Clear interactions from initial build fetch
      clearInteractions(mockService);

      when(() => mockService.fetchMacFilterSettings(
            forceRemote: any(named: 'forceRemote'),
            updateStatusOnly: true,
          )).thenAnswer((_) async => (
            null,
            const InstantPrivacyStatus(mode: MacFilterMode.deny),
          ));

      // Act
      await notifier.performFetch(updateStatusOnly: true);

      // Assert
      verify(() => mockService.fetchMacFilterSettings(
            forceRemote: false,
            updateStatusOnly: true,
          )).called(1);

      // fetchMyMacAddress should NOT be called when updateStatusOnly is true
      verifyNever(() => mockService.fetchMyMacAddress(any()));
    });

    test('performSave delegates to service.saveMacFilterSettings', () async {
      // Arrange - get notifier and let initial fetch complete
      final notifier = container.read(instantPrivacyProvider.notifier);
      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      // Clear interactions from initial build fetch
      clearInteractions(mockService);

      when(() => mockService.saveMacFilterSettings(
            any(),
            any(),
          )).thenAnswer((_) async {});

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveMacFilterSettings(
            any(),
            any(),
          )).called(1);
    });

    test('getMyMACAddress delegates to service.fetchMyMacAddress', () async {
      // Arrange - get notifier first
      final notifier = container.read(instantPrivacyProvider.notifier);
      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      // Clear interactions from initial build fetch
      clearInteractions(mockService);

      when(() => mockService.fetchMyMacAddress(any()))
          .thenAnswer((_) async => 'AA:BB:CC:DD:EE:FF');

      // Act
      final result = await notifier.getMyMACAddress();

      // Assert
      verify(() => mockService.fetchMyMacAddress(any())).called(1);
      expect(result, 'AA:BB:CC:DD:EE:FF');
    });
  });
}
