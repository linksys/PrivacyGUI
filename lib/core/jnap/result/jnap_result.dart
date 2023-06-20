import 'package:equatable/equatable.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/core/jnap/actions/better_action.dart';

abstract class JNAPResult extends Equatable {
  final String result;

  const JNAPResult({
    required this.result,
  });

  factory JNAPResult.fromJson(Map<String, dynamic> json) {
    if (json[keyJnapResult] == jnapResultOk) {
      return json.containsKey(keyJnapResponses)
          ? JNAPTransactionSuccess.fromJson(json)
          : JNAPSuccess.fromJson(json);
    }
    return JNAPError.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
    };
  }

  @override
  List<Object?> get props => [result];
}

class JNAPSuccess extends JNAPResult {
  final Map<String, dynamic> output;
  final List<String>? sideEffects;

  const JNAPSuccess({
    required super.result,
    this.output = const {},
    this.sideEffects,
  });

  factory JNAPSuccess.fromJson(Map<String, dynamic> json) {
    return JNAPSuccess(
      result: json[keyJnapResult],
      output: json[keyJnapOutput] ?? {},
      sideEffects: json.containsKey(keyJnapSideEffects)
          ? List.from(json[keyJnapSideEffects])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        keyJnapOutput: output,
        keyJnapSideEffects: sideEffects,
      });
  }

  @override
  List<Object?> get props => super.props..add(output);
}

class JNAPTransactionSuccess extends JNAPResult {
  final List<JNAPSuccess> responses;

  const JNAPTransactionSuccess({
    required super.result,
    required this.responses,
  });

  factory JNAPTransactionSuccess.fromJson(Map<String, dynamic> json) {
    return JNAPTransactionSuccess(
      result: json[keyJnapResult],
      responses: List.from(json[keyJnapResponses])
          .map((e) => JNAPSuccess.fromJson(e))
          .toList(),
    );
  }

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

class JNAPTransactionSuccessWrap extends JNAPResult {
  final Map<JNAPAction, JNAPResult> data;

  const JNAPTransactionSuccessWrap({
    required super.result,
    this.data = const {},
  });

  factory JNAPTransactionSuccessWrap.convert({
    required List<JNAPAction> actions,
    required JNAPTransactionSuccess transactionSuccess,
  }) {
    return JNAPTransactionSuccessWrap(
      result: transactionSuccess.result,
      data: Map.fromIterables(actions, transactionSuccess.responses),
    );
  }

  static JNAPSuccess? getResult(
      JNAPAction action, Map<JNAPAction, JNAPResult> results) {
    if (!results.containsKey(action)) {
      return null;
    }
    return results[action] as JNAPSuccess?;
  }

  @override
  List<Object?> get props => super.props..add(data);
}

class JNAPError extends JNAPResult {
  final String? error;

  const JNAPError({
    required super.result,
    this.error,
  });

  factory JNAPError.fromJson(Map<String, dynamic> json) {
    // Check if it's a transaction jnap
    if (json.containsKey(keyJnapResponses)) {
      final responses = json[keyJnapResponses] as List;
      // Get the first error result that occurs in the transaction
      for (final response in responses) {
        if (response[keyJnapResult] != jnapResultOk) {
          return JNAPError(
            result: response[keyJnapResult],
            error: response[keyJnapError],
          );
        }
      }
      return const JNAPError(
        result: jnapResultError,
        error: jnapResultError,
      );
    }
    // Otherwise, it's a general jnap
    return JNAPError(
      result: json[keyJnapResult],
      error: json[keyJnapError],
    );
  }

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
