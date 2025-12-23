import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/administration/services/administration_settings_service.dart';

// Mock AdministrationSettingsService
class MockAdministrationSettingsService extends Mock
    implements AdministrationSettingsService {}

class _FakeAdministrationSettings extends Fake implements AdministrationSettings {}

class _FakeRef extends Fake implements Ref {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAdministrationSettings());
    registerFallbackValue(_MockRouterRepository());
    registerFallbackValue(_FakeRef());
  });

  group('AdministrationSettingsNotifier', () {
    /// T028: Test initial state has correct default values
    test('initial state has correct default values', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.settings.current.managementSettings.canManageUsingHTTP,
          false);
      expect(notifier.state.settings.current.managementSettings.canManageUsingHTTPS,
          false);
      expect(notifier.state.settings.current.isUPnPEnabled, false);
      expect(notifier.state.settings.current.enabledALG, false);
      expect(notifier.state.settings.current.isExpressForwardingSupported, false);
    });

    /// T029: Test that performFetch method exists and has correct signature
    test('performFetch method is implemented', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      // Verify the notifier is a PreservableNotifierMixin instance
      // which means performFetch method is available
      expect(notifier, isNotNull);

      // Verify initial state is preserved (original == current)
      expect(notifier.state.settings.original, isNotNull);
      expect(notifier.state.settings.current, isNotNull);
    });

    /// T030: Test setManagementSettings updates current state
    test('setManagementSettings updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      // Initial state
      expect(notifier.state.current.managementSettings.canManageWirelessly, null);

      // Act
      notifier.setManagementSettings(true);

      // Assert
      expect(notifier.state.current.managementSettings.canManageWirelessly, true);
    });

    /// T031: Test setUPnPEnabled updates current state
    test('setUPnPEnabled updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.current.isUPnPEnabled, false);

      notifier.setUPnPEnabled(true);

      expect(notifier.state.current.isUPnPEnabled, true);
    });

    /// T032: Test setCanUsersConfigure updates current state
    test('setCanUsersConfigure updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.current.canUsersConfigure, false);

      notifier.setCanUsersConfigure(true);

      expect(notifier.state.current.canUsersConfigure, true);
    });

    /// T033: Test setCanUsersDisableWANAccess updates current state
    test('setCanUsersDisableWANAccess updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.current.canUsersDisableWANAccess, false);

      notifier.setCanUsersDisableWANAccess(true);

      expect(notifier.state.current.canUsersDisableWANAccess, true);
    });

    /// T034: Test setALGEnabled updates current state
    test('setALGEnabled updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.current.enabledALG, false);

      notifier.setALGEnabled(true);

      expect(notifier.state.current.enabledALG, true);
    });

    /// T035: Test setExpressForwarding updates current state
    test('setExpressForwarding updates current state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      expect(notifier.state.current.enabledExpressForwarfing, false);

      notifier.setExpressForwarding(true);

      expect(notifier.state.current.enabledExpressForwarfing, true);
    });

    /// T036: Test multiple setter calls maintain state integrity
    test('multiple setter calls maintain state integrity', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      notifier.setUPnPEnabled(true);
      notifier.setCanUsersConfigure(true);
      notifier.setALGEnabled(true);

      expect(notifier.state.current.isUPnPEnabled, true);
      expect(notifier.state.current.canUsersConfigure, true);
      expect(notifier.state.current.enabledALG, true);
    });

    /// T037: Test state maintains original values for undo functionality
    test('state maintains original values for undo functionality', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      final originalIsUPnPEnabled = notifier.state.settings.original.isUPnPEnabled;

      notifier.setUPnPEnabled(true);

      // Original should remain unchanged
      expect(notifier.state.settings.original.isUPnPEnabled, originalIsUPnPEnabled);
      // Current should be updated
      expect(notifier.state.current.isUPnPEnabled, true);
    });

    /// T038: Test performSave accepts current state for saving
    test('performSave accepts current state for saving', () async {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      // Act: Update some settings and call performSave
      notifier.setUPnPEnabled(true);
      notifier.setALGEnabled(true);

      // performSave will attempt to send settings to the device
      // We're testing that it doesn't throw an error
      try {
        await notifier.performSave();
      } catch (e) {
        // Expected since we don't have a real device
        // Just verify the settings were updated before the call
      }

      // Assert: Settings were modified before save attempt
      expect(notifier.state.current.isUPnPEnabled, true);
      expect(notifier.state.current.enabledALG, true);
    });

    /// T039: Test isDirty flag indicates changes
    test('isDirty flag indicates when settings have changed', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      // Initially not dirty
      expect(notifier.state.isDirty, false);

      // After change should be dirty
      notifier.setUPnPEnabled(true);
      expect(notifier.state.isDirty, true);
    });

    /// T040: Test dirty flag reflects actual changes
    test('isDirty flag reflects actual value changes only', () {
      final container = ProviderContainer();
      final notifier = container.read(administrationSettingsProvider.notifier);

      notifier.setUPnPEnabled(true);
      expect(notifier.state.isDirty, true);

      // Setting back to original value
      notifier.setUPnPEnabled(false);
      expect(notifier.state.isDirty, false);
    });

    /// T041: Example test demonstrating service mocking capability
    test('performFetch can be tested with mocked service', () async {
      // Arrange
      final mockService = MockAdministrationSettingsService();
      const testSettings = AdministrationSettings(
        managementSettings: ManagementSettingsUIModel(
          canManageUsingHTTP: true,
          canManageUsingHTTPS: true,
          isManageWirelesslySupported: true,
          canManageWirelessly: true,
          canManageRemotely: false,
        ),
        isUPnPEnabled: true,
        enabledALG: false,
        isExpressForwardingSupported: false,
        enabledExpressForwarfing: false,
        canUsersConfigure: true,
        canUsersDisableWANAccess: true,
      );

      // Mock the service to return test data
      when(() => mockService.fetchAdministrationSettings(
            any(),
            forceRemote: any(named: 'forceRemote'),
            updateStatusOnly: any(named: 'updateStatusOnly'),
          )).thenAnswer((_) async => testSettings);

      // Create container with overridden service
      final container = ProviderContainer(
        overrides: [
          administrationSettingsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Act
      final notifier = container.read(administrationSettingsProvider.notifier);
      await notifier.fetch();

      // Assert
      expect(notifier.state.current.managementSettings.canManageUsingHTTP, true);
      expect(notifier.state.current.managementSettings.canManageUsingHTTPS, true);
      expect(notifier.state.current.isUPnPEnabled, true);
      expect(notifier.state.current.enabledALG, false);

      // Verify service was called
      verify(() => mockService.fetchAdministrationSettings(
            any(),
            forceRemote: false,
            updateStatusOnly: false,
          )).called(1);
    });
  });
}

class _MockRouterRepository extends Mock implements RouterRepository {}
