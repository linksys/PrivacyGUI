// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DMZSettings extends Equatable {
  final bool isDMZEnabled;
  final DMZSourceRestriction? sourceRestriction;
  final String? destinationIPAddress;
  final String? destinationMACAddress;
  const DMZSettings({
    required this.isDMZEnabled,
    this.sourceRestriction,
    this.destinationIPAddress,
    this.destinationMACAddress,
  });

  DMZSettings copyWith({
    bool? isDMZEnabled,
    DMZSourceRestriction? sourceRestriction,
    String? destinationIPAddress,
    String? destinationMACAddress,
  }) {
    return DMZSettings(
      isDMZEnabled: isDMZEnabled ?? this.isDMZEnabled,
      sourceRestriction: sourceRestriction ?? this.sourceRestriction,
      destinationIPAddress: destinationIPAddress ?? this.destinationIPAddress,
      destinationMACAddress:
          destinationMACAddress ?? this.destinationMACAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isDMZEnabled': isDMZEnabled,
      'sourceRestriction': sourceRestriction?.toMap(),
      'destinationIPAddress': destinationIPAddress,
      'destinationMACAddress': destinationMACAddress,
    };
  }

  factory DMZSettings.fromMap(Map<String, dynamic> map) {
    return DMZSettings(
      isDMZEnabled: map['isDMZEnabled'] as bool,
      sourceRestriction: map['sourceRestriction'] != null
          ? DMZSourceRestriction.fromMap(
              map['sourceRestriction'] as Map<String, dynamic>)
          : null,
      destinationIPAddress: map['destinationIPAddress'] != null
          ? map['destinationIPAddress'] as String
          : null,
      destinationMACAddress: map['destinationMACAddress'] != null
          ? map['destinationMACAddress'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DMZSettings.fromJson(String source) =>
      DMZSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        isDMZEnabled,
        sourceRestriction,
        destinationIPAddress,
        destinationMACAddress,
      ];
}

class DMZSourceRestriction extends Equatable {
  final String firstIPAddress;
  final String lastIPAddress;
  const DMZSourceRestriction({
    required this.firstIPAddress,
    required this.lastIPAddress,
  });

  DMZSourceRestriction copyWith({
    String? firstIPAddress,
    String? lastIPAddress,
  }) {
    return DMZSourceRestriction(
      firstIPAddress: firstIPAddress ?? this.firstIPAddress,
      lastIPAddress: lastIPAddress ?? this.lastIPAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstIPAddress': firstIPAddress,
      'lastIPAddress': lastIPAddress,
    };
  }

  factory DMZSourceRestriction.fromMap(Map<String, dynamic> map) {
    return DMZSourceRestriction(
      firstIPAddress: map['firstIPAddress'] as String,
      lastIPAddress: map['lastIPAddress'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DMZSourceRestriction.fromJson(String source) =>
      DMZSourceRestriction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [firstIPAddress, lastIPAddress];
}
