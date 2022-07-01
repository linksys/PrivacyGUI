
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';

import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(OtpState.init());

  void updateOtpMethods(List<OtpInfo> methods) {
    final selected = methods.length > 1 ? null : methods[0];
    final step = selected == null ? OtpStep.chooseOtpMethod : OtpStep.inputOtp;
    emit(state.copyWith(step: step, methods:  methods, selectedMethod: selected, token: ''));
  }

  void selectOtpMethod(OtpInfo method) {
    emit(state.copyWith(selectedMethod: method));
  }

  void updateToken(String token) {
    emit(state.copyWith(step: OtpStep.inputOtp, token: token));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void processBack() {
    if (state.step == OtpStep.inputOtp) {
      emit(state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null));
    }
  }
}