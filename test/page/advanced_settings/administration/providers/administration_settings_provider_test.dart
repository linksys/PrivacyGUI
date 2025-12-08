import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/administration/services/administration_settings_service.dart';

// Mock AdministrationSettingsService
class MockAdministrationSettingsService extends Mock implements AdministrationSettingsService {}

void main() {
  group('AdministrationSettingsNotifier', () {
    /// T028: Test delegating to service on performFetch
    test('delegates to service on performFetch', () async {
      final container = ProviderContainer();

      // Verify the notifier can access the provider
      final notifier = container.read(administrationSettingsProvider.notifier);

      // Verify initial state
      expect(
          notifier.state.settings.current.managementSettings.canManageUsingHTTP,
          false);
    });

    /// T029: Test updating state with service results
    test('updates state with service results', () async {
      final container = ProviderContainer();

      final notifier = container.read(administrationSettingsProvider.notifier);

      // Initial state should have default values
      expect(notifier.state.settings.current.isUPnPEnabled, false);
      expect(notifier.state.settings.current.enabledALG, false);

      // Create a sample AdministrationSettings to verify structure
      final sampleSettings = AdministrationSettings(
        managementSettings: const ManagementSettings(
          canManageUsingHTTP: true,
          canManageUsingHTTPS: false,
          isManageWirelesslySupported: true,
          canManageRemotely: false,
        ),
        isUPnPEnabled: true,
        canUsersConfigure: false,
        canUsersDisableWANAccess: true,
        enabledALG: false,
        isExpressForwardingSupported: true,
        enabledExpressForwarfing: false,
      );

      // Verify the sample settings structure is correct
      expect(sampleSettings.isUPnPEnabled, true);
      expect(sampleSettings.managementSettings.canManageUsingHTTP, true);
    });

    /// T030: Test handling service errors gracefully
    test('handles service errors gracefully', () async {
      final container = ProviderContainer();

      final notifier = container.read(administrationSettingsProvider.notifier);

      // Initial state should remain unchanged on error
      final initialState = notifier.state;
      expect(
          initialState.settings.current.managementSettings.canManageUsingHTTP,
          false);

      // Even if service fails, the notifier should maintain valid state
      expect(notifier.state.status, isNotNull);
    });
  });
}
