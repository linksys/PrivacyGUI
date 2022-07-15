import 'package:equatable/equatable.dart';

///   {
///     "method": "SMS",
///     "targetValue": "1234"
///   }
class MaskedMethod extends Equatable {
  const MaskedMethod({
    required this.method,
    required this.targetValue,
  });

  factory MaskedMethod.fromJson(Map<String, dynamic> json) {
    return MaskedMethod(
      method: json['method'],
      targetValue: json['targetValue'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'targetValue': targetValue,
    };
  }

  final String method;
  final String targetValue;


  @override
  List<Object?> get props =>
      [method, targetValue];
}
