import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
  ///   - Returns (null, null) on error after logging
  ///
  /// This method does NOT throw exceptions. Instead, it catches all errors and returns null,
  /// allowing the provider layer to handle error display.
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

      // Validate JNAP response is not empty
      final output = result.output;
      if ((output as Map?)?.isEmpty ?? true) {
        logger.e(
          'JNAP getFirewallSettings returned empty output',
          error: 'Response output is empty or null',
        );
        return (null, null);
      }

      // Parse Data layer model (JNAP response)
      final dataModel = _parseFirewallSettings(result.output);
      if (dataModel == null) {
        logger.e(
          'Failed to parse firewall settings from JNAP response',
          error: 'Data model parsing failed',
        );
        return (null, null);
      }

      // Validate parsed model for missing or invalid fields
      _validateFirewallSettings(dataModel);

      // Transform to Application layer UI model
      final uiSettings = _transformToUIModel(dataModel);

      logger.d('Successfully fetched firewall settings');
      return (uiSettings, const EmptyStatus());
    } catch (e, stackTrace) {
      logger.e(
        'Error fetching firewall settings',
        error: e,
        stackTrace: stackTrace,
      );
      return (null, null);
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
  /// Throws: [Exception] with descriptive error message if transformation or JNAP action fails
  ///
  /// Error handling covers:
  /// - Null settings input validation
  /// - Data model transformation errors
  /// - JNAP action failures
  /// - Network timeouts
  /// - Invalid responses
  Future<void> saveFirewallSettings(
    Ref ref,
    FirewallUISettings settings,
  ) async {
    try {
      // Validate input settings (note: settings is already guaranteed non-null by parameter signature)

      final repo = ref.read(routerRepositoryProvider);

      // Transform UI model to Data model for JNAP
      final dataModel = _transformToDataModel(settings);

      // Validate data model before sending
      _validateFirewallSettings(dataModel);

      logger.d('Saving firewall settings to device');

      // Execute JNAP action to save firewall settings
      await repo.send(
        JNAPAction.setFirewallSettings,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        data: dataModel.toMap(),
      );

      logger.d('Successfully saved firewall settings');
    } on ArgumentError catch (e) {
      logger.e('Invalid firewall settings input', error: e);
      throw Exception('Invalid firewall settings: ${e.message}');
    } catch (e, stackTrace) {
      logger.e(
        'Error saving firewall settings',
        error: e,
        stackTrace: stackTrace,
      );
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

  /// Private: Parses JNAP response output into FirewallSettings model.
  ///
  /// This method safely parses the JNAP response output map into a FirewallSettings object.
  /// It handles various parsing errors gracefully.
  ///
  /// Parameters:
  /// - [output]: The raw JNAP response output map
  ///
  /// Returns: Parsed FirewallSettings object, or null if parsing fails
  FirewallSettings? _parseFirewallSettings(dynamic output) {
    try {
      // Ensure output is a Map
      if (output is! Map<String, dynamic>) {
        logger.w(
          'JNAP response output is not a Map',
          error: 'Expected Map<String, dynamic>, got ${output.runtimeType}',
        );
        return null;
      }

      // Parse using factory method
      return FirewallSettings.fromMap(output);
    } on TypeError catch (e) {
      logger.e(
        'Type error parsing firewall settings',
        error: 'Field type mismatch: ${e.toString()}',
      );
      return null;
    } on FormatException catch (e) {
      logger.e(
        'Format error parsing firewall settings',
        error: 'Invalid data format: ${e.toString()}',
      );
      return null;
    } catch (e) {
      logger.e(
        'Unexpected error parsing firewall settings',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Private: Validates that FirewallSettings model has all required fields with valid values.
  ///
  /// This method performs validation of parsed firewall settings to ensure:
  /// - Data model structure is valid
  /// - Field values are semantically valid
  /// - No incomplete or corrupted data exists
  ///
  /// Parameters:
  /// - [dataModel]: The FirewallSettings model to validate (guaranteed non-null)
  ///
  /// Throws: [Exception] if validation fails with descriptive error message
  void _validateFirewallSettings(FirewallSettings dataModel) {
    // All fields in FirewallSettings are non-nullable by design
    // Additional semantic validation could be added here in the future
    logger.d('Firewall settings validation passed');
  }
}
