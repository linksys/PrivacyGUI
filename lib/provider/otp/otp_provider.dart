import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_moab/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_moab/core/cloud/linksys_cloud_repository.dart';

import 'otp_state.dart';

enum CommunicationMethodType {
  sms,
  email;
}

final otpProvider = NotifierProvider<OtpNotifier, OtpState>(
  () => OtpNotifier(),
);

class OtpNotifier extends Notifier<OtpState> {
  OtpNotifier();

  @override
  OtpState build() => OtpState.init();

  void init() {
    state = OtpState.init();
  }

  Future<void> fetchMaskedMethods({required String username}) async {
    final repository = ref.read(cloudRepositoryProvider);
    final methods = await repository.getMfaMaskedMethods(username: username);
    state = state.copyWith(step: OtpStep.init, methods: methods);
  }

  void updateOtpMethods(
      List<CommunicationMethod>? methods, OtpFunction function) {
    final targetMethods = methods ?? state.methods;
    var selected = targetMethods.length > 1
        ? targetMethods.firstWhere((element) =>
            element.method == CommunicationMethodType.sms.name.toUpperCase())
        : targetMethods[0];
    final step = (function == OtpFunction.send && targetMethods.length == 1)
        ? OtpStep.inputOtp
        : OtpStep.chooseOtpMethod;
    state = state.copyWith(
        step: step,
        methods: targetMethods,
        selectedMethod: selected,
        function: function);
  }

  void selectOtpMethod(CommunicationMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  void addPhone() {
    state = state.copyWith(step: OtpStep.addPhone);
  }

  void finish() {
    state = state.copyWith(step: OtpStep.finish);
  }

  void updateToken(String token) {
    state = state.copyWith(token: token);
  }

  void onInputOtp({CommunicationMethod? method}) {
    state = state.copyWith(step: OtpStep.inputOtp, selectedMethod: method);
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void processBack() {
    if (state.step == OtpStep.inputOtp) {
      state = state.copyWith(
          step: !state.isSendFunction()
              ? OtpStep.addPhone
              : OtpStep.chooseOtpMethod,
          selectedMethod: null);
    } else if (state.step == OtpStep.addPhone) {
      state =
          state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null);
    }
  }

  Future<void> authChallenge(
      {required CommunicationMethod method, required String token}) async {
    final repository = ref.read(cloudRepositoryProvider);
    return await repository.mfaChallenge(
      verificationToken: token,
      method: method.method,
    );
  }

  Future<SessionToken> authChallengeVerify(
      {required String code, required String token}) async {
    final repository = ref.read(cloudRepositoryProvider);
    final result = await repository.mfaValidate(
      otpCode: code,
      verificationToken: token,
    );
    state = state.copyWith(step: OtpStep.finish, extras: result.toJson());
    return result;
  }
}
