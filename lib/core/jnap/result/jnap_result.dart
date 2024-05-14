import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

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

class JNAPSuccess extends JNAPResult with SideEffectGetter {
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
      })
      ..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => super.props
    ..add(output)
    ..add(sideEffects);
}

class JNAPTransactionSuccess extends JNAPResult with SideEffectGetter {
  final List<JNAPSuccess> responses;
  final List<String>? sideEffects;

  const JNAPTransactionSuccess({
    required super.result,
    required this.responses,
    this.sideEffects,
  });

  factory JNAPTransactionSuccess.fromJson(Map<String, dynamic> json) {
    return JNAPTransactionSuccess(
      result: json[keyJnapResult],
      responses: List.from(json[keyJnapResponses])
          .map((e) => JNAPSuccess.fromJson(e))
          .toList(),
      sideEffects: json.containsKey(keyJnapSideEffects)
          ? List.from(json[keyJnapSideEffects])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      keyJnapResult: result,
      keyJnapResponses: responses,
      keyJnapSideEffects: sideEffects
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => super.props
    ..add(responses)
    ..add(sideEffects);
}

class JNAPTransactionSuccessWrap extends JNAPResult with SideEffectGetter {
  final List<String> sideEffects;
  final List<MapEntry<JNAPAction, JNAPResult>> data;

  const JNAPTransactionSuccessWrap({
    required super.result,
    this.data = const [],
    this.sideEffects = const [],
  });

  factory JNAPTransactionSuccessWrap.convert({
    required List<JNAPAction> actions,
    required JNAPTransactionSuccess transactionSuccess,
  }) {
    return JNAPTransactionSuccessWrap(
      result: transactionSuccess.result,
      sideEffects: transactionSuccess.getSideEffects() ?? [],
      data: actions
          .mapIndexed((index, action) =>
              MapEntry(action, transactionSuccess.responses[index]))
          .toList(),
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
            error:
                response[keyJnapError] ?? jsonEncode(response[keyJnapOutput]),
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
      error: json[keyJnapError] ?? jsonEncode(json[keyJnapOutput]),
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

mixin SideEffectGetter {
  List<String>? getSideEffects() {
    if (this is JNAPSuccess) {
      return (this as JNAPSuccess).sideEffects;
    } else if (this is JNAPTransactionSuccess) {
      return (this as JNAPTransactionSuccess).sideEffects;
    } else if (this is JNAPTransactionSuccessWrap) {
      final trans = this as JNAPTransactionSuccessWrap;
      // return trans.data
      //     .map((e) => e.value as JNAPSuccess?)
      //     .whereType<JNAPSuccess>()
      //     .fold<List<String>>([], (previousValue, element) {
      //   if (element.sideEffects != null) {
      //     previousValue.addAll(element.sideEffects!);
      //   }
      //   return previousValue;
      // }).toList();
      return trans.sideEffects;
    } else {
      return null;
    }
  }
}
