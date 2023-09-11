import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';

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

  Future<void> fetchMfaMethods({required String? username}) async {
    final repository = ref.read(cloudRepositoryProvider);
    final auth = ref.read(authProvider).value;
    final methods = auth?.loginType == LoginType.remote
        ? await repository.getMfaMethod()
        : await repository.getMfaMaskedMethods(username: username ?? '');
    state = state.copyWith(step: OtpStep.init, methods: methods);
  }

  Future<void> prepareAddMfa() async {
    final repository = ref.read(cloudRepositoryProvider);
    final token = await repository.prepareAddMfa();
    state = state.copyWith(step: OtpStep.init, token: token);
  }

  void updateOtpMethods(
    List<CommunicationMethod>? methods,
  ) {
    final targetMethods = methods ?? state.methods;
    var selected = targetMethods.length > 1
        ? targetMethods.firstWhere((element) =>
            element.method == CommunicationMethodType.sms.name.toUpperCase())
        : targetMethods[0];
    final step = (targetMethods.length == 1)
        ? OtpStep.inputOtp
        : OtpStep.chooseOtpMethod;
    state = state.copyWith(
      step: step,
      methods: targetMethods,
      selectedMethod: selected,
    );
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
      state =
          state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null);
    } else if (state.step == OtpStep.addPhone) {
      state =
          state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null);
    }
  }

  Future<void> mfaChallenge(
      {required CommunicationMethod method, required String token}) async {
    final repository = ref.read(cloudRepositoryProvider);
    return await repository.mfaChallenge(
      verificationToken: token.isEmpty ? state.token : token,
      method: method.method,
    );
  }

  Future mfaVerify({required String code, required String token}) async {
    final repository = ref.read(cloudRepositoryProvider);
    final auth = ref.read(authProvider).value;
    if (auth?.loginType == LoginType.remote) {
      final result = await repository.mfaValidate(
        otpCode: code,
        verificationToken: token,
      );
      state = state.copyWith(step: OtpStep.finish, extras: result.toJson());
    } else {
      final result = await repository.oAuthMfaValidate(
        otpCode: code,
        verificationToken: token,
      );
      state = state.copyWith(step: OtpStep.finish, extras: result.toJson());
    }
  }
}
