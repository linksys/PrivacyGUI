import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';

final addWiredNodesProvider =
    NotifierProvider.autoDispose<AddWiredNodesNotifier, AddWiredNodesState>(
        () => AddWiredNodesNotifier());

class AddWiredNodesNotifier extends AutoDisposeNotifier<AddWiredNodesState> {
  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  Future<void> setAutoOnboardingSettings(bool enabled) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.setWiredAutoOnboardingSettings,
            data: {
              'isAutoOnboardingEnabled': enabled,
            },
            auth: true);
  }

  Future<bool> getAutoOnboardingSettings() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getWiredAutoOnboardingSettings, auth: true)
        .then(
            (response) => response.output['isAutoOnboardingEnabled'] ?? false);
  }

  Future startAutoOnboarding(BuildContext context) async {
    logger.d('[AddWiredNode]: start auto onboarding');
    final log = BenchMarkLogger(name: 'Add Wired Node Process')..start();
    state = state.copyWith(
      isLoading: true,
      forceStop: false,
      loadingMessage: loc(context).addNodesSearchingNodes,
    );
    // Pause the idle checker
    ref.read(idleCheckerPauseProvider.notifier).state = true;
    // Set router auto onboarding to true
    await setAutoOnboardingSettings(true);
    // Get backhaul info
    final backhaulList = ref.read(deviceManagerProvider).backhaulInfoData;
    state = state.copyWith(backhaulSnapshot: backhaulList);

    // logger.d('[AddWiredNode]: polling connect status');
    // await _startPollingConnectStatus();
    // state = state.copyWith(loadingMessage: loc(context).addNodesOnboardingNodes);

    logger.d('[AddWiredNode]: check backhaul changes');
    await _checkBackhaulChanges(context);
    // Set router auto onboarding to false
    await stopAutoOnboarding();
    // Fetch latest status
    logger.d('[AddWiredNode]: fetch nodes');
    final nodes = await _fetchNodes();
    state = state.copyWith(nodes: nodes);
    stopCheckingBackhaul(context);
    await ref.read(pollingProvider.notifier).forcePolling();
    // Resume the idle checker
    ref.read(idleCheckerPauseProvider.notifier).state = false;
    final delta = log.end();
    logger.d('[AddWiredNode]: end auto onboarding, cost time: ${delta}ms');
  }

  // _startPollingConnectStatus() async {
  //   if (state.forceStop) {
  //     logger.d('[AddWiredNode]: force stop smart connect status');
  //     return;
  //   }
  //   final repo = ref.read(routerRepositoryProvider);
  //   final pin = await repo
  //       .send(JNAPAction.getSmartConnectPin,
  //           fetchRemote: true, cacheLevel: CacheLevel.noCache, auth: true)
  //       .then((result) => result.output['pin'])
  //       .onError((error, stackTrace) {
  //     logger.d('[AddWiredNode]: get pin error');
  //   });
  //   String getStatus(JNAPSuccess result) {
  //     final status = result.output['status'] ?? '';
  //     return status;
  //   }

  //   final pollStatusStream = repo.scheduledCommand(
  //       action: JNAPAction.getSmartConnectStatus,
  //       data: {'pin': pin},
  //       auth: true,
  //       maxRetry: 30,
  //       retryDelayInMilliSec: 3000,
  //       condition: (result) {
  //         if (state.forceStop) {
  //           logger.d('[AddWiredNode]: force stop smart connect status');
  //           return true;
  //         }
  //         if (result is! JNAPSuccess) {
  //           return false;
  //         }
  //         final status = getStatus(result);
  //         if (status == 'Connecting') {
  //           state = state.copyWith(onboardingProceed: true);
  //         }
  //         return status == 'Success' && state.onboardingProceed == true;
  //       });

  //   await for (final result in pollStatusStream) {
  //     if (result is JNAPSuccess) {
  //       final status = getStatus(result);
  //       logger.d('[AddWiredNode]: polling smart connect status: $status');
  //     }
  //   }
  // }

  Future _checkBackhaulChanges(BuildContext context,
      [bool refreshing = false]) async {
    if (state.forceStop) {
      logger.d('[AddWiredNode]: force stop poll backhaul info');
      return;
    }
    final pollBackhaul = pollBackhaulInfo(context, refreshing);

    await for (final result in pollBackhaul) {
      if (result is! JNAPSuccess) {
        return;
      }
      state = state.copyWith(onboardingProceed: true);
    }
  }

  Stream pollBackhaulInfo(BuildContext context, [bool refreshing = false]) {
    final repo = ref.read(routerRepositoryProvider);
    final now = DateTime.now();
    return repo.scheduledCommand(
      action: JNAPAction.getBackhaulInfo,
      auth: true,
      firstDelayInMilliSec: 1 * 1000,
      retryDelayInMilliSec: 10 * 1000,
      maxRetry: refreshing ? 6 : 60,
      condition: (result) {
        if (state.forceStop) {
          logger.d('[AddWiredNode]: force stop poll backhaul info');
          return true;
        }
        if (result is! JNAPSuccess) {
          return false;
        }
        final backhaulInfoList = List.from(
          result.output['backhaulDevices'] ?? [],
        ).map((e) => BackHaulInfoData.fromMap(e)).toList();
        final foundCounting = backhaulInfoList.fold<int>(0, (value, infoData) {
          final dateFormat = DateFormat("yyyy-MM-ddThh:mm:ssZ");
          // find the node which uuid is already exist on backhaul snapshot,
          // and the connection type is "Wired"
          // and the timestamp is less than current time
          // and if the uuid is exist the timestamp is less than snapshot one
          // if satisfy the above condition, then this is not the new added one.
          return (state.backhaulSnapshot?.any((e) =>
                      e.deviceUUID == infoData.deviceUUID &&
                      infoData.connectionType == 'Wired' &&
                      now.millisecondsSinceEpoch >
                          (dateFormat
                                  .tryParse(infoData.timestamp)
                                  ?.millisecondsSinceEpoch ??
                              0) &&
                      (dateFormat
                                  .tryParse(e.timestamp)
                                  ?.millisecondsSinceEpoch ??
                              0) <
                          (dateFormat
                                  .tryParse(infoData.timestamp)
                                  ?.millisecondsSinceEpoch ??
                              0)) ==
                  true)
              ? value
              : value + 1;
        });
        if (foundCounting > 0) {
          state = state.copyWith(
              loadingMessage: loc(context).foundNNodesOnline(foundCounting),
              anyOnboarded: true);
        }
        logger.i('[AddWiredNode]: Found $foundCounting new nodes');
        return false;
      },
      onCompleted: (_) {
        logger.i('[AddWiredNode]: poll backhaul info is completed');
      },
    );
  }

  ///
  /// Auto onboarding flow with _startPollingConnectStatus
  ///
  // Stream pollBackhaulInfo([bool refreshing = false]) {
  //   final repo = ref.read(routerRepositoryProvider);
  //   int nodeCounting = 0;
  //   int noChangesCounting = 0;
  //   final noChangesThrethold = refreshing ? 6 : 12;
  //   final now = DateTime.now();
  //   return repo.scheduledCommand(
  //     action: JNAPAction.getBackhaulInfo,
  //     auth: true,
  //     firstDelayInMilliSec: 1 * 1000,
  //     retryDelayInMilliSec: 10 * 1000,
  //     maxRetry: refreshing ? 6 : 30,
  //     condition: (result) {
  //       if (state.forceStop) {
  //         logger.d('[AddWiredNode]: force stop poll backhaul info');
  //         return true;
  //       }
  //       if (result is! JNAPSuccess) {
  //         return false;
  //       }
  //       final backhaulInfoList = List.from(
  //         result.output['backhaulDevices'] ?? [],
  //       ).map((e) => BackHaulInfoData.fromMap(e)).toList();
  //       final foundCounting = backhaulInfoList.fold<int>(0, (value, infoData) {
  //         final dateFormat = DateFormat("yyyy-MM-ddThh:mm:ssZ");
  //         // find the node which uuid is already exist on backhaul snapshot,
  //         // and the connection type is "Wired"
  //         // and the timestamp is less than current time
  //         // and if the uuid is exist the timestamp is less than snapshot one
  //         // if satisfy the above condition, then this is not the new added one.
  //         return (state.backhaulSnapshot?.any((e) =>
  //                     e.deviceUUID == infoData.deviceUUID &&
  //                     infoData.connectionType == 'Wired' &&
  //                     now.millisecondsSinceEpoch >
  //                         (dateFormat
  //                                 .tryParse(infoData.timestamp)
  //                                 ?.millisecondsSinceEpoch ??
  //                             0) &&
  //                     (dateFormat
  //                                 .tryParse(e.timestamp)
  //                                 ?.millisecondsSinceEpoch ??
  //                             0) <
  //                         (dateFormat
  //                                 .tryParse(infoData.timestamp)
  //                                 ?.millisecondsSinceEpoch ??
  //                             0)) ==
  //                 true)
  //             ? value
  //             : value + 1;
  //       });
  //       // if found counting is changed then record the counting
  //       // if not changed, increase no changes counting
  //       // if no changes counting exceed to 12 (no changes within 2 minutes) and has found changes
  //       // then end this check process
  //       if (foundCounting != nodeCounting) {
  //         nodeCounting = foundCounting;
  //       } else {
  //         noChangesCounting++;
  //         logger.i(
  //           '[AddWiredNode]: There has no changes on the backhaul. found counting=$foundCounting, check times=$noChangesCounting',
  //         );
  //         return noChangesCounting > noChangesThrethold && nodeCounting > 0;
  //       }
  //       logger.i('[AddWiredNode]: Found $foundCounting new nodes');
  //       return false;
  //     },
  //     onCompleted: (_) {
  //       logger.i('[AddWiredNode]: poll backhaul info is completed');
  //     },
  //   );
  // }

  Future _fetchNodes() async {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(JNAPAction.getDevices, fetchRemote: true, auth: true)
        .then((result) {
      // nodes
      final nodeList = List.from(
        result.output['devices'],
      )
          .map((e) => LinksysDevice.fromMap(e))
          .where((device) => device.nodeType != null)
          .toList();
      return nodeList;
    }).onError((error, stackTrace) {
      logger.i('[AddWiredNode]: fetch node failed! $error');
      return [];
    });
  }

  void stopCheckingBackhaul(BuildContext context) {
    state = state.copyWith(
      isLoading: false,
      forceStop: false,
    );
  }

  Future stopAutoOnboarding() async {
    await setAutoOnboardingSettings(false);
    ref.read(idleCheckerPauseProvider.notifier).state = false;
  }

  Future forceStopAutoOnboarding() async {
    logger.i('[AddWiredNode]: force stop auto onboarding');
    if (state.isLoading) {
      state = state.copyWith(forceStop: true);
    }
  }
}
