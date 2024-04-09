import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/page/pnp/data/pnp_error.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/page/pnp/data/pnp_state.dart';
import 'package:linksys_app/page/pnp/data/pnp_step_state.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/providers/connectivity/mixin.dart';

final pnpProvider =
    NotifierProvider<BasePnpNotifier, PnpState>(() => MockPnpNotifier());

abstract class BasePnpNotifier extends Notifier<PnpState> {
  @override
  PnpState build() => const PnpState(
        deviceInfo: null,
        password: '',
      );

  ///
  PnpStepState getStepState(int index) {
    return state.stepStateList[index] ??
        const PnpStepState(status: StepViewStatus.data, data: {});
  }

  void setStepState(int index, PnpStepState stepState) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    stepStateData[index] = stepState;
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepStatus(int index, {required StepViewStatus status}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(status: status);
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepData(int index, {required Map<String, dynamic> data}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(
        data: Map.fromEntries(target.data.entries)..addAll(data));
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepError(int index, {Object? error}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(error: error);
    state = state.copyWith(stepStateList: stepStateData);
  }

  // abstract functions

  Future fetchDeviceInfo();
  Future checkAdminPassword(String? password);
  Future checkInternetConnection();
  Future<bool> pnpCheck();
  Future<bool> factoryResetCheck();
}

class MockPnpNotifier extends BasePnpNotifier {
  @override
  Future checkAdminPassword(String? password) {
    if (password == 'Linksys123!') {
      return Future.delayed(const Duration(seconds: 1));
    }
    return Future.delayed(const Duration(seconds: 3))
        .then((value) => throw ErrorInvalidAdminPassword());
  }

  @override
  Future checkInternetConnection() {
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future fetchDeviceInfo() {
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> pnpCheck() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => false);
  }

  @override
  Future<bool> factoryResetCheck() {
    return Future.delayed(const Duration(seconds: 1)).then((value) => false);
  }
}

class PnpNotifier extends BasePnpNotifier with AvailabilityChecker {
  @override
  Future fetchDeviceInfo() async {
    final deviceInfo = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getDeviceInfo,
          type: CommandType.local,
          fetchRemote: true,
        )
        .then((result) => NodeDeviceInfo.fromJson(result.output));
    // Build/Update better actions
    buildBetterActions(deviceInfo.services);
    ref.read(routerRepositoryProvider).send(JNAPAction.getDeviceMode);
    state = state.copyWith(deviceInfo: deviceInfo);
  }

  @override
  Future checkAdminPassword(String? password) async {
    final response = await ref.read(routerRepositoryProvider).send(
      JNAPAction.checkAdminPassword,
      cacheLevel: CacheLevel.noCache,
      type: CommandType.local,
      fetchRemote: true,
      data: {
        'adminPassword': password,
      },
    );
    if (response.result == jnapResultOk) {
      state = state.copyWith(password: password);
    } else {
      throw response;
    }
  }

  /// check internet connection within 30 seconds
  @override
  Future checkInternetConnection() {
    final repo = ref.read(routerRepositoryProvider);
    final isConfigured = repo
        .send(JNAPAction.getDeviceMode, fetchRemote: true)
        .then((value) =>
            (value.output['mode'] ?? 'Unconfigured') == 'Unconfigured');
    // testConnection()
    return Future.delayed(const Duration(seconds: 3));
  }

  @override
  Future<bool> pnpCheck() async {
    final isSupportedSetup11 = isServiceSupport(JNAPService.setup11);
    if (!isSupportedSetup11) {
      return false;
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = repo.send(JNAPAction.getAutoConfigurationSettings).then(
        (data) =>
            data.output['isAutoConfigurationSupported'] ||
            data.output['userAcknowledgedAutoConfiguration']);
    return result;
  }

  @override
  Future<bool> factoryResetCheck() {
    final transaction = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.isAdminPasswordDefault, {}),
      const MapEntry(JNAPAction.isAdminPasswordSetByUser, {}),
    ]);
    final repo = ref.read(routerRepositoryProvider);
    return repo.transaction(transaction, fetchRemote: true).then((response) {
      bool isAdminPasswordDefault = (response.data
                  .firstWhereOrNull((element) =>
                      element.key == JNAPAction.isAdminPasswordDefault)
                  ?.value as JNAPSuccess?)
              ?.output['isAdminPasswordDefault'] ??
          false;
      bool isAdminPasswordSetByUser = (response.data
                  .firstWhereOrNull((element) =>
                      element.key == JNAPAction.isAdminPasswordSetByUser)
                  ?.value as JNAPSuccess?)
              ?.output['isAdminPasswordSetByUser'] ??
          true;

      return !isAdminPasswordDefault || isAdminPasswordSetByUser;
    });
  }
}
