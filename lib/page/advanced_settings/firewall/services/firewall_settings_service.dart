import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/providers/empty_status.dart';

/// FirewallSettingsService handles JNAP orchestration and data transformation for firewall settings.
///
/// This service isolates data-fetching logic from the Notifier, enabling:
/// - Independent unit testing of data transformation
/// - Reusability by other components
/// - Clear separation of concerns (Service vs State Management)
class FirewallSettingsService {
  /// Fetches firewall settings from the device.
  ///
  /// This method handles:
  /// - JNAP protocol communication via RouterRepository
  /// - Transformation from Data layer (FirewallSettings) to Application layer (FirewallUISettings)
  /// - Error handling for network and parsing failures
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [forceRemote]: If true, fetch from cloud; otherwise use local (default: false)
  ///
  /// Returns: Tuple of (FirewallUISettings, EmptyStatus)
  ///   - FirewallUISettings: Transformed UI model with all firewall configuration
  ///   - EmptyStatus: Status object (currently unused, reserved for future extensions)
  ///
  /// Throws: [Exception] with detailed context if JNAP action or transformation fails
  Future<(FirewallUISettings?, EmptyStatus?)> fetchFirewallSettings(
    Ref ref, {
    bool forceRemote = false,
  }) async {
    try {
      final repo = ref.read(routerRepositoryProvider);

      // Execute JNAP action to retrieve firewall settings
      final result = await repo.send(
        JNAPAction.getFirewallSettings,
        auth: true,
        fetchRemote: forceRemote,
      );

      // Parse Data layer model (JNAP response)
      final dataModel = FirewallSettings.fromMap(result.output);

      // Transform to Application layer UI model
      final uiSettings = _transformToUIModel(dataModel);

      return (uiSettings, const EmptyStatus());
    } catch (e) {
      throw Exception(
        'Failed to fetch firewall settings: ${e.toString()}',
      );
    }
  }

  /// Saves firewall settings to the device.
  ///
  /// This method handles:
  /// - Transformation from Application layer (FirewallUISettings) to Data layer (FirewallSettings)
  /// - JNAP protocol communication via RouterRepository
  /// - Error handling for save failures
  ///
  /// Parameters:
  /// - [ref]: Riverpod Ref for accessing provider dependencies
  /// - [settings]: The FirewallUISettings to save (Application layer UI model)
  ///
  /// Throws: [Exception] with detailed context if transformation or JNAP action fails
  Future<void> saveFirewallSettings(
    Ref ref,
    FirewallUISettings settings,
  ) async {
    try {
      final repo = ref.read(routerRepositoryProvider);

      // Transform UI model to Data model for JNAP
      final dataModel = _transformToDataModel(settings);

      // Execute JNAP action to save firewall settings
      await repo.send(
        JNAPAction.setFirewallSettings,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        data: dataModel.toMap(),
      );
    } catch (e) {
      throw Exception(
        'Failed to save firewall settings: ${e.toString()}',
      );
    }
  }

  /// Transforms Data layer model (FirewallSettings) to Application layer UI model (FirewallUISettings).
  ///
  /// This transformation isolates the Presentation layer from JNAP protocol details.
  /// Currently, the models have identical structures, but this abstraction allows
  /// for future divergence without impacting the UI.
  ///
  /// Parameters:
  /// - [dataModel]: JNAP data model from repository
  ///
  /// Returns: UI model for presentation layer
  FirewallUISettings _transformToUIModel(FirewallSettings dataModel) {
    return FirewallUISettings(
      blockAnonymousRequests: dataModel.blockAnonymousRequests,
      blockIDENT: dataModel.blockIDENT,
      blockIPSec: dataModel.blockIPSec,
      blockL2TP: dataModel.blockL2TP,
      blockMulticast: dataModel.blockMulticast,
      blockNATRedirection: dataModel.blockNATRedirection,
      blockPPTP: dataModel.blockPPTP,
      isIPv4FirewallEnabled: dataModel.isIPv4FirewallEnabled,
      isIPv6FirewallEnabled: dataModel.isIPv6FirewallEnabled,
    );
  }

  /// Transforms Application layer UI model (FirewallUISettings) to Data layer model (FirewallSettings).
  ///
  /// This transformation ensures the Presentation layer never directly interacts with JNAP data models.
  /// The service acts as the adapter between layers, maintaining clean architecture boundaries.
  ///
  /// Parameters:
  /// - [uiSettings]: UI model from presentation layer
  ///
  /// Returns: JNAP data model for repository
  FirewallSettings _transformToDataModel(FirewallUISettings uiSettings) {
    return FirewallSettings(
      blockAnonymousRequests: uiSettings.blockAnonymousRequests,
      blockIDENT: uiSettings.blockIDENT,
      blockIPSec: uiSettings.blockIPSec,
      blockL2TP: uiSettings.blockL2TP,
      blockMulticast: uiSettings.blockMulticast,
      blockNATRedirection: uiSettings.blockNATRedirection,
      blockPPTP: uiSettings.blockPPTP,
      isIPv4FirewallEnabled: uiSettings.isIPv4FirewallEnabled,
      isIPv6FirewallEnabled: uiSettings.isIPv6FirewallEnabled,
    );
  }
}
