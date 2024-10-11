import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';

final addWiredNodesProvider =
    NotifierProvider.autoDispose<AddWiredNodesNotifier, AddWiredNodesState>(
        () => AddWiredNodesNotifier());

class AddWiredNodesNotifier extends AutoDisposeNotifier<AddWiredNodesState> {
  StreamSubscription? _streamSubscription;

  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  Future<void> setAutoOnboardingSettings(bool enabled) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.setWiredAutoOnboardingSettings,
            data: {
              'isAutoOnboardingEnabled': true,
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

  Future startAutoOnboarding() async {
    ref.read(pollingProvider.notifier).stopPolling();
    await setAutoOnboardingSettings(true);
    final backhaulList = ref.read(deviceManagerProvider).backhaulInfoData;
    state = state.copyWith(
      isLoading: true,
      nodesSnapshot: backhaulList,
    );
    _checkBackhaulChanges();
  }

  void _checkBackhaulChanges() {
    _streamSubscription?.cancel();
    _streamSubscription = pollBackhaulInfo().listen((result) {
      if (result is! JNAPSuccess) {
        return;
      }
      state = state.copyWith(onboardingProceed: true);
      final backhaulInfoList = List.from(
        result.output['backhaulDevices'] ?? [],
      ).map((e) => BackHaulInfoData.fromMap(e)).toList();
      final foundCounting = backhaulInfoList.fold<int>(0, (value, infoData) {
        final dateFormat = DateFormat("yyyy-MM-ddThh:mm:ssZ");
        return (state.backhaulSnapshot?.any((e) =>
                    e.deviceUUID == infoData.deviceUUID &&
                    (dateFormat.tryParse(e.timestamp)?.millisecondsSinceEpoch ??
                            0) <
                        (dateFormat
                                .tryParse(infoData.timestamp)
                                ?.millisecondsSinceEpoch ??
                            0)) ==
                true)
            ? value
            : value + 1;
      });
      logger.i('[AddWiredNodes]: Found $foundCounting new nodes');
    }, onDone: () {
      stopCheckingBackhaul();
    });

    // await for (final result in pollBackhaulInfo()) {
    //   if (result is! JNAPSuccess) {
    //     return;
    //   }
    //   state = state.copyWith(onboardingProceed: true);
    //   final backhaulInfoList = List.from(
    //     result.output['backhaulDevices'] ?? [],
    //   ).map((e) => BackHaulInfoData.fromMap(e)).toList();
    //   final foundCounting = backhaulInfoList.fold<int>(0, (value, infoData) {
    //     final dateFormat = DateFormat("yyyy-MM-ddThh:mm:ssZ");
    //     return (state.backhaulSnapshot?.any((e) =>
    //                 e.deviceUUID == infoData.deviceUUID &&
    //                 (dateFormat.tryParse(e.timestamp)?.millisecondsSinceEpoch ??
    //                         0) <
    //                     (dateFormat
    //                             .tryParse(infoData.timestamp)
    //                             ?.millisecondsSinceEpoch ??
    //                         0)) ==
    //             true)
    //         ? value
    //         : value + 1;
    //   });
    //   logger.i('[AddWiredNodes]: Found $foundCounting new nodes');
    // }
  }

  Stream pollBackhaulInfo() {
    final repo = ref.read(routerRepositoryProvider);

    return repo.scheduledCommand(
      action: JNAPAction.getBackhaulInfo,
      auth: true,
      firstDelayInMilliSec: 1 * 1000,
      retryDelayInMilliSec: 10 * 1000,
      maxRetry: 30,
      // condition: (result) {
      //   if (result is! JNAPSuccess) {
      //     return false;
      //   }
      //   state = state.copyWith(onboardingProceed: true);
      //   final backhaulInfoList = List.from(
      //     result.output['backhaulDevices'] ?? [],
      //   ).map((e) => BackHaulInfoData.fromMap(e)).toList();
      //   final foundCounting = backhaulInfoList.fold<int>(0, (value, infoData) {
      //     return (state.nodesSnapshot
      //                 ?.any((e) => e.deviceUUID == infoData.deviceUUID) ==
      //             true)
      //         ? value
      //         : value + 1;
      //   });
      //   logger.i('[AddWiredNodes]: Found $foundCounting new nodes');
      //   return false;
      // },
    );
  }

  void stopCheckingBackhaul() {
    _streamSubscription?.cancel();
    state = state.copyWith(
      isLoading: false,
    );
  }

  Future stopAutoOnboarding() async {
    await setAutoOnboardingSettings(false);
  }
}
