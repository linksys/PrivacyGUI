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
  StreamSubscription? _autoOnboardingStatusSub;

  @override
  FutureOr<AddNodesState> build() => AddNodesState();

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
      logger.d('XXXXX: [init nodes] $nodeSnapshot');

      final repo = ref.read(routerRepositoryProvider);
      await repo.send(JNAPAction.startBlueboothAutoOnboarding);

      // For AutoOnboarding 2 service, there has no deviceOnboardingStatus
      // only AutoOnboarding 3 service has deviceOnboardingStatus.
      bool onboardingProceed = false;
      bool anyOnboarded = false;
      await for (final result in pollAutoOnboardingStatus()) {
        // Update onboarding status
        logger.d('XXXXX: [AddNodes]getAutoOnboardingStatus: $result');
        if (result is JNAPSuccess &&
            result.output['autoOnboardingStatus'] == 'Onboarding') {
          onboardingProceed = true;
        }
        //deviceOnboardingStatus
        if (result is JNAPSuccess) {
          if (result.output['autoOnboardingStatus'] == 'Onboarding') {
            onboardingProceed = true;
          }
          final deviceOnboardingStatus =
              result.output['deviceOnboardingStatus'] ?? [];
          anyOnboarded = List.from(deviceOnboardingStatus)
              .any((element) => element['onboardingStatus'] == 'Onboarded');
        }
      }
      if (onboardingProceed && anyOnboarded) {
        await for (final result in pollForNodesOnline(nodeSnapshot)) {}
      }
      final polling = ref.read(pollingProvider.notifier);
      await polling.forcePolling().then((value) => polling.startPolling());
      return AddNodesState(nodesSnapshot: nodeSnapshot);
    });
  }

  Stream pollForNodesOnline(List<LinksysDevice> initDeviceList) {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .scheduledCommand(
            firstDelayInMilliSec: 30000,
            retryDelayInMilliSec: 30000,
            maxRetry: 4,
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
                bool ret = false;
                // see any additional nodes shows.
                for (var element in deviceList) {
                  logger.d('XXXXX: [pollForNodesOnline] $element');
                }
                ret = deviceList.any((element) {
                  final hit = initDeviceList
                      .firstWhereOrNull((e) => e.deviceID == element.deviceID);
                  logger.d(
                      'XXXXX: [pollForNodesOnline] test node<$element> is new added? ${hit == null}');
                  return hit == null;
                });
                if (!ret) {
                  return true;
                }
              }
              return false;
            },
            onCompleted: () {
              logger.d('XXXXX: poll nodes complete');
            })
        .transform(
      StreamTransformer.fromHandlers(
        handleData: (result, sink) {
          if (result is JNAPSuccess) {
            final deviceList = List.from(
              result.output['devices'],
            )
                .map((e) => LinksysDevice.fromMap(e))
                .where((device) => device.isAuthority == false)
                .toList()
                .forEach((element) {
              logger.d(
                  'XXXXX: check node: location:${element.getDeviceLocation()}, name: ${element.getDeviceName()}, sn: ${element.unit.serialNumber}');
            });
          }
        },
      ),
    );
  }
}
