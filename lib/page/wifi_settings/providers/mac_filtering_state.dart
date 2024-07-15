// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

enum MacFilterMode {
  disabled,
  allow,
  deny,
  ;

  static MacFilterMode reslove(String value) => switch (value) {
        'Disabled' => MacFilterMode.disabled,
        'Allow' => MacFilterMode.allow,
        'Deny' => MacFilterMode.deny,
        _ => MacFilterMode.disabled,
      };
}

class MacFilteringState extends Equatable {
  final MacFilterMode mode;
  final List<String> macAddresses;
  final int maxMacAddresses;

  @override
  List<Object> get props => [mode, macAddresses, maxMacAddresses];

  const MacFilteringState({
    required this.mode,
    required this.macAddresses,
    required this.maxMacAddresses,
  });

  factory MacFilteringState.init() {
    return const MacFilteringState(
      mode: MacFilterMode.disabled,
      macAddresses: [],
      maxMacAddresses: 32,
    );
  }

  MacFilteringState copyWith({
    MacFilterMode? mode,
    List<String>? macAddresses,
    int? maxMacAddresses,
  }) {
    return MacFilteringState(
      mode: mode ?? this.mode,
      macAddresses: macAddresses ?? this.macAddresses,
      maxMacAddresses: maxMacAddresses ?? this.maxMacAddresses,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': mode.name,
      'macAddresses': macAddresses,
      'maxMacAddresses': maxMacAddresses,
    };
  }

  factory MacFilteringState.fromMap(Map<String, dynamic> map) {
    return MacFilteringState(
      mode: MacFilterMode.reslove(map['status']),
      macAddresses: List.from(map['macAddresses']),
      maxMacAddresses: map['maxMacAddresses'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory MacFilteringState.fromJson(String source) =>
      MacFilteringState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
