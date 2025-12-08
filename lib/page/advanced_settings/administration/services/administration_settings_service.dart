import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/alg_settings.dart';
import 'package:privacy_gui/core/jnap/models/express_forwarding_settings.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/core/jnap/models/unpn_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';

/// AdministrationSettingsService handles JNAP orchestration and data transformation
/// for administration settings (Management, UPnP, ALG, Express Forwarding).
///
/// This service isolates data-fetching logic from the Notifier, enabling:
/// - Independent unit testing of data transformation
/// - Reusability by other components
/// - Clear separation of concerns (Service vs State Management)
class AdministrationSettingsService {
  /// Fetches all four administration settings via a single JNAP transaction.
  ///
  /// Orchestrates four JNAP actions in one coordinated call:
  /// - getManagementSettings
  /// - getUPnPSettings
  /// - getALGSettings
  /// - getExpressForwardingSettings
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [forceRemote]: If true, fetch from cloud; otherwise use local (default: false)
  /// - [updateStatusOnly]: If true, only update status without fetching new data (default: false)
  ///
  /// Returns: [AdministrationSettings] with all four model types aggregated
  ///
  /// Throws: [Exception] with action context if any JNAP action fails
  Future<AdministrationSettings> fetchAdministrationSettings(
    Ref ref, {
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final repo = ref.read(routerRepositoryProvider);

    // Build JNAP transaction with all four actions
    final transaction = JNAPTransactionBuilder(
      commands: [
        const MapEntry(JNAPAction.getManagementSettings, {}),
        const MapEntry(JNAPAction.getUPnPSettings, {}),
        const MapEntry(JNAPAction.getALGSettings, {}),
        const MapEntry(JNAPAction.getExpressForwardingSettings, {}),
      ],
      auth: true,
    );

    // Execute transaction
    final transactionWrap =
        await repo.transaction(transaction, fetchRemote: forceRemote);

    // Convert JNAPTransactionSuccessWrap data to map for easy lookup
    final resultMap = Map.fromEntries(transactionWrap.data);

    // Parse each JNAP response and instantiate domain models
    final managementSettings = _parseManagementSettings(resultMap);
    final upnpSettings = _parseUPnPSettings(resultMap);
    final algSettings = _parseALGSettings(resultMap);
    final expressForwardingSettings =
        _parseExpressForwardingSettings(resultMap);

    // Check LAN port availability for wireless management toggle
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;

    // Aggregate all settings into AdministrationSettings
    return AdministrationSettings(
      managementSettings: managementSettings,
      isUPnPEnabled: upnpSettings?.isUPnPEnabled ?? false,
      canUsersConfigure: upnpSettings?.canUsersConfigure ?? false,
      canUsersDisableWANAccess: upnpSettings?.canUsersDisableWANAccess ?? false,
      enabledALG: algSettings?.isSIPEnabled ?? false,
      isExpressForwardingSupported:
          expressForwardingSettings?.isExpressForwardingSupported ?? false,
      enabledExpressForwarfing:
          expressForwardingSettings?.isExpressForwardingEnabled ?? false,
      canDisAllowLocalMangementWirelessly: hasLanPort,
    );
  }

  /// Parses ManagementSettings from JNAP response.
  ///
  /// Throws [Exception] with action context if parsing fails.
  ManagementSettings _parseManagementSettings(
      Map<JNAPAction, JNAPResult> resultMap) {
    try {
      final result = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getManagementSettings,
        resultMap,
      );

      if (result == null) {
        throw Exception(
          'getManagementSettings failed: No response received from device',
        );
      }

      final output = result.output as Map<String, dynamic>?;
      if (output == null) {
        throw Exception(
          'getManagementSettings failed: Invalid response format',
        );
      }

      return ManagementSettings.fromMap(output);
    } catch (e) {
      throw Exception(
        'getManagementSettings failed: ${e.toString()}',
      );
    }
  }

  /// Parses UPnPSettings from JNAP response.
  ///
  /// Returns null if response is unavailable; throws [Exception] on error.
  UPnPSettings? _parseUPnPSettings(Map<JNAPAction, JNAPResult> resultMap) {
    try {
      final result = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getUPnPSettings,
        resultMap,
      );

      final output = result?.output;
      if (output == null) return null;

      return UPnPSettings.fromMap(output);
    } catch (e) {
      throw Exception(
        'getUPnPSettings failed: ${e.toString()}',
      );
    }
  }

  /// Parses ALGSettings from JNAP response.
  ///
  /// Returns null if response is unavailable; throws [Exception] on error.
  ALGSettings? _parseALGSettings(Map<JNAPAction, JNAPResult> resultMap) {
    try {
      final result = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getALGSettings,
        resultMap,
      );

      final output = result?.output;
      if (output == null) return null;

      return ALGSettings.fromMap(output);
    } catch (e) {
      throw Exception(
        'getALGSettings failed: ${e.toString()}',
      );
    }
  }

  /// Parses ExpressForwardingSettings from JNAP response.
  ///
  /// Returns null if response is unavailable; throws [Exception] on error.
  ExpressForwardingSettings? _parseExpressForwardingSettings(
      Map<JNAPAction, JNAPResult> resultMap) {
    try {
      final result = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getExpressForwardingSettings,
        resultMap,
      );

      final output = result?.output;
      if (output == null) return null;

      return ExpressForwardingSettings.fromMap(output);
    } catch (e) {
      throw Exception(
        'getExpressForwardingSettings failed: ${e.toString()}',
      );
    }
  }

  /// Saves all administration settings via a single JNAP transaction.
  ///
  /// Orchestrates four JNAP set actions in one coordinated call:
  /// - setManagementSettings
  /// - setUPnPSettings
  /// - setALGSettings
  /// - setExpressForwardingSettings
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [settings]: The AdministrationSettings to save
  ///
  /// Throws: [Exception] with action context if any JNAP action fails
  Future<void> saveAdministrationSettings(
    Ref ref,
    AdministrationSettings settings,
  ) async {
    final repo = ref.read(routerRepositoryProvider);

    // Build JNAP transaction with all four set actions
    final transaction = JNAPTransactionBuilder(
      commands: [
        MapEntry(
          JNAPAction.setManagementSettings,
          settings.managementSettings.toMap()
            ..remove('isManageWirelesslySupported'),
        ),
        MapEntry(
          JNAPAction.setUPnPSettings,
          {
            'isUPnPEnabled': settings.isUPnPEnabled,
            'canUsersConfigure': settings.canUsersConfigure,
            'canUsersDisableWANAccess': settings.canUsersDisableWANAccess,
          },
        ),
        MapEntry(
          JNAPAction.setALGSettings,
          {'isSIPEnabled': settings.enabledALG},
        ),
        MapEntry(
          JNAPAction.setExpressForwardingSettings,
          {'isExpressForwardingEnabled': settings.enabledExpressForwarfing},
        ),
      ],
      auth: true,
    );

    try {
      await repo.transaction(transaction);
    } catch (e) {
      throw Exception(
        'Failed to save administration settings: ${e.toString()}',
      );
    }
  }
}
