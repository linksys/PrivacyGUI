import 'package:equatable/equatable.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/result/fcn_result.dart';

abstract class JNAPResult extends Equatable {
  const JNAPResult({required this.result});

  final String result;

  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
    };
  }

  factory JNAPResult.fromJson(Map<String, dynamic> json) {
    if (json[keyJnapResult] == jnapResultOk) {
      return JNAPSuccess.fromJson(json);
    } else {
      return JNAPError.fromJson(json);
    }
  }

  @override
  List<Object?> get props => [result];
}

class JNAPSuccess extends JNAPResult {
  const JNAPSuccess({
    required super.result,
    this.output = const {},
    this.sideEffects,
  });

  factory JNAPSuccess.fromJson(Map<String, dynamic> json) {
    return json.containsKey(keyJnapResponses)
        ? JNAPTransactionSuccess.fromJson(json)
        : JNAPSuccess(
            result: json[keyJnapResult],
            output: json[keyJnapOutput] ?? {},
            sideEffects: json[keyJnapSideEffects] != null
                ? List.from(json[keyJnapSideEffects])
                : null,
          );
  }

  final Map<String, dynamic> output;
  final List<String>? sideEffects;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        keyJnapOutput: output,
        keyJnapSideEffects: sideEffects,
      });
  }

  FCNResult toFCNResult() {
    if (!output.containsKey('status') || !output.containsKey('response')) {
      // TODO #ERRORHANDLING
      // Not a FCN result
    }
    return FCNResult.fromJson(output);
  }

  @override
  List<Object?> get props => super.props..add(output);
}

class JNAPTransactionSuccess extends JNAPSuccess {
  const JNAPTransactionSuccess({
    required super.result,
    required this.responses,
  });

  factory JNAPTransactionSuccess.fromJson(Map<String, dynamic> json) {
    return JNAPTransactionSuccess(
      result: json[keyJnapResult],
      responses: List.from(json[keyJnapResponses])
          .map((e) => JNAPResult.fromJson(e))
          .toList(),
    );
  }

  final List<JNAPResult> responses;

  @override
  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
      keyJnapResponses: responses,
    };
  }

  @override
  List<Object?> get props => super.props..add(responses);
}

// TODO check Authenticate error
class JNAPError extends JNAPResult {
  const JNAPError({
    required super.result,
    this.error,
  });

  factory JNAPError.fromJson(Map<String, dynamic> json) {
    return JNAPError(
      result: json[keyJnapResult],
      error: json[keyJnapError],
    );
  }

  final String? error;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        keyJnapError: error,
      });
  }

  @override
  List<Object?> get props => super.props..add(error);
}
