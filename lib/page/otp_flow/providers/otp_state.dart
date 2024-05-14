import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';

enum OtpStep { init, chooseOtpMethod, inputOtp, addPhone, finish }

class OtpState extends Equatable {
  const OtpState({
    required this.step,
    required this.methods,
    required this.token,
    required this.selectedMethod,
    required this.isLoading,
    this.extras = const {},
  });

  OtpState.init()
      : step = OtpStep.init,
        methods = [],
        token = '',
        selectedMethod = null,
        isLoading = false,
        extras = {};

  OtpState copyWith({
    OtpStep? step,
    List<CommunicationMethod>? methods,
    String? token,
    CommunicationMethod? selectedMethod,
    bool? isLoading,
    Map<String, dynamic>? extras,
  }) {
    return OtpState(
      step: step ?? this.step,
      methods: methods ?? this.methods,
      token: token ?? this.token,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isLoading: isLoading ?? this.isLoading,
      extras: extras ?? this.extras,
    );
  }

  final OtpStep step;
  final List<CommunicationMethod> methods;
  final String token;
  final CommunicationMethod? selectedMethod;
  final bool isLoading;
  final Map<String, dynamic> extras;

  @override
  List<Object?> get props => [
        step,
        methods,
        token,
        selectedMethod,
        isLoading,
        extras,
      ];
}
