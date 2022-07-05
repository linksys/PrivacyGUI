
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';

import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(OtpState.init());

  void updateOtpMethods(List<OtpInfo> methods, isSettingLoginType) {
    var selected = methods.length > 1 ? null : isSettingLoginType ? null : methods[0];
    final step = selected == null ? OtpStep.chooseOtpMethod : OtpStep.inputOtp;
    emit(state.copyWith(step: step, methods:  methods, selectedMethod: selected, token: '', isSettingLoginType: isSettingLoginType));
  }

  void selectOtpMethod(OtpInfo method) {
    emit(state.copyWith(selectedMethod: method));
  }

  void addPhone() {
    emit(state.copyWith(step: OtpStep.addPhone));
  }

  void finish() {
    emit(state.copyWith(step: OtpStep.finish));
  }

  void updateToken(String token, {OtpInfo? info}) {
    emit(state.copyWith(step: OtpStep.inputOtp, token: token, selectedMethod: info ?? state.selectedMethod));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void processBack() {
    if (state.step == OtpStep.inputOtp) {
      emit(state.copyWith(step: state.isSettingLoginType ? OtpStep.addPhone : OtpStep.chooseOtpMethod, selectedMethod: null));
    } else if (state.step == OtpStep.addPhone) {
      emit(state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null));

    }
  }
}