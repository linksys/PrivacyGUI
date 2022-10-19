import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/repository/authenticate/otp_repository.dart';

import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit({ required OtpRepository otpRepository}) : _otpRepository = otpRepository, super(OtpState.init());

  final OtpRepository _otpRepository;

  void init() {
    emit(OtpState.init());
  }
  void updateOtpMethods(
      List<CommunicationMethod> methods, OtpFunction function) {
    var selected = methods.length > 1
        ? methods.firstWhere((element) =>
            element.method == CommunicationMethodType.sms.name.toUpperCase())
        : methods[0];
    final step = (function == OtpFunction.send && methods.length == 1)
        ? OtpStep.inputOtp
        : OtpStep.chooseOtpMethod;
    emit(state.copyWith(
        step: step,
        methods: methods,
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
        target: method.targetValue,
      );
    }
    return await _otpRepository.authChallenge(challenge).onError((error, stackTrace) => null);
  }

  Future<void> authChallengeVerify(
      {required String code, required String token}) async {
    return await _otpRepository.authChallengeVerify(token, code);
  }

  Future<void> authChallengeVerifyAccept(String code, String token) async {
    return await _otpRepository.authChallengeVerifyAccept(token, code);
  }
}
