// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class RouterPasswordState extends Equatable {
  final String adminPassword;
  final String hint;
  final bool isValid;
  final bool isDefault;
  final bool isSetByUser;
  final bool hasEdited;
  final String? error;
  final int? remainingErrorAttempts;

  @override
  List<Object?> get props => [
        adminPassword,
        hint,
        isValid,
        isDefault,
        isSetByUser,
        hasEdited,
        error,
        remainingErrorAttempts,
      ];

  const RouterPasswordState({
    required this.adminPassword,
    required this.hint,
    required this.isValid,
    required this.isDefault,
    required this.isSetByUser,
    required this.hasEdited,
    this.error,
    this.remainingErrorAttempts,
  });

  factory RouterPasswordState.init() {
    return const RouterPasswordState(
      adminPassword: '',
      hint: '',
      isValid: false,
      isDefault: true,
      isSetByUser: false,
      hasEdited: false,
      error: null,
      remainingErrorAttempts: null,
    );
  }

  RouterPasswordState copyWith({
    String? adminPassword,
    String? hint,
    bool? isValid,
    bool? isDefault,
    bool? isSetByUser,
    bool? hasEdited,
    String? error,
    int? remainingErrorAttempts,
  }) {
    return RouterPasswordState(
      adminPassword: adminPassword ?? this.adminPassword,
      hint: hint ?? this.hint,
      isValid: isValid ?? this.isValid,
      isDefault: isDefault ?? this.isDefault,
      isSetByUser: isSetByUser ?? this.isSetByUser,
      hasEdited: hasEdited ?? this.hasEdited,
      error: error ?? this.error,
      remainingErrorAttempts:
          remainingErrorAttempts ?? this.remainingErrorAttempts,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'adminPassword': adminPassword,
      'hint': hint,
      'isValid': isValid,
      'isDefault': isDefault,
      'isSetByUser': isSetByUser,
      'hasEdited': hasEdited,
      'error': error,
      'remainingErrorAttempts': remainingErrorAttempts,
    };
  }

  factory RouterPasswordState.fromMap(Map<String, dynamic> map) {
    return RouterPasswordState(
      adminPassword: map['adminPassword'] as String,
      hint: map['hint'] as String,
      isValid: map['isValid'] as bool,
      isDefault: map['isDefault'] as bool,
      isSetByUser: map['isSetByUser'] as bool,
      hasEdited: map['hasEdited'] as bool,
      error: map['error'] != null ? map['error'] as String : null,
      remainingErrorAttempts: map['remainingErrorAttempts'] != null ? map['remainingErrorAttempts'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterPasswordState.fromJson(String source) => RouterPasswordState.fromMap(json.decode(source) as Map<String, dynamic>);
}
