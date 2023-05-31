// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';

class BaseResponse<T> {
  int code;
  String message;
  T? data;

  BaseResponse({required this.code, required this.message, required this.data});

  factory BaseResponse.fromJson(
      Map<String, dynamic> json, Function(Map<String, dynamic>) builder) {
    return BaseResponse(
        code: json['status'],
        message: json['message'],
        data: builder(json['data']));
  }
}

class ErrorResponse extends Equatable {
  const ErrorResponse(
      {required this.status,
      required this.code,
      this.errorMessage,
      this.parameters});

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

class ErrorMfaRequired extends Equatable {
  final String code;
  final String errorMessage;
  final String verificationToken;
  const ErrorMfaRequired({
    required this.code,
    required this.errorMessage,
    required this.verificationToken,
  });

  ErrorMfaRequired copyWith({
    String? code,
    String? errorMessage,
    String? verificationToken,
  }) {
    return ErrorMfaRequired(
      code: code ?? this.code,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'errorMessage': errorMessage,
      'verificationToken': verificationToken,
    };
  }

  factory ErrorMfaRequired.fromMap(Map<String, dynamic> map) {
    return ErrorMfaRequired(
      code: map['code'] as String,
      errorMessage: map['errorMessage'] as String,
      verificationToken: map['verificationToken'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorMfaRequired.fromJson(String source) =>
      ErrorMfaRequired.fromMap(json.decode(source) as Map<String, dynamic>);

  factory ErrorMfaRequired.fromResponse(ErrorResponse response) {
    String token = '';
    try {
      token = response.parameters?[0]['parameter']['value'];
    } catch (_) {}
    return ErrorMfaRequired(
      code: response.code,
      errorMessage: response.errorMessage ?? '',
      verificationToken: token,
    );
  }
  @override
  String toString() =>
      'ErrorMfaRequired(code: $code, errorMessage: $errorMessage, verificationToken: $verificationToken)';

  @override
  bool operator ==(covariant ErrorMfaRequired other) {
    if (identical(this, other)) return true;

    return other.code == code &&
        other.errorMessage == errorMessage &&
        other.verificationToken == verificationToken;
  }

  @override
  int get hashCode =>
      code.hashCode ^ errorMessage.hashCode ^ verificationToken.hashCode;

  @override
  List<Object> get props => [code, errorMessage, verificationToken];
}
