import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for InstantTopologyService
final instantTopologyServiceProvider = Provider<InstantTopologyService>((ref) {
  return InstantTopologyService(
    ref.watch(routerRepositoryProvider),
  );
});

/// Stateless service for topology node operations.
///
/// Encapsulates JNAP communication for reboot, factory reset, and LED blink
/// operations, following the three-layer architecture (Article V, VI).
///
/// All JNAP errors are converted to [ServiceError] subtypes.
class InstantTopologyService {
  InstantTopologyService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Reboots one or more network nodes.
  ///
  /// **Parameters:**
  /// - [deviceUUIDs]: List of device UUIDs to reboot. Empty list means master node only.
  ///
  /// **Behavior:**
  /// - Empty list: Sends single `JNAPAction.reboot` to master node
  /// - Non-empty list: Sends `JNAPAction.reboot2` transaction for each UUID (reverse order)
  /// - After transaction: Waits for all specified nodes to go offline
  ///
  /// **Returns:** Future<void> - Completes when nodes are offline
  ///
  /// **Throws:**
  /// - [NodeOperationFailedError]: If reboot command fails
  /// - [TopologyTimeoutError]: If nodes don't go offline within timeout
  /// - [UnexpectedError]: For unexpected JNAP errors
  Future<void> rebootNodes(List<String> deviceUUIDs) async {
    try {
      if (deviceUUIDs.isEmpty) {
        // Master node only
        await _routerRepository.send(
          JNAPAction.reboot,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
        );
      } else {
        // Child nodes - build transaction
        final builder = JNAPTransactionBuilder(
          commands: deviceUUIDs.reversed
              .map((uuid) => MapEntry(JNAPAction.reboot2, {'deviceUUID': uuid}))
              .toList(),
          auth: true,
        );
        await _routerRepository.transaction(
          builder,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
        // Wait for nodes to go offline
        await waitForNodesOffline(deviceUUIDs);
      }
    } on JNAPError catch (e) {
      throw _mapJnapError(e, deviceUUIDs.firstOrNull ?? 'master', 'reboot');
    }
  }

  /// Factory resets one or more network nodes.
  ///
  /// **Parameters:**
  /// - [deviceUUIDs]: List of device UUIDs to reset. Empty list means master node only.
  ///
  /// **Behavior:**
  /// - Empty list: Sends single `JNAPAction.factoryReset` to master node
  /// - Non-empty list: Sends `JNAPAction.factoryReset2` transaction (reverse order)
  /// - After transaction: Waits for all specified nodes to go offline
  ///
  /// **Returns:** Future<void> - Completes when nodes are offline
  ///
  /// **Throws:**
  /// - [NodeOperationFailedError]: If factory reset command fails
  /// - [TopologyTimeoutError]: If nodes don't go offline within timeout
  /// - [UnexpectedError]: For unexpected JNAP errors
  Future<void> factoryResetNodes(List<String> deviceUUIDs) async {
    try {
      if (deviceUUIDs.isEmpty) {
        // Master node only
        await _routerRepository.send(
          JNAPAction.factoryReset,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
        );
      } else {
        // Child nodes - build transaction (reverse order for bottom-up reset)
        final builder = JNAPTransactionBuilder(
          commands: deviceUUIDs.reversed
              .map((uuid) =>
                  MapEntry(JNAPAction.factoryReset2, {'deviceUUID': uuid}))
              .toList(),
          auth: true,
        );
        await _routerRepository.transaction(
          builder,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
        // Wait for nodes to go offline
        await waitForNodesOffline(deviceUUIDs);
      }
    } on JNAPError catch (e) {
      throw _mapJnapError(
          e, deviceUUIDs.firstOrNull ?? 'master', 'factoryReset');
    }
  }

  /// Starts LED blinking on a specific node.
  ///
  /// **Parameters:**
  /// - [deviceId]: The device ID of the node to blink
  ///
  /// **Returns:** Future<void> - Completes when blink command is sent
  ///
  /// **Throws:**
  /// - [NodeOperationFailedError]: If blink command fails (device: deviceId, operation: 'blinkStart')
  /// - [UnexpectedError]: For unexpected JNAP errors
  Future<void> startBlinkNodeLED(String deviceId) async {
    try {
      await _routerRepository.send(
        JNAPAction.startBlinkNodeLed,
        data: {'deviceID': deviceId},
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e, deviceId, 'blinkStart');
    }
  }

  /// Stops LED blinking on all nodes.
  ///
  /// **Returns:** Future<void> - Completes when stop command is sent
  ///
  /// **Throws:**
  /// - [NodeOperationFailedError]: If stop command fails (device: '', operation: 'blinkStop')
  /// - [UnexpectedError]: For unexpected JNAP errors
  Future<void> stopBlinkNodeLED() async {
    try {
      await _routerRepository.send(
        JNAPAction.stopBlinkNodeLed,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e, '', 'blinkStop');
    }
  }

  /// Waits for specified nodes to go offline.
  ///
  /// **Parameters:**
  /// - [deviceUUIDs]: List of device UUIDs to monitor
  /// - [maxRetry]: Maximum number of polling attempts (default: 20)
  /// - [retryDelayMs]: Delay between retries in milliseconds (default: 3000)
  ///
  /// **Behavior:**
  /// - Polls `JNAPAction.getDevices` at intervals
  /// - Completes when all specified devices report offline status
  /// - Times out after maxRetry × retryDelayMs milliseconds
  ///
  /// **Returns:** Future<void> - Completes when all nodes are offline
  ///
  /// **Throws:**
  /// - [TopologyTimeoutError]: If timeout exceeded (includes timeout duration and device IDs)
  Future<void> waitForNodesOffline(
    List<String> deviceUUIDs, {
    int maxRetry = 20,
    int retryDelayMs = 3000,
  }) async {
    final waitingStream = _routerRepository.scheduledCommand(
      action: JNAPAction.getDevices,
      retryDelayInMilliSec: retryDelayMs,
      maxRetry: maxRetry,
      condition: (result) {
        if (result is JNAPSuccess) {
          final deviceList = List.from(result.output['devices'])
              .map((e) => LinksysDevice.fromMap(e))
              .where((device) => deviceUUIDs.contains(device.deviceID))
              .toList();
          return !deviceList.any((device) => device.isOnline());
        }
        return false;
      },
      auth: true,
    );

    bool allOffline = false;
    await for (final result in waitingStream) {
      logger.d('[Reboot/FactoryReset]: Waiting for all nodes offline');
      if (result is JNAPSuccess) {
        final deviceList = List.from(result.output['devices'])
            .map((e) => LinksysDevice.fromMap(e))
            .where((device) => deviceUUIDs.contains(device.deviceID))
            .toList();
        for (final device in deviceList) {
          logger.d(
              '[Reboot/FactoryReset]: Waiting for - isDevice<${device.getDeviceLocation()}> Online - ${device.isOnline()}');
        }
        // Check if all specified nodes are offline
        if (!deviceList.any((device) => device.isOnline())) {
          allOffline = true;
        }
      }
    }

    // If stream completed without all nodes going offline, throw timeout
    if (!allOffline) {
      throw TopologyTimeoutError(
        timeout: Duration(milliseconds: maxRetry * retryDelayMs),
        deviceIds: deviceUUIDs,
      );
    }
  }

  /// Maps JNAP errors to ServiceError for topology operations.
  ///
  /// Uses the centralized mapper from `jnap_error_mapper.dart` for common errors,
  /// with topology-specific handling for operation failures.
  ServiceError _mapJnapError(
      JNAPError error, String deviceId, String operation) {
    // For common errors, use centralized mapper
    final commonError = mapJnapErrorToServiceError(error);
    if (commonError is! UnexpectedError) {
      return commonError;
    }

    // For topology-specific errors
    return NodeOperationFailedError(
      deviceId: deviceId,
      operation: operation,
      originalError: error,
    );
  }
}
