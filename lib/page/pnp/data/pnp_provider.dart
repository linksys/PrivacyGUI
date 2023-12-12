import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/page/pnp/data/pnp_state.dart';
import 'package:linksys_app/page/pnp/data/pnp_step_state.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';

final pnpProvider =
    NotifierProvider<PnpNotifier, PnpState>(() => PnpNotifier());

class PnpNotifier extends Notifier<PnpState> {
  @override
  PnpState build() => const PnpState(
        deviceInfo: null,
        password: '',
      );

  Future fetchDeviceInfo() async {
    final deviceInfo = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getDeviceInfo,
          cacheLevel: CacheLevel.noCache,
          type: CommandType.local,
          fetchRemote: true,
        )
        .then((result) => NodeDeviceInfo.fromJson(result.output));
    state = state.copyWith(deviceInfo: deviceInfo);
  }

  Future checkAdminPassword(String password) async {
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
    stepStateData[index] = target.copyWith(data: data);
    state = state.copyWith(stepStateList: stepStateData);
  }

  void setStepError(int index, {Object? error}) {
    final stepStateData = Map<int, PnpStepState>.from(state.stepStateList);
    final target = stepStateData[index] ??
        const PnpStepState(status: StepViewStatus.loading, data: {});
    stepStateData[index] = target.copyWith(error: error);
    state = state.copyWith(stepStateList: stepStateData);
  }
}
