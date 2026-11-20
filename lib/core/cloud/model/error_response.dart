// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:equatable/equatable.dart';

class ErrorResponse extends Equatable {
  const ErrorResponse(
      {required this.status,
      required this.code,
      this.errorMessage,
      this.parameters});

  factory ErrorResponse.convert(Object error) {
    if (error is TimeoutException) {
      return const ErrorResponse(status: 1000, code: 'REQUEST_TIMEOUT');
    }
    return const ErrorResponse(status: -1, code: 'UNKNOWN_ERROR');
  }
  factory ErrorResponse.fromJson(int status, Map<String, dynamic> json) {
    final errorsJson = json['errors'];

    if (errorsJson != null) {
      final errorJson = List.from(errorsJson)[0]['error'];
      final String code = errorJson['code'];
      final String? errorMessage = errorJson['message'];
      final List<Map<String, dynamic>>? parameters =
          !errorJson.containsKey('parameters')
              ? null
              : List.from(errorJson['parameters']);
      return ErrorResponse(
          status: status,
          code: code,
          errorMessage: errorMessage,
          parameters: parameters);
    } else if (json.containsKey('code')) {
      final String code = json['code'];
      final String? errorMessage = json['errorMessage'];
      return ErrorResponse(
        status: status,
        code: code,
        errorMessage: errorMessage,
      );
    } else {
      final String code = json['error'];
      final String? errorMessage = json['error_description'];
      final List<Map<String, dynamic>>? parameters =
          !json.containsKey('parameters')
              ? null
              : List.from(json['parameters']);
      return ErrorResponse(
          status: status,
          code: code,
          errorMessage: errorMessage,
          parameters: parameters);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {'code': code};
    if (errorMessage != null) {
      result.addAll({'errorMessage': errorMessage!});
    }
    if (parameters != null) {
      result.addAll({'parameters': parameters!});
    }
    return result;
  }

  final int status;
  final String code;
  final String? errorMessage;
  final List<Map<String, dynamic>>? parameters;

  @override
  List<Object?> get props => [
        status,
        code,
        errorMessage,
        parameters,
      ];
}
