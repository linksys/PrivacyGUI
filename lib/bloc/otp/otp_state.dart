import 'package:equatable/equatable.dart';
import 'package:linksys_moab/bloc/auth/state.dart';

enum OtpStep { init, chooseOtpMethod, inputOtp, addPhone, finish }

// TODO: Need a more understandable name
enum OtpFunction { send, setting, setting2sv, add }

class OtpState extends Equatable {
  const OtpState({
    required this.step,
    required this.methods,
    required this.token,
    required this.selectedMethod,
    required this.function,
    required this.isLoading,
  });

  OtpState.init()
      : step = OtpStep.init,
        methods = [],
        token = '',
        selectedMethod = null,
        function = OtpFunction.send,
        isLoading = false;

  OtpState copyWith({
    OtpStep? step,
    List<OtpInfo>? methods,
    String? token,
    OtpInfo? selectedMethod,
    OtpFunction? function,
    bool? isLoading,
  }) {
    return OtpState(
      step: step ?? this.step,
      methods: methods ?? this.methods,
      token: token ?? this.token,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      function: function ?? this.function,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  final OtpStep step;
  final List<OtpInfo> methods;
  final String token;
  final OtpInfo? selectedMethod;
  final OtpFunction function;
  final bool isLoading;

  @override
  List<Object?> get props => [
        step,
        methods,
        token,
        selectedMethod,
        function,
        isLoading,
      ];

  bool isSendFunction() => function == OtpFunction.send;
  bool isSettingFunction() => function == OtpFunction.setting;
  bool isSetting2svFunction() => function == OtpFunction.setting2sv;
}
