
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';

import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(OtpState.init());

  void updateOtpMethods(List<OtpInfo> methods, OtpFunction function) {
    var selected = methods.length > 1 ? methods.firstWhere((element) => element.method == OtpMethod.sms) : methods[0];
    final step = (function == OtpFunction.send && methods.length == 1) ? OtpStep.inputOtp : OtpStep.chooseOtpMethod;
    emit(state.copyWith(step: step, methods:  methods, selectedMethod: selected, function: function));
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

  void updateToken(String token) {
    emit(state.copyWith(token: token));
  }

  void onInputOtp({OtpInfo? info}) {
    emit(state.copyWith(step: OtpStep.inputOtp, selectedMethod: info ?? state.selectedMethod));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void processBack() {
    if (state.step == OtpStep.inputOtp) {
      emit(state.copyWith(step: !state.isSendFunction() ? OtpStep.addPhone : OtpStep.chooseOtpMethod, selectedMethod: null));
    } else if (state.step == OtpStep.addPhone) {
      emit(state.copyWith(step: OtpStep.chooseOtpMethod, selectedMethod: null));
    }
  }
}