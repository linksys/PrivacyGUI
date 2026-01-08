import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for AddNodesService
final addNodesServiceProvider = Provider<AddNodesService>((ref) {
  return AddNodesService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for Add Nodes / Bluetooth Auto-Onboarding operations
///
/// Encapsulates JNAP communication for node onboarding, separating
/// business logic from state management (AddNodesNotifier).
///
/// Reference: constitution Article VI - Service Layer Principle
class AddNodesService {
  /// Constructor injection of RouterRepository
  AddNodesService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Enables Bluetooth auto-onboarding on the router
  ///
  /// Sends JNAPAction.setBluetoothAutoOnboardingSettings with
  /// isAutoOnboardingEnabled = true
  ///
  /// Throws:
  ///   - [NetworkError] if router communication fails
  ///   - [UnauthorizedError] if authentication expired
  ///   - [UnexpectedError] for other JNAP failures
  Future<void> setAutoOnboardingSettings() async {
    try {
      await _routerRepository.send(
        JNAPAction.setBluetoothAutoOnboardingSettings,
        data: {'isAutoOnboardingEnabled': true},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Fetches current Bluetooth auto-onboarding setting
  ///
  /// Returns:
  ///   - `true` if auto-onboarding is enabled
  ///   - `false` if disabled or not configured
  ///
  /// Throws:
  ///   - [NetworkError] if router communication fails
  ///   - [UnauthorizedError] if authentication expired
  ///   - [UnexpectedError] for other JNAP failures
  Future<bool> getAutoOnboardingSettings() async {
    try {
      final response = await _routerRepository.send(
        JNAPAction.getBluetoothAutoOnboardingSettings,
        auth: true,
      );
      return response.output['isAutoOnboardingEnabled'] ?? false;
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Polls auto-onboarding status until Idle or Complete
  ///
  /// Parameters:
  ///   - [oneTake]: If true, polls once and returns immediately
  ///
  /// Returns: Stream emitting status maps:
  /// ```dart
  /// {
  ///   'status': 'Idle' | 'Onboarding' | 'Complete',
  ///   'deviceOnboardingStatus': List<Map<String, dynamic>>,
  /// }
  /// ```
  ///
  /// Stream completes when:
  ///   - Status reaches 'Idle' or 'Complete'
  ///   - Max retries exhausted (18 retries × 10s = 3 minutes)
  Stream<Map<String, dynamic>> pollAutoOnboardingStatus({
    bool oneTake = false,
  }) {
    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getBluetoothAutoOnboardingStatus,
      maxRetry: oneTake ? 1 : 18,
      retryDelayInMilliSec: 10000,
      firstDelayInMilliSec: oneTake ? 100 : 3000,
      condition: (result) {
        if (result is JNAPSuccess) {
          final status = result.output['autoOnboardingStatus'];
          return status == 'Idle' || status == 'Complete';
        }
        return false;
      },
      onCompleted: (_) {
        logger.d('[AddNodesService]: GetAutoOnboardingStatus Done!');
      },
      auth: true,
    )
        .transform(
      StreamTransformer<JNAPResult, Map<String, dynamic>>.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            sink.add({
              'status': result.output['autoOnboardingStatus'],
              'deviceOnboardingStatus':
                  result.output['deviceOnboardingStatus'] ?? [],
            });
          }
        },
      ),
    );
  }

  /// Initiates the Bluetooth auto-onboarding process
  ///
  /// Internally calls JNAPAction.startBlueboothAutoOnboarding
  ///
  /// Throws:
  ///   - [NetworkError] if router communication fails
  ///   - [UnauthorizedError] if authentication expired
  ///   - [UnexpectedError] for other JNAP failures
  Future<void> startAutoOnboarding() async {
    try {
      await _routerRepository.send(
        JNAPAction.startBlueboothAutoOnboarding,
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Polls for onboarded nodes to come online
  ///
  /// Parameters:
  ///   - [onboardedMACList]: MAC addresses to watch for
  ///   - [refreshing]: If true, uses shorter timeouts for refresh operations
  ///
  /// Returns: Stream of device lists where each emission contains
  /// all currently visible nodes (nodeType != null)
  ///
  /// Stream completes when:
  ///   - All MAC addresses found in online nodes with connections, OR
  ///   - Max retries exhausted
  ///
  /// Note: Stream completion with partial results is NOT an error.
  /// Provider handles empty/partial results per clarification session.
  Stream<List<LinksysDevice>> pollForNodesOnline(
    List<String> onboardedMACList, {
    bool refreshing = false,
  }) {
    logger.d(
        '[AddNodesService]: [pollForNodesOnline] Start by MACs: $onboardedMACList');

    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getDevices,
      firstDelayInMilliSec: refreshing ? 1000 : 20000,
      retryDelayInMilliSec: refreshing ? 3000 : 20000,
      // Basic 3 minutes, add 2 minutes for each one more node
      maxRetry: refreshing ? 5 : 9 + onboardedMACList.length * 6,
      auth: true,
      condition: (result) {
        if (result is JNAPSuccess) {
          final deviceList = List.from(result.output['devices'])
              .map((e) => LinksysDevice.fromMap(e))
              .where((device) => device.isAuthority == false)
              .toList();

          // Check all MAC addresses can be found in the device list
          bool allFound = onboardedMACList.every((mac) => deviceList.any(
              (device) =>
                  device.nodeType == 'Slave' &&
                  (device.knownInterfaces?.any((knownInterface) =>
                          knownInterface.macAddress == mac) ??
                      false)));

          logger.d(
              '[AddNodesService]: [pollForNodesOnline] are All MACs in device list? $allFound');

          // Check if nodes in the mac list all have connections
          bool ret = deviceList
              .where((device) =>
                  device.nodeType == 'Slave' &&
                  (device.knownInterfaces?.any((knownInterface) =>
                          onboardedMACList
                              .contains(knownInterface.macAddress)) ??
                      false))
              .every((device) {
            final hasConnections = device.isOnline();
            logger.d(
                '[AddNodesService]: [pollForNodesOnline] <${device.getDeviceLocation()}> has connections: $hasConnections');
            return hasConnections;
          });

          return allFound && ret;
        }
        return false;
      },
      onCompleted: (_) {
        logger.d('[AddNodesService]: [pollForNodesOnline] Done!');
      },
    )
        .transform(
      StreamTransformer<JNAPResult, List<LinksysDevice>>.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            final deviceList = List.from(result.output['devices'])
                .map((e) => LinksysDevice.fromMap(e))
                .where((device) => device.nodeType != null)
                .toList();
            sink.add(deviceList);
          }
        },
      ),
    );
  }

  /// Polls backhaul info for child nodes and enriches device data
  ///
  /// Parameters:
  ///   - [nodes]: List of nodes to get backhaul info for
  ///   - [refreshing]: If true, uses shorter timeouts
  ///
  /// Returns: Stream of BackHaulInfoData lists
  ///
  /// Stream completes when:
  ///   - All child node UUIDs found in backhaul info, OR
  ///   - Max retries exhausted
  Stream<List<BackHaulInfoData>> pollNodesBackhaulInfo(
    List<LinksysDevice> nodes, {
    bool refreshing = false,
  }) {
    final childNodes =
        nodes.where((e) => e.nodeType == 'Slave' && e.isOnline()).toList();
    logger.d(
        '[AddNodesService]: [pollNodesBackhaulInfo] check child nodes backhaul info data: $childNodes');

    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getBackhaulInfo,
      firstDelayInMilliSec: refreshing ? 1000 : 3000,
      retryDelayInMilliSec: refreshing ? 3000 : 3000,
      maxRetry: refreshing ? 1 : 20,
      auth: true,
      condition: (result) {
        if (result is JNAPSuccess) {
          final backhaulList = List.from(result.output['backhaulDevices'] ?? [])
              .map((e) => BackHaulInfoData.fromMap(e))
              .toList();

          // Check all MAC addresses can be found in the backhaul list
          bool allFound = backhaulList.isNotEmpty &&
              childNodes.every((n) => backhaulList
                  .any((backhaul) => backhaul.deviceUUID == n.deviceID));

          logger.d(
              '[AddNodesService]: [pollNodesBackhaulInfo] are All child deviceUUID in backhaul info data? $allFound');

          return allFound;
        }
        return false;
      },
      onCompleted: (_) {
        logger.d('[AddNodesService]: [pollNodesBackhaulInfo] Done!');
      },
    )
        .transform(
      StreamTransformer<JNAPResult, List<BackHaulInfoData>>.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            final backhaulList =
                List.from(result.output['backhaulDevices'] ?? [])
                    .map((e) => BackHaulInfoData.fromMap(e))
                    .toList();
            sink.add(backhaulList);
          }
        },
      ),
    );
  }

  /// Collects and merges backhaul info into child node data
  ///
  /// Parameters:
  ///   - [childNodes]: List of child nodes to enrich
  ///   - [backhaulInfoList]: Backhaul info data to merge
  ///
  /// Returns: List of LinksysDevice with backhaul info populated
  List<LinksysDevice> collectChildNodeData(
    List<LinksysDevice> childNodes,
    List<BackHaulInfoData> backhaulInfoList,
  ) {
    childNodes.sort((a, b) => a.isAuthority ? -1 : 1);
    final newChildNodes = childNodes.map((e) {
      final target =
          backhaulInfoList.firstWhereOrNull((d) => d.deviceUUID == e.deviceID);
      if (target != null) {
        return e.copyWith(
          wirelessConnectionInfo: target.wirelessConnectionInfo,
          connectionType: target.connectionType,
        );
      } else {
        return e;
      }
    }).toList();
    return newChildNodes;
  }
}
