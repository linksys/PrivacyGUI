import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/services/administration_settings_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

import 'administration_settings_state.dart';

/// Provides administration settings state management with undo/reset capability.
///
/// This provider manages four related administration settings:
/// - Management settings (HTTP/HTTPS/Remote management)
/// - UPnP settings (enabled, user configuration, WAN access)
/// - ALG settings (Application Layer Gateway)
/// - Express Forwarding settings
///
/// State is preserved in an original/current pattern to support dirty flag tracking
/// and undo functionality. Use [PreservableNotifierMixin] to coordinate state changes
/// with the preservation mechanism.
///
/// Example usage:
/// ```dart
/// final state = ref.watch(administrationSettingsProvider);
/// final notifier = ref.read(administrationSettingsProvider.notifier);
///
/// // Update individual settings
/// notifier.setUPnPEnabled(true);
///
/// // Save changes to device
/// await notifier.performSave();
/// ```
final administrationSettingsProvider = NotifierProvider<
    AdministrationSettingsNotifier,
    AdministrationSettingsState>(() => AdministrationSettingsNotifier());

/// Provides access to the [PreservableContract] for dirty guard functionality.
///
/// Used by the routing system to check if there are unsaved changes
/// before navigating away from the page.
final preservableAdministrationSettingsProvider = Provider<PreservableContract>(
  (ref) => ref.watch(administrationSettingsProvider.notifier),
);

/// Notifier managing administration settings state and operations.
///
/// Responsibilities:
/// - Coordinates state changes through setter methods
/// - Delegates fetching to [AdministrationSettingsService]
/// - Delegates saving to [AdministrationSettingsService]
/// - Maintains original vs current state for dirty tracking
///
/// The [PreservableNotifierMixin] provides automatic support for:
/// - Tracking whether settings have changed (isDirty flag)
/// - Resetting to original values (undo)
/// - Preserving state across app lifecycle
class AdministrationSettingsNotifier
    extends Notifier<AdministrationSettingsState>
    with
        PreservableNotifierMixin<AdministrationSettings, AdministrationStatus,
            AdministrationSettingsState> {
  /// Initializes the notifier with default administration settings.
  ///
  /// Returns a [AdministrationSettingsState] with all settings disabled by default.
  /// The state uses [Preservable] to track both original and current values.
  @override
  AdministrationSettingsState build() => AdministrationSettingsState(
        settings: Preservable(
          original: const AdministrationSettings(
            managementSettings: ManagementSettings(
              canManageUsingHTTP: false,
              canManageUsingHTTPS: false,
              isManageWirelesslySupported: false,
              canManageRemotely: false,
            ),
            enabledALG: false,
            isExpressForwardingSupported: false,
            enabledExpressForwarfing: false,
            isUPnPEnabled: false,
            canUsersConfigure: false,
            canUsersDisableWANAccess: false,
          ),
          current: const AdministrationSettings(
            managementSettings: ManagementSettings(
              canManageUsingHTTP: false,
              canManageUsingHTTPS: false,
              isManageWirelesslySupported: false,
              canManageRemotely: false,
            ),
            enabledALG: false,
            isExpressForwardingSupported: false,
            enabledExpressForwarfing: false,
            isUPnPEnabled: false,
            canUsersConfigure: false,
            canUsersDisableWANAccess: false,
          ),
        ),
        status: const AdministrationStatus(),
      );

  /// Fetches administration settings from the device.
  ///
  /// Called by [PreservableNotifierMixin] to load settings from the device
  /// and update the state. Returns a tuple of (settings, status).
  ///
  /// Parameters:
  /// - [forceRemote]: If true, fetch from cloud; otherwise use local device (default: false)
  /// - [updateStatusOnly]: If true, only update status without fetching new data (default: false)
  ///
  /// Returns: A tuple of (AdministrationSettings, AdministrationStatus) or (null, status) on error
  @override
  Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final service = AdministrationSettingsService();
    final settings = await service.fetchAdministrationSettings(
      ref,
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );
    return (settings, const AdministrationStatus());
  }

  /// Saves administration settings to the device.
  ///
  /// Called by [PreservableNotifierMixin] to persist the current state
  /// to the device via [AdministrationSettingsService].
  @override
  Future<void> performSave() async {
    final service = AdministrationSettingsService();
    await service.saveAdministrationSettings(ref, state.current);
  }

  /// Updates the management settings (wireless management capability).
  ///
  /// Sets whether the device can be managed wirelessly.
  /// This affects the [canManageWirelessly] flag in [ManagementSettings].
  void setManagementSettings(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(
          managementSettings: state.current.managementSettings.copyWith(
            canManageWirelessly: value,
          ),
        ),
      ),
    );
  }

  /// Updates UPnP enabled state.
  ///
  /// Sets whether Universal Plug and Play (UPnP) is enabled on the device.
  void setUPnPEnabled(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(isUPnPEnabled: value),
      ),
    );
  }

  /// Updates UPnP user configuration permission.
  ///
  /// Sets whether regular users are allowed to configure UPnP settings.
  void setCanUsersConfigure(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(canUsersConfigure: value),
      ),
    );
  }

  /// Updates UPnP WAN access permission for users.
  ///
  /// Sets whether users are allowed to disable WAN (Internet) access through UPnP.
  void setCanUsersDisableWANAccess(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(canUsersDisableWANAccess: value),
      ),
    );
  }

  /// Updates Application Layer Gateway (ALG) enabled state.
  ///
  /// Sets whether ALG is enabled. ALG typically refers to SIP (Session Initiation Protocol)
  /// support for VoIP applications.
  void setALGEnabled(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(enabledALG: value),
      ),
    );
  }

  /// Updates Express Forwarding enabled state.
  ///
  /// Sets whether Express Forwarding is enabled for improved port forwarding performance.
  void setExpressForwarding(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.current.copyWith(enabledExpressForwarfing: value),
      ),
    );
  }
}
