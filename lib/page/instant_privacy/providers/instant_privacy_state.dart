// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

enum MacFilterMode {
  disabled,
  allow,
  deny,
  ;

  static MacFilterMode reslove(String value) => switch (value.toLowerCase()) {
        'disabled' => MacFilterMode.disabled,
        'allow' => MacFilterMode.allow,
        'deny' => MacFilterMode.deny,
        _ => MacFilterMode.disabled,
      };
}

class InstantPrivacyState extends Equatable {
  final MacFilterMode mode;
  final List<String> macAddresses;
  final List<String> denyMacAddresses;
  final int maxMacAddresses;
  final List<String> bssids;
  final String? myMac;

  @override
  List<Object?> get props => [
        mode,
        macAddresses,
        denyMacAddresses,
        maxMacAddresses,
        bssids,
        myMac,
      ];

  const InstantPrivacyState({
    required this.mode,
    required this.macAddresses,
    required this.denyMacAddresses,
    required this.maxMacAddresses,
    this.bssids = const [],
    this.myMac,
  });

  factory InstantPrivacyState.init() {
    return const InstantPrivacyState(
      mode: MacFilterMode.disabled,
      macAddresses: [],
      denyMacAddresses: [],
      maxMacAddresses: 32,
    );
  }

  InstantPrivacyState copyWith({
    MacFilterMode? mode,
    List<String>? macAddresses,
    List<String>? denyMacAddresses,
    int? maxMacAddresses,
    List<String>? bssids,
    String? myMac,
  }) {
    return InstantPrivacyState(
      mode: mode ?? this.mode,
      macAddresses: macAddresses ?? this.macAddresses,
      denyMacAddresses: denyMacAddresses ?? this.denyMacAddresses,
      maxMacAddresses: maxMacAddresses ?? this.maxMacAddresses,
      bssids: bssids ?? this.bssids,
      myMac: myMac ?? this.myMac,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': mode.name,
      'macAddresses': macAddresses,
      'denyMacAddresses': denyMacAddresses,
      'maxMacAddresses': maxMacAddresses,
      'bssids': bssids,
      'myMac': myMac,
    }..removeWhere((key, value) => value == null);
  }

  factory InstantPrivacyState.fromMap(Map<String, dynamic> map) {
    return InstantPrivacyState(
      mode: MacFilterMode.reslove(map['status']),
      macAddresses: List.from(map['macAddresses']),
      denyMacAddresses: List.from(map['denyMacAddresses']),
      maxMacAddresses: map['maxMacAddresses'] as int,
      bssids: map['bssids'] == null ? [] : List.from(map['bssids']),
      myMac: map['myMac'],
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantPrivacyState.fromJson(String source) =>
      InstantPrivacyState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
