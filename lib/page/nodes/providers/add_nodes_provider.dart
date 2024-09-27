import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';

final addNodesProvider =
    NotifierProvider.autoDispose<AddNodesNotifier, AddNodesState>(
        () => AddNodesNotifier());

class AddNodesNotifier extends AutoDisposeNotifier<AddNodesState> {
  @override
  AddNodesState build() => const AddNodesState();

  Future<void> setAutoOnboardingSettings() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.setBluetoothAutoOnboardingSettings,
            data: {
              'isAutoOnboardingEnabled': true,
            },
            auth: true);
  }

  Future<bool> getAutoOnboardingSettings() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getBluetoothAutoOnboardingSettings, auth: true)
        .then(
            (response) => response.output['isAutoOnboardingEnabled'] ?? false);
  }

  FutureOr getAutoOnboardingStatus() {
    return pollAutoOnboardingStatus(oneTake: true).first;
  }

  Stream<JNAPResult> pollAutoOnboardingStatus({bool oneTake = false}) {
    return ref.read(routerRepositoryProvider).scheduledCommand(
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
          onCompleted: () {
            logger.d('[AddNodes]: GetAutoOnboardingStatus Done!');
          },
          auth: true,
        );
  }

  Future startAutoOnboarding() async {
    logger.d('[AddNodes]: Start Bluetooth auto-onboarding process');
    final benchMark = BenchMarkLogger(name: 'AutoOnboarding');
    benchMark.start();

    ref.read(pollingProvider.notifier).stopPolling();
    final nodeSnapshot =
        List<LinksysDevice>.from(ref.read(deviceManagerProvider).deviceList)
            .toList();
    // Commence the auto-onboarding process
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(JNAPAction.startBlueboothAutoOnboarding, auth: true);

    bool onboardingProceed = false;
    // For AutoOnboarding 2 service, there has no deviceOnboardingStatus
    // only AutoOnboarding 3 service has deviceOnboardingStatus.
    bool anyOnboarded = false;
    var deviceOnboardingStatus = [];

    state = state.copyWith(isLoading: true, loadingMessage: 'searching');

    await for (final result in pollAutoOnboardingStatus()) {
      logger.d('[AddNodes]: GetAutoOnboardingStatus result: $result');
      // Update onboarding status
      if (result is JNAPSuccess) {
        if (result.output['autoOnboardingStatus'] == 'Onboarding') {
          onboardingProceed = true;
        }
        // Set deviceOnboardingStatus data
        deviceOnboardingStatus = result.output['deviceOnboardingStatus'] ?? [];
      }
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
          .whereNotNull()
          .toList();
    }
    logger.d(
        '[AddNodes]: Number of onboarded MAC addresses = ${onboardedMACList.length}');
    List<RawDevice> addedDevices = [];
    List<RawDevice> childNodes = [];

    state = state.copyWith(isLoading: true, loadingMessage: 'onboarding');
    if (onboardingProceed && anyOnboarded) {
      await for (final result in pollForNodesOnline(onboardedMACList)) {
        childNodes =
            result.where((element) => element.nodeType != null).toList();
        addedDevices = result
            .where(
              (element) =>
                  element.knownInterfaces?.any((knownInterface) =>
                      onboardedMACList.contains(knownInterface.macAddress)) ??
                  false,
            )
            .toList();
        logger
            .d('[AddNodes]: [pollForNodesOnline] added devices: $addedDevices');
      }
    } else {
      // put original slave nodes
      childNodes =
          nodeSnapshot.where((element) => element.nodeType != null).toList();
    }
    final polling = ref.read(pollingProvider.notifier);
    await polling.forcePolling().then((value) => polling.startPolling());
    logger.d('[AddNodes]: Update state: nodesSnapshot = $nodeSnapshot');
    logger.d('[AddNodes]: Update state: addedDevices = $addedDevices');
    logger.d(
        '[AddNodes]: Update state: onboardingProceed = $onboardingProceed, anyOnboarded=$anyOnboarded');
    benchMark.end();

    state = state.copyWith(
      nodesSnapshot: nodeSnapshot,
      onboardingProceed: onboardingProceed,
      anyOnboarded: anyOnboarded,
      addedNodes: addedDevices,
      childNodes: childNodes,
      isLoading: false,
      onboardedMACList: onboardedMACList,
    );
  }

  Stream<List<RawDevice>> pollForNodesOnline(List<String> onboardedMACList,
      {bool refreshing = false}) {
    logger
        .d('[AddNodes]: [pollForNodesOnline] Start by MACs: $onboardedMACList');
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .scheduledCommand(
            firstDelayInMilliSec: refreshing ? 1000 : 20000,
            retryDelayInMilliSec: refreshing ? 3000 : 20000,
            maxRetry: refreshing ? 5 : 9,
            auth: true,
            action: JNAPAction.getDevices,
            condition: (result) {
              if (result is JNAPSuccess) {
                final deviceList = List.from(
                  result.output['devices'],
                )
                    .map((e) => LinksysDevice.fromMap(e))
                    .where((device) => device.isAuthority == false)
                    .toList();
                // check all mac address in the list can be found on the device list
                bool allFound = onboardedMACList.every((mac) => deviceList.any(
                    (device) =>
                        device.knownInterfaces?.any((knownInterface) =>
                            knownInterface.macAddress == mac) ??
                        false));
                logger.d(
                    '[AddNodes]: [pollForNodesOnline] are All MACs in device list? $allFound');
                // see any additional nodes || nodes in the mac list all has connections.
                bool ret = deviceList
                    .where((device) =>
                        device.knownInterfaces?.any((knownInterface) =>
                            onboardedMACList
                                .contains(knownInterface.macAddress)) ??
                        false)
                    .every((device) {
                  final hasConnections = device.isOnline();
                  logger.d(
                      '[AddNodes]: [pollForNodesOnline] <${device.getDeviceLocation()}> has connections: $hasConnections');
                  return hasConnections;
                });
                return allFound && ret;
              }
              return false;
            },
            onCompleted: () {
              logger.d('[AddNodes]: [pollForNodesOnline] Done!');
            })
        .transform(
      StreamTransformer<JNAPResult, List<RawDevice>>.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            final deviceList = List.from(
              result.output['devices'],
            )
                .map((e) => LinksysDevice.fromMap(e))
                .where((device) => device.isAuthority == false)
                .toList();
            sink.add(deviceList);
          }
        },
      ),
    );
  }

  Future startRefresh() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'searching');

    List<RawDevice> childNodes = [];
    await for (final result
        in pollForNodesOnline(state.onboardedMACList ?? [], refreshing: true)) {
      childNodes =
          result.where((element) => element.nodeType == 'Slave').toList();
    }

    state = state.copyWith(
      childNodes: childNodes,
      isLoading: false,
      loadingMessage: '',
    );
  }
}
