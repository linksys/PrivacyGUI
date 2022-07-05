import 'package:equatable/equatable.dart';
import 'package:moab_poc/bloc/auth/state.dart';

enum OtpStep { init, chooseOtpMethod, inputOtp, addPhone }

class OtpState extends Equatable {
  const OtpState({
    required this.step,
    required this.methods,
    required this.token,
    required this.selectedMethod,
    required this.isSettingLoginType,

    required this.isLoading,
  });

  OtpState.init()
      : step = OtpStep.init,
        methods = [],
        token = '',
        selectedMethod = null,
        isSettingLoginType = false,
        isLoading = false;

  OtpState copyWith({
    OtpStep? step,
    List<OtpInfo>? methods,
    String? token,
    OtpInfo? selectedMethod,
    bool? isSettingLoginType,
    bool? isLoading,
  }) {
    return OtpState(
      step: step ?? this.step,
      methods: methods ?? this.methods,
      token: token ?? this.token,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isSettingLoginType: isSettingLoginType ?? this.isSettingLoginType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  final OtpStep step;
  final List<OtpInfo> methods;
  final String token;
  final OtpInfo? selectedMethod;
  final bool isSettingLoginType;
  final bool isLoading;

  @override
  List<Object?> get props =>
      [step, methods, token, selectedMethod, isSettingLoginType, isLoading];
}
