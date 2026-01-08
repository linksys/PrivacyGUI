import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';

/// Riverpod provider for AddWiredNodesService
final addWiredNodesServiceProvider = Provider<AddWiredNodesService>((ref) {
  return AddWiredNodesService(ref.watch(routerRepositoryProvider));
});

/// Result container for pollBackhaulChanges stream emissions
class BackhaulPollResult {
  final List<BackhaulInfoUIModel> backhaulList;
  final int foundCounting;
  final bool anyOnboarded;

  const BackhaulPollResult({
    required this.backhaulList,
    required this.foundCounting,
    required this.anyOnboarded,
  });
}

/// Stateless service for Add Wired Nodes / Wired Auto-Onboarding operations
///
/// Encapsulates JNAP communication for wired node onboarding, separating
/// business logic from state management (AddWiredNodesNotifier).
///
/// Reference: constitution Article VI - Service Layer Principle
class AddWiredNodesService {
  /// Constructor injection of RouterRepository
  AddWiredNodesService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Enables or disables wired auto-onboarding on the router
  ///
  /// Parameters:
  ///   - [enabled]: true to enable, false to disable
  ///
  /// Throws:
  ///   - [NetworkError] if router communication fails
  ///   - [UnauthorizedError] if authentication expired
  ///   - [UnexpectedError] for other JNAP failures
  Future<void> setAutoOnboardingEnabled(bool enabled) async {
    try {
      await _routerRepository.send(
        JNAPAction.setWiredAutoOnboardingSettings,
        data: {'isAutoOnboardingEnabled': enabled},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Fetches current wired auto-onboarding setting
  ///
  /// Returns:
  ///   - `true` if auto-onboarding is enabled
  ///   - `false` if disabled or not configured
  ///
  /// Throws:
  ///   - [NetworkError] if router communication fails
  ///   - [UnauthorizedError] if authentication expired
  ///   - [UnexpectedError] for other JNAP failures
  Future<bool> getAutoOnboardingEnabled() async {
    try {
      final response = await _routerRepository.send(
        JNAPAction.getWiredAutoOnboardingSettings,
        auth: true,
      );
      return response.output['isAutoOnboardingEnabled'] ?? false;
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Polls for backhaul changes compared to a snapshot
  ///
  /// Detects new wired nodes by comparing current backhaul info against
  /// the provided snapshot, using timestamp comparison to identify new entries.
  ///
  /// Parameters:
  ///   - [snapshot]: Previous backhaul state to compare against
  ///   - [refreshing]: If true, uses shorter timeouts for refresh operations
  ///
  /// Returns: Stream of [BackhaulPollResult] containing:
  ///   - [backhaulList]: Current backhaul entries as UI models
  ///   - [foundCounting]: Number of new nodes detected
  ///   - [anyOnboarded]: true if at least one new node was found
  ///
  /// Polling Config:
  ///   - Normal: 1s first delay, 10s retry delay, 60 retries (~10 minutes)
  ///   - Refreshing: 1s first delay, 10s retry delay, 6 retries (~1 minute)
  Stream<BackhaulPollResult> pollBackhaulChanges(
    List<BackhaulInfoUIModel> snapshot, {
    bool refreshing = false,
  }) {
    final now = DateTime.now();
    final dateFormat = DateFormat("yyyy-MM-ddThh:mm:ssZ");
    bool anyOnboarded = false;

    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getBackhaulInfo,
      auth: true,
      firstDelayInMilliSec: 1 * 1000,
      retryDelayInMilliSec: 10 * 1000,
      maxRetry: refreshing ? 6 : 60,
      condition: (result) {
        if (result is! JNAPSuccess) {
          return false;
        }
        // Keep polling until timeout - no early termination
        return false;
      },
      onCompleted: (_) {
        logger.i('[AddWiredNodesService]: poll backhaul info is completed');
      },
    )
        .transform(
      StreamTransformer<JNAPResult, BackhaulPollResult>.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            final backhaulInfoList = List.from(
              result.output['backhaulDevices'] ?? [],
            ).map((e) => BackHaulInfoData.fromMap(e)).toList();

            // Calculate found counting - detect new wired nodes
            final foundCounting =
                backhaulInfoList.fold<int>(0, (value, infoData) {
              // Find nodes that are:
              // 1. Connection type is "Wired"
              // 2. Timestamp is after poll start time (now)
              // 3. Either new UUID or timestamp newer than snapshot
              final isNewNode = !_isExistingWiredNode(
                infoData,
                snapshot,
                now,
                dateFormat,
              );
              return isNewNode ? value + 1 : value;
            });

            if (foundCounting > 0) {
              anyOnboarded = true;
            }

            logger.i('[AddWiredNodesService]: Found $foundCounting new nodes');

            // Convert to UI models
            final uiModels = backhaulInfoList
                .map((data) => BackhaulInfoUIModel(
                      deviceUUID: data.deviceUUID,
                      connectionType: data.connectionType,
                      timestamp: data.timestamp,
                    ))
                .toList();

            sink.add(BackhaulPollResult(
              backhaulList: uiModels,
              foundCounting: foundCounting,
              anyOnboarded: anyOnboarded,
            ));
          }
        },
      ),
    );
  }

  /// Checks if a backhaul entry is an existing wired node (not newly added)
  ///
  /// A node is considered "existing" if:
  /// - Its UUID exists in snapshot AND
  /// - Connection type is "Wired" AND
  /// - Timestamp is before poll start AND
  /// - Timestamp is same or earlier than snapshot timestamp for same UUID
  bool _isExistingWiredNode(
    BackHaulInfoData infoData,
    List<BackhaulInfoUIModel> snapshot,
    DateTime pollStartTime,
    DateFormat dateFormat,
  ) {
    // Check if this device was in the snapshot
    final snapshotEntry = snapshot.firstWhere(
      (e) => e.deviceUUID == infoData.deviceUUID,
      orElse: () => const BackhaulInfoUIModel(
        deviceUUID: '',
        connectionType: '',
        timestamp: '',
      ),
    );

    // If not found in snapshot, it's new
    if (snapshotEntry.deviceUUID.isEmpty) {
      return false;
    }

    // Must be wired connection
    if (infoData.connectionType != 'Wired') {
      return false;
    }

    final infoTimestamp =
        dateFormat.tryParse(infoData.timestamp)?.millisecondsSinceEpoch ?? 0;
    final snapshotTimestamp =
        dateFormat.tryParse(snapshotEntry.timestamp)?.millisecondsSinceEpoch ??
            0;
    final nowTimestamp = pollStartTime.millisecondsSinceEpoch;

    // Check timestamps:
    // - Info timestamp must be before poll start (now)
    // - Info timestamp must be same or earlier than snapshot timestamp
    return nowTimestamp > infoTimestamp && infoTimestamp <= snapshotTimestamp;
  }

  /// Fetches all node devices from the router
  ///
  /// Returns: List of [LinksysDevice] where nodeType != null
  ///
  /// Note: Returns empty list on error instead of throwing (matches existing behavior)
  Future<List<LinksysDevice>> fetchNodes() async {
    try {
      final response = await _routerRepository.send(
        JNAPAction.getDevices,
        fetchRemote: true,
        auth: true,
      );

      final nodeList = List.from(response.output['devices'])
          .map((e) => LinksysDevice.fromMap(e))
          .where((device) => device.nodeType != null)
          .toList();

      return nodeList;
    } catch (error) {
      logger.i('[AddWiredNodesService]: fetch node failed! $error');
      return [];
    }
  }
}
