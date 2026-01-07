import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';
import 'package:privacy_gui/page/nodes/services/add_wired_nodes_service.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';

final addWiredNodesProvider =
    NotifierProvider.autoDispose<AddWiredNodesNotifier, AddWiredNodesState>(
        () => AddWiredNodesNotifier());

class AddWiredNodesNotifier extends AutoDisposeNotifier<AddWiredNodesState> {
  /// Service accessor for JNAP communication
  AddWiredNodesService get _service => ref.read(addWiredNodesServiceProvider);

  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  /// Enables or disables wired auto-onboarding settings
  ///
  /// Delegates to [AddWiredNodesService.setAutoOnboardingEnabled]
  Future<void> setAutoOnboardingSettings(bool enabled) {
    return _service.setAutoOnboardingEnabled(enabled);
  }

  /// Gets current wired auto-onboarding settings
  ///
  /// Delegates to [AddWiredNodesService.getAutoOnboardingEnabled]
  Future<bool> getAutoOnboardingSettings() {
    return _service.getAutoOnboardingEnabled();
  }

  /// Starts the wired auto-onboarding flow
  ///
  /// This method orchestrates the full onboarding process:
  /// 1. Enable auto-onboarding on router
  /// 2. Capture initial backhaul snapshot
  /// 3. Poll for backhaul changes (new wired nodes)
  /// 4. Disable auto-onboarding
  /// 5. Fetch final node list
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
    if (!context.mounted) return;

    // Get backhaul info from deviceManager and convert to UI model
    final backhaulData = ref.read(deviceManagerProvider).backhaulInfoData;
    final backhaulSnapshot = backhaulData
        .map((data) => BackhaulInfoUIModel(
              deviceUUID: data.deviceUUID,
              connectionType: data.connectionType,
              timestamp: data.timestamp,
            ))
        .toList();
    state = state.copyWith(backhaulSnapshot: backhaulSnapshot);

    logger.d('[AddWiredNode]: check backhaul changes');
    await _checkBackhaulChanges(context, backhaulSnapshot);
    // Set router auto onboarding to false
    await stopAutoOnboarding();
    // Fetch latest status
    logger.d('[AddWiredNode]: fetch nodes');
    final nodes = await _service.fetchNodes();
    if (!context.mounted) return;
    state = state.copyWith(nodes: nodes);
    stopCheckingBackhaul(context);
    await ref.read(pollingProvider.notifier).forcePolling();
    // Resume the idle checker
    ref.read(idleCheckerPauseProvider.notifier).state = false;
    final delta = log.end();
    logger.d('[AddWiredNode]: end auto onboarding, cost time: ${delta}ms');
  }

  /// Checks for backhaul changes by polling the service
  ///
  /// Uses [AddWiredNodesService.pollBackhaulChanges] to detect new wired nodes
  Future _checkBackhaulChanges(
    BuildContext context,
    List<BackhaulInfoUIModel> snapshot, [
    bool refreshing = false,
  ]) async {
    if (state.forceStop) {
      logger.d('[AddWiredNode]: force stop poll backhaul info');
      return;
    }

    final pollStream = _service.pollBackhaulChanges(
      snapshot,
      refreshing: refreshing,
    );

    await for (final result in pollStream) {
      if (state.forceStop) {
        logger.d('[AddWiredNode]: force stop poll backhaul info');
        break;
      }

      // Update state based on poll result
      if (result.foundCounting > 0) {
        state = state.copyWith(
          loadingMessage: loc(context).foundNNodesOnline(result.foundCounting),
          anyOnboarded: result.anyOnboarded,
          onboardingProceed: true,
        );
      }
    }
  }

  /// Stops the backhaul checking process and resets loading state
  void stopCheckingBackhaul(BuildContext context) {
    state = state.copyWith(
      isLoading: false,
      forceStop: false,
    );
  }

  /// Stops auto-onboarding by disabling the setting on the router
  ///
  /// Delegates to [AddWiredNodesService.setAutoOnboardingEnabled]
  Future stopAutoOnboarding() async {
    await setAutoOnboardingSettings(false);
    ref.read(idleCheckerPauseProvider.notifier).state = false;
  }

  /// Forces immediate stop of the auto-onboarding process
  Future forceStopAutoOnboarding() async {
    logger.i('[AddWiredNode]: force stop auto onboarding');
    if (state.isLoading) {
      state = state.copyWith(forceStop: true);
    }
  }
}
