import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart' as jnap_models;
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';
import 'package:privacy_gui/utils.dart';

/// DMZSettingsService handles JNAP orchestration and data transformation for DMZ settings.
///
/// This service isolates data-fetching logic from the Notifier, enabling:
/// - Independent unit testing of data transformation
/// - Reusability by other components
/// - Clear separation of concerns (Service vs State Management)
class DMZSettingsService {
  /// Fetches DMZ settings and LAN configuration via a single JNAP transaction.
  ///
  /// Orchestrates two JNAP actions in one coordinated call:
  /// - getLANSettings (for network context: IP address, subnet mask)
  /// - getDMZSettings (for DMZ configuration: enabled/disabled, source/destination settings)
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [forceRemote]: If true, fetch from cloud; otherwise use local (default: false)
  /// - [updateStatusOnly]: If true, only update status without fetching new data (default: false)
  ///
  /// Returns: Tuple of (DMZUISettings, DMZStatus) with all settings and network context
  ///
  /// Throws: [Exception] with action context if any JNAP action fails
  Future<(DMZUISettings?, DMZStatus?)> fetchDmzSettings(
    Ref ref, {
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final repo = ref.read(routerRepositoryProvider);

    // Build JNAP transaction with both actions
    final transaction = JNAPTransactionBuilder(
      commands: const [
        MapEntry(JNAPAction.getLANSettings, {}),
        MapEntry(JNAPAction.getDMZSettings, {}),
      ],
      auth: true,
    );

    // Execute transaction
    final transactionWrap =
        await repo.transaction(transaction, fetchRemote: forceRemote);

    // Parse each JNAP response
    final lanResult = transactionWrap.data
        .firstWhereOrNull((element) => element.key == JNAPAction.getLANSettings)
        ?.value;
    final dmzResult = transactionWrap.data
        .firstWhereOrNull((element) => element.key == JNAPAction.getDMZSettings)
        ?.value;

    DMZStatus? status;
    if (lanResult != null && lanResult is JNAPSuccess) {
      status = _parseLANSettings(lanResult);
    }

    DMZUISettings? uiSettings;
    if (dmzResult != null && dmzResult is JNAPSuccess) {
      uiSettings = _parseDMZSettings(dmzResult);
    }

    return (uiSettings, status ?? const DMZStatus());
  }

  /// Parses LANSettings from JNAP response to extract network context.
  ///
  /// Throws [Exception] with action context if parsing fails.
  DMZStatus _parseLANSettings(JNAPSuccess result) {
    try {
      final output = result.output as Map<String, dynamic>?;
      if (output == null) {
        throw Exception('getLANSettings failed: Invalid response format');
      }

      final lanSettings = RouterLANSettings.fromMap(output);
      final subnetMask = NetworkUtils.prefixLengthToSubnetMask(
          lanSettings.networkPrefixLength);
      final ipAddress =
          NetworkUtils.getIpPrefix(lanSettings.ipAddress, subnetMask);

      return DMZStatus(ipAddress: ipAddress, subnetMask: subnetMask);
    } catch (e) {
      throw Exception('getLANSettings failed: ${e.toString()}');
    }
  }

  /// Parses DMZSettings from JNAP response and converts to UI model.
  ///
  /// This is where the Data layer model (DMZSettings) is converted to the
  /// Application layer UI model (DMZUISettings). The UI layer never sees
  /// the JNAP data models.
  ///
  /// Throws [Exception] with action context if parsing fails.
  DMZUISettings _parseDMZSettings(JNAPSuccess result) {
    try {
      final output = result.output as Map<String, dynamic>?;
      if (output == null) {
        throw Exception('getDMZSettings failed: Invalid response format');
      }

      final dmzSettings = jnap_models.DMZSettings.fromMap(output);

      // Convert Data model source restriction to UI model
      final sourceRestrictionUI = dmzSettings.sourceRestriction != null
          ? DMZSourceRestrictionUI(
              firstIPAddress: dmzSettings.sourceRestriction!.firstIPAddress,
              lastIPAddress: dmzSettings.sourceRestriction!.lastIPAddress,
            )
          : null;

      final uiSettings = DMZUISettings(
        isDMZEnabled: dmzSettings.isDMZEnabled,
        sourceRestriction: sourceRestrictionUI,
        destinationIPAddress: dmzSettings.destinationIPAddress,
        destinationMACAddress: dmzSettings.destinationMACAddress,
        sourceType: sourceRestrictionUI == null
            ? DMZSourceType.auto
            : DMZSourceType.range,
        destinationType: dmzSettings.destinationMACAddress == null
            ? DMZDestinationType.ip
            : DMZDestinationType.mac,
      );
      return uiSettings;
    } catch (e) {
      throw Exception('getDMZSettings failed: ${e.toString()}');
    }
  }

  /// Saves DMZ settings via a single JNAP action.
  ///
  /// Converts UI model (DMZUISettings) back to Data model (DMZSettings) for JNAP.
  /// This ensures the UI layer never directly interacts with JNAP data models.
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [settings]: The DMZUISettings to save (Application layer UI model)
  ///
  /// Throws: [Exception] with action context if JNAP action fails
  Future<void> saveDmzSettings(
    Ref ref,
    DMZUISettings settings,
  ) async {
    final repo = ref.read(routerRepositoryProvider);

    // Convert UI model source restriction to Data model
    final sourceRestrictionData = settings.sourceRestriction != null
        ? jnap_models.DMZSourceRestriction(
            firstIPAddress: settings.sourceRestriction!.firstIPAddress,
            lastIPAddress: settings.sourceRestriction!.lastIPAddress,
          )
        : null;

    // Transform UI settings to domain model for JNAP
    final domainSettings = jnap_models.DMZSettings(
      isDMZEnabled: settings.isDMZEnabled,
      sourceRestriction: sourceRestrictionData,
      destinationIPAddress: settings.destinationIPAddress,
      destinationMACAddress: settings.destinationMACAddress,
    );

    try {
      await repo.send(
        JNAPAction.setDMZSettings,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
        data: domainSettings.toMap()
          ..removeWhere((key, value) => value == null),
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for DMZSettingsService
///
/// Provides a singleton instance of [DMZSettingsService] for use
/// throughout the application. Can be overridden in tests to inject mock implementations.
final dmzSettingsServiceProvider = Provider<DMZSettingsService>(
  (ref) => DMZSettingsService(),
);
