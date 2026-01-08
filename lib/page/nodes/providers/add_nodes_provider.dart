import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart';

final addNodesProvider =
    NotifierProvider.autoDispose<AddNodesNotifier, AddNodesState>(
        () => AddNodesNotifier());

class AddNodesNotifier extends AutoDisposeNotifier<AddNodesState> {
  /// Get AddNodesService instance
  AddNodesService get _service => ref.read(addNodesServiceProvider);

  @override
  AddNodesState build() => const AddNodesState();

  Future<void> setAutoOnboardingSettings() {
    return _service.setAutoOnboardingSettings();
  }

  Future<bool> getAutoOnboardingSettings() {
    return _service.getAutoOnboardingSettings();
  }

  FutureOr<Map<String, dynamic>> getAutoOnboardingStatus() {
    return _service.pollAutoOnboardingStatus(oneTake: true).first;
  }

  Future startAutoOnboarding() async {
    logger.d('[AddNodes]: Start Bluetooth auto-onboarding process');
    final benchMark = BenchMarkLogger(name: 'AutoOnboarding');
    benchMark.start();

    ref.read(pollingProvider.notifier).stopPolling();

    // Commence the auto-onboarding process
    await _service.startAutoOnboarding();

    bool onboardingProceed = false;
    // For AutoOnboarding 2 service, there has no deviceOnboardingStatus
    // only AutoOnboarding 3 service has deviceOnboardingStatus.
    bool anyOnboarded = false;
    var deviceOnboardingStatus = [];

    state = state.copyWith(isLoading: true, loadingMessage: 'searching');

    await for (final result in _service.pollAutoOnboardingStatus()) {
      logger.d('[AddNodes]: GetAutoOnboardingStatus result: $result');
      // Update onboarding status
      if (result['status'] == 'Onboarding') {
        onboardingProceed = true;
      }
      // Set deviceOnboardingStatus data
      deviceOnboardingStatus = result['deviceOnboardingStatus'] ?? [];
    }
    // Get onboarded device data
    anyOnboarded = List.from(deviceOnboardingStatus)
        .any((element) => element['onboardingStatus'] == 'Onboarded');
    // Get the MAC address list of these onboarded devices
    List<String> onboardedMACList = [];
    if (anyOnboarded) {
      onboardedMACList = List.from(deviceOnboardingStatus)
          .where((element) => element['onboardingStatus'] == 'Onboarded')
          .map((e) => e['btMACAddress'] as String?)
          .nonNulls
          .toList();
    }
    logger.d(
        '[AddNodes]: Number of onboarded MAC addresses = ${onboardedMACList.length}');
    List<LinksysDevice> addedDevices = [];
    List<LinksysDevice> childNodes = [];
    List<LinksysDevice> childNodesWithBackhaul = [];
    state = state.copyWith(isLoading: true, loadingMessage: 'onboarding');
    if (onboardingProceed && anyOnboarded) {
      await for (final result
          in _service.pollForNodesOnline(onboardedMACList)) {
        childNodes =
            result.where((element) => element.nodeType != null).toList();
        addedDevices = result
            .where(
              (element) =>
                  element.nodeType == 'Slave' &&
                  (element.knownInterfaces?.any((knownInterface) =>
                          onboardedMACList
                              .contains(knownInterface.macAddress)) ??
                      false),
            )
            .toList();
        logger.d(
            '[AddNodes]: [pollForNodesOnline] added devices: ${addedDevices.map((d) => d.toJson()).join(', ')}');
      }
      // Poll and merge backhaul info using Service
      await for (final result in _service.pollNodesBackhaulInfo(childNodes)) {
        childNodesWithBackhaul =
            _service.collectChildNodeData(childNodes, result);
      }
    }
    childNodes.sort((a, b) => a.isAuthority ? -1 : 1);
    final polling = ref.read(pollingProvider.notifier);
    await polling.forcePolling().then((value) => polling.startPolling());
    logger.d('[AddNodes]: Update state: addedDevices = $addedDevices');
    logger.d(
        '[AddNodes]: Update state: onboardingProceed = $onboardingProceed, anyOnboarded=$anyOnboarded');
    benchMark.end();

    state = state.copyWith(
      onboardingProceed: onboardingProceed,
      anyOnboarded: anyOnboarded,
      addedNodes: addedDevices,
      childNodes: childNodesWithBackhaul.isNotEmpty
          ? childNodesWithBackhaul
          : _service.collectChildNodeData(childNodes, []),
      isLoading: false,
      onboardedMACList: onboardedMACList,
    );
  }

  Future startRefresh() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'searching');

    List<LinksysDevice> childNodes = [];
    List<LinksysDevice> childNodesWithBackhaul = [];

    await for (final result in _service
        .pollForNodesOnline(state.onboardedMACList ?? [], refreshing: true)) {
      childNodes = result.where((element) => element.nodeType != null).toList();
    }
    await for (final result
        in _service.pollNodesBackhaulInfo(childNodes, refreshing: true)) {
      childNodesWithBackhaul =
          _service.collectChildNodeData(childNodes, result);
    }
    state = state.copyWith(
      childNodes: childNodesWithBackhaul.isNotEmpty
          ? childNodesWithBackhaul
          : _service.collectChildNodeData(childNodes, []),
      isLoading: false,
      loadingMessage: '',
    );
  }
}
