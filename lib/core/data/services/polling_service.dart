import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final pollingServiceProvider = Provider<PollingService>((ref) {
  return PollingService(ref.watch(routerRepositoryProvider));
});

/// Service for polling operations.
///
/// Handles JNAP communication for periodic data polling.
/// This isolates JNAP protocol details from the PollingNotifier.
class PollingService {
  final RouterRepository _routerRepository;

  PollingService(this._routerRepository);

  // === Device Mode ===

  /// Checks the current device mode (Master, Slave, Unconfigured).
  ///
  /// Returns: Device mode string, defaults to 'Unconfigured' if unavailable.
  Future<String> checkDeviceMode() async {
    final result = await _routerRepository.send(
      JNAPAction.getDeviceMode,
      fetchRemote: true,
    );
    return result.output['mode'] ?? 'Unconfigured';
  }

  // === Core Transactions ===

  /// Builds the list of JNAP commands for core polling.
  ///
  /// [mode] - Current device mode (affects which commands are included).
  ///
  /// Returns: List of JNAP action entries with their parameters.
  List<MapEntry<JNAPAction, Map<String, dynamic>>> buildCoreTransactions({
    String? mode,
  }) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();

    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getNetworkConnections, {}),
      const MapEntry(JNAPAction.getRadioInfo, {}),
      if (isSupportGuestWiFi)
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      if ((mode ?? 'Unconfigured') == 'Master')
        const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
      const MapEntry(JNAPAction.getEthernetPortConnections, {}),
      const MapEntry(JNAPAction.getSystemStats, {}),
      const MapEntry(JNAPAction.getPowerTableSettings, {}),
      const MapEntry(JNAPAction.getLocalTime, {}),
      const MapEntry(JNAPAction.getDeviceInfo, {}),
    ];

    if (serviceHelper.isSupportSetup()) {
      commands.add(
        const MapEntry(JNAPAction.getInternetConnectionStatus, {}),
      );
    }

    if (serviceHelper.isSupportHealthCheck()) {
      commands.add(const MapEntry(JNAPAction.getHealthCheckResults, {
        'includeModuleResults': true,
        'lastNumberOfResults': 5,
      }));
      commands
          .add(const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}));
    }

    if (serviceHelper.isSupportNodeFirmwareUpdate()) {
      commands.add(
        const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}),
      );
    } else {
      commands.add(
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
      );
    }

    if (serviceHelper.isSupportProduct()) {
      commands.add(const MapEntry(JNAPAction.getSoftSKUSettings, {}));
    }

    // For additional features
    if (serviceHelper.isSupportLedMode()) {
      commands.add(const MapEntry(JNAPAction.getLedNightModeSetting, {}));
    }

    commands.add(const MapEntry(JNAPAction.getMACFilterSettings, {}));

    return commands;
  }

  // === Transaction Execution ===

  /// Executes a JNAP transaction with the given commands.
  ///
  /// [commands] - List of JNAP actions with parameters.
  /// [force] - If true, bypasses cache and fetches from remote.
  ///
  /// Returns: Transaction result containing action results.
  ///
  /// Throws: Exception on transaction failure.
  Future<JNAPTransactionSuccessWrap> executeTransaction(
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands, {
    bool force = false,
  }) async {
    return await _routerRepository.transaction(
      JNAPTransactionBuilder(commands: commands, auth: true),
      fetchRemote: force,
    );
  }

  // === Cache Data Parsing ===

  /// Parses cached data and converts to JNAP result map.
  ///
  /// Validates that all required commands have cached data, then converts
  /// the raw cache entries to JNAPSuccess objects.
  ///
  /// [cache] - Raw cache data map from LinksysCacheManager.
  /// [commands] - List of JNAP commands to look up in cache.
  ///
  /// Returns: Map of JNAPAction to JNAPResult if all commands have cache data,
  ///          null if cache is incomplete.
  Map<JNAPAction, JNAPResult>? parseCacheData({
    required Map<String, dynamic> cache,
    required List<MapEntry<JNAPAction, Map<String, dynamic>>> commands,
  }) {
    final checkCacheDataList = commands
        .where((command) => cache.keys.contains(command.key.actionValue));

    // Have not done any polling yet - cache incomplete
    if (checkCacheDataList.length != commands.length) return null;

    final cacheDataList = checkCacheDataList
        .where((command) => cache[command.key.actionValue]['data'] != null)
        .map((command) => MapEntry(
              command.key,
              JNAPSuccess.fromJson(cache[command.key.actionValue]['data']),
            ))
        .toList();

    return Map.fromEntries(cacheDataList);
  }

  // === Fernet Key Management ===

  /// Updates Fernet encryption key from device info in transaction result.
  ///
  /// Extracts serial number from getDeviceInfo response and updates
  /// the FernetManager key. Silently handles missing or invalid data.
  ///
  /// [data] - Map of JNAP action results from a transaction.
  void updateFernetKeyFromResult(Map<JNAPAction, JNAPResult> data) {
    try {
      final deviceInfoResult = data[JNAPAction.getDeviceInfo];
      if (deviceInfoResult is JNAPSuccess) {
        final serialNumber = deviceInfoResult.output['serialNumber'] as String?;
        if (serialNumber != null && serialNumber.isNotEmpty) {
          FernetManager().updateKeyFromSerial(serialNumber);
        } else {
          logger.w(
              'Serial number not found in getDeviceInfo response, cannot update Fernet key.');
        }
      }
    } catch (e) {
      logger.e('Failed to update Fernet key: $e');
    }
  }
}
