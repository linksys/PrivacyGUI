import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/nodes/providers/add_nodes_state.dart';

final addNodesProvider =
    AsyncNotifierProvider.autoDispose<AddNodesNotifier, AddNodesState>(
        () => AddNodesNotifier());

class AddNodesNotifier extends AutoDisposeAsyncNotifier<AddNodesState> {
  @override
  FutureOr<AddNodesState> build() => const AddNodesState();

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
        .send(JNAPAction.getBluetoothAutoOnboardingSettings)
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
            // Complete
            logger.d('[AddNodes]getAutoOnboardingStatus complete!');
          },
          auth: true,
        );
  }

  Future startAutoOnboarding() async {
    logger.d('XXXXX: startAutoOnboarding: ${state.value?.nodesSnapshot}');
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      ref.read(pollingProvider.notifier).stopPolling();
      final nodeSnapshot =
          List<LinksysDevice>.from(ref.read(deviceManagerProvider).deviceList)
              .where((device) => device.isAuthority == false)
              .toList();

      final repo = ref.read(routerRepositoryProvider);
      await repo.send(JNAPAction.startBlueboothAutoOnboarding);

      // For AutoOnboarding 2 service, there has no deviceOnboardingStatus
      // only AutoOnboarding 3 service has deviceOnboardingStatus.
      bool onboardingProceed = false;
      bool anyOnboarded = false;
      var deviceOnboardingStatus = [];
      await for (final result in pollAutoOnboardingStatus()) {
        // Update onboarding status
        logger.d('XXXXX: [AddNodes]getAutoOnboardingStatus: $result');

        if (result is JNAPSuccess) {
          if (result.output['autoOnboardingStatus'] == 'Onboarding') {
            onboardingProceed = true;
          }
          //deviceOnboardingStatus
          deviceOnboardingStatus =
              result.output['deviceOnboardingStatus'] ?? [];
        }
      }
      anyOnboarded = List.from(deviceOnboardingStatus)
          .any((element) => element['onboardingStatus'] == 'Onboarded');
      List<String> onboardedMACList = [];
      if (anyOnboarded) {
        onboardedMACList = List.from(deviceOnboardingStatus)
            .where((element) => element['onboardingStatus'] == 'Onboarded')
            .map((e) => e['btMACAddress'] as String?)
            .whereNotNull()
            .toList();
      }
      List<RawDevice> addedDevices = [];
      List<RawDevice> childNodes = [];

      if (onboardingProceed && anyOnboarded) {
        await for (final result
            in pollForNodesOnline(nodeSnapshot, onboardedMACList)) {
          childNodes =
              result.where((element) => element.nodeType == 'Slave').toList();
          addedDevices = result
              .where(
                (element) =>
                    element.knownInterfaces?.any((knownInterface) =>
                        onboardedMACList.contains(knownInterface.macAddress)) ??
                    false,
              )
              .toList();
          logger.d('XXXXX: added devices: $addedDevices');
        }
      }
      final polling = ref.read(pollingProvider.notifier);
      await polling.forcePolling().then((value) => polling.startPolling());
      logger.d(
          'XXXXX: add nodes state: nodesSnapshot: $nodeSnapshot, onboardingProceed: $onboardingProceed, anyOnboarded: $anyOnboarded, addedDevices: $addedDevices');
      return AddNodesState(
        nodesSnapshot: nodeSnapshot,
        onboardingProceed: onboardingProceed,
        anyOnboarded: anyOnboarded,
        addedNodes: addedDevices,
        childNodes: childNodes,
      );
    });
  }

  Stream<List<RawDevice>> pollForNodesOnline(
    List<LinksysDevice> initDeviceList,
    List<String> onboardedMACList,
  ) {
    logger.d(
        'XXXXX: start poll for nodes online, onboardedMACList: $onboardedMACList');
    int testRetry = 0;
    int maxTestRetry = 1;
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .scheduledCommand(
            firstDelayInMilliSec: 30000,
            retryDelayInMilliSec: 30000,
            maxRetry: 6,
            auth: true,
            action: JNAPAction.getDevices,
            condition: (result) {
              if (result is JNAPSuccess) {
                logger.d('XXXXX: get devices result: $result');
                final deviceList = List.from(
                  result.output['devices'],
                )
                    .map((e) => LinksysDevice.fromMap(e))
                    .where((device) => device.isAuthority == false)
                    .toList();
                bool ret = false;

                // see any additional nodes shows.
                ret = deviceList.any((device) {
                  final hit =
                      initDeviceList.any((e) => e.deviceID == device.deviceID);

                  final hitFromOnboardMACList = device.knownInterfaces?.any(
                          (knownInterface) => onboardedMACList
                              .contains(knownInterface.macAddress)) ??
                      false;
                  logger.d(
                      'XXXXX: [pollForNodesOnline] test node<$device> is new added? ${!hit}, or included in the MAC list? $hitFromOnboardMACList');

                  final nameUpdated =
                      device.getDeviceLocation() != device.modelNumber;
                  if (hitFromOnboardMACList) {
                    logger.d(
                        'XXXXX: [pollForNodesOnline] check name is updated: ${device.getDeviceLocation()}, ${device.modelNumber}, $nameUpdated');
                  }
                  return !hit || (hitFromOnboardMACList && !nameUpdated);
                });
                if (!ret && testRetry++ > maxTestRetry) {
                  return true;
                }
              }
              return false;
            },
            onCompleted: () {
              logger.d('XXXXX: poll nodes complete');
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
                .toList()
              ..forEach((element) {
                logger.d(
                    'XXXXX: check node: location:${element.getDeviceLocation()}, name: ${element.getDeviceName()}, sn: ${element.unit.serialNumber}');
              });
            sink.add(deviceList);
          }
        },
      ),
    );
  }
}
