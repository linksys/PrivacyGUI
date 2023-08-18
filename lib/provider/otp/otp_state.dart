import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';

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
    this.extras = const {},
  });

  OtpState.init()
      : step = OtpStep.init,
        methods = [],
        token = '',
        selectedMethod = null,
        function = OtpFunction.send,
        isLoading = false,
        extras = {};

  OtpState copyWith({
    OtpStep? step,
    List<CommunicationMethod>? methods,
    String? token,
    CommunicationMethod? selectedMethod,
    OtpFunction? function,
    bool? isLoading,
    Map<String, dynamic>? extras,
  }) {
    return OtpState(
      step: step ?? this.step,
      methods: methods ?? this.methods,
      token: token ?? this.token,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      function: function ?? this.function,
      isLoading: isLoading ?? this.isLoading,
      extras: extras ?? this.extras,
    );
  }

  final OtpStep step;
  final List<CommunicationMethod> methods;
  final String token;
  final CommunicationMethod? selectedMethod;
  final OtpFunction function;
  final bool isLoading;
  final Map<String, dynamic> extras;

  @override
  List<Object?> get props => [
        step,
        methods,
        token,
        selectedMethod,
        function,
        isLoading,
        extras,
      ];

  bool isSendFunction() => function == OtpFunction.send;
  bool isSettingFunction() => function == OtpFunction.setting;
  bool isSetting2svFunction() => function == OtpFunction.setting2sv;
}
