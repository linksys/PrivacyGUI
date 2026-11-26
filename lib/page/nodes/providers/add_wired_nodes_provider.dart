import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:privacy_gui/providers/auth/auth_provider.dart';

final addWiredNodesProvider =
    NotifierProvider.autoDispose<AddWiredNodesNotifier, AddWiredNodesState>(
        () => AddWiredNodesNotifier());

class AddWiredNodesNotifier extends AutoDisposeNotifier<AddWiredNodesState> {
  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  /// The login the running flow belongs to (#1904). Its backhaul reads end at
  /// a logout, and so does the flow. Null while no flow runs.
  int? _logoutGeneration;

  bool get _loggedOut {
    final generation = _logoutGeneration;
    return generation != null &&
        ref.read(authProvider.notifier).loggedOutSince(generation);
  }

  Future<void> setAutoOnboardingSettings(bool enabled) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.setWiredAutoOnboardingSettings,
            data: {
              'isAutoOnboardingEnabled': enabled,
            },
            auth: true);
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
    _logoutGeneration = ref.read(authProvider.notifier).logoutGeneration;
    // Whether the router's wired onboarding is on, so that a run that fails
    // part way still turns it off.
    var onboardingOn = false;
    try {
      // Set router auto onboarding to true
      await setAutoOnboardingSettings(true);
      onboardingOn = true;
      // Get backhaul info
      final backhaulList = ref.read(deviceManagerProvider).backhaulInfoData;
      state = state.copyWith(backhaulSnapshot: backhaulList);

      logger.d('[AddWiredNode]: check backhaul changes');
      await _checkBackhaulChanges(context);
      // Set router auto onboarding to false
      await stopAutoOnboarding();
      onboardingOn = false;
      // Fetch latest status
      logger.d('[AddWiredNode]: fetch nodes');
      final nodes = await _fetchNodes();
      state = state.copyWith(nodes: nodes);
      stopCheckingBackhaul(context);
      await ref.read(pollingProvider.notifier).forcePolling();
    } on LoggedOutException {
      // The login the run belonged to has ended; its dialog is gone.
      logger.d('[AddWiredNode]: Logged out, the run is dropped');
    } finally {
      // A run that fails part way must not leave wired onboarding on at the
      // router, the idle logout off for the rest of the session, nor the
      // dialog loading. After a logout, though, nothing more is asked of the
      // router: the request would carry the factory default password (#1904).
      if (onboardingOn && !_loggedOut) {
        await setAutoOnboardingSettings(false).catchError((Object error) {
          logger
              .e('[AddWiredNode]: could not turn wired onboarding off: $error');
        });
      }
      if (state.isLoading) {
        state = state.copyWith(isLoading: false, forceStop: false);
      }
      // Resume the idle checker
      ref.read(idleCheckerPauseProvider.notifier).state = false;
      _logoutGeneration = null;
    }
    final delta = log.end();
    logger.d('[AddWiredNode]: end auto onboarding, cost time: ${delta}ms');
  }

  Future _checkBackhaulChanges(BuildContext context,
      [bool refreshing = false]) async {
    if (state.forceStop) {
      logger.d('[AddWiredNode]: force stop poll backhaul info');
      return;
    }
    final pollBackhaul = pollBackhaulInfo(context, refreshing);

    await for (final result in pollBackhaul) {
      // A read that fails, such as one that times out while a node joins,
      // does not end the watch: the poll's condition keeps going too.
      if (result is! JNAPSuccess) {
        continue;
      }
      state = state.copyWith(onboardingProceed: true);
    }
  }

  Stream pollBackhaulInfo(BuildContext context, [bool refreshing = false]) {
    final repo = ref.read(routerRepositoryProvider);
    return repo.scheduledCommand(
      action: JNAPAction.getBackhaulInfo,
      auth: true,
      logoutGeneration: _logoutGeneration,
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
        // A node is new when it was not on the backhaul the app last polled.
        // A node already in the mesh is never new, however its backhaul
        // changed: wired or wireless, refreshed or not.
        final known = {
          for (final e in state.backhaulSnapshot ?? <BackHaulInfoData>[])
            e.deviceUUID,
        };
        final foundCounting = backhaulInfoList
            .where((infoData) => !known.contains(infoData.deviceUUID))
            .length;
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
