import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';

import '../../repository/linksys_cloud_repository.dart';
import '../../repository/model/cloud_session_model.dart';
import 'otp_state.dart';

enum CommunicationMethodType {
  sms,
  email;
}

class OtpCubit extends Cubit<OtpState> {
  OtpCubit({
    required LinksysCloudRepository repository,
  })  : _repository = repository,
        super(OtpState.init());

  final LinksysCloudRepository _repository;
  void init() {
    emit(OtpState.init());
  }

  Future<void> fetchMaskedMethods({required String username}) async {
    final methods = await _repository.getMfaMaskedMethods(username: username);
    emit(state.copyWith(methods: methods));
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
    emit(state.copyWith(
        step: step,
        methods: targetMethods,
        selectedMethod: selected,
        function: function));
  }

  void selectOtpMethod(CommunicationMethod method) {
    emit(state.copyWith(selectedMethod: method));
  }

  void addPhone() {
    emit(state.copyWith(step: OtpStep.addPhone));
  }

  void finish() {
    emit(state.copyWith(step: OtpStep.finish));
  }

  void updateToken(String token) {
    emit(state.copyWith(token: token));
  }

  void onInputOtp({CommunicationMethod? method}) {
    emit(state.copyWith(
        step: OtpStep.inputOtp,
        selectedMethod: method ?? state.selectedMethod));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void processBack() {
    if (state.step == OtpStep.inputOtp) {
      emit(state.copyWith(
          step: !state.isSendFunction()
              ? OtpStep.addPhone
              : OtpStep.chooseOtpMethod,
          selectedMethod: null));
    } else if (state.step == OtpStep.addPhone) {
      emit(state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null));
    }
  }

  Future<void> authChallenge(
      {required CommunicationMethod method, required String token}) async {
    BaseAuthChallenge challenge;
    final id = method.id;
    if (id != null) {
      challenge = AuthChallengeMethodId(token: token, commMethodId: id);
    } else {
      challenge = AuthChallengeMethod(
        token: token,
        method: method.method,
        target: method.target,
      );
    }
    return await _repository.mfaChallenge(
      verificationToken: token,
      method: method.method,
    );
  }

  Future<SessionToken> authChallengeVerify(
      {required String code, required String token}) async {
    return await _repository.mfaValidate(
      otpCode: code,
      verificationToken: token,
    );
  }
}
