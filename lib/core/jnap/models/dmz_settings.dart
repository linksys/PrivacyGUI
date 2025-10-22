// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

enum DMZSourceType {
  auto,
  range,
  ;

  static DMZSourceType resolve(String value) =>
      values.firstWhere((element) => element.name == value);
}

enum DMZDestinationType {
  ip,
  mac,
  ;

  static DMZDestinationType resolve(String value) =>
      values.firstWhere((element) => element.name == value);
}

class DMZSettings extends Equatable {
  final bool isDMZEnabled;
  final DMZSourceRestriction? sourceRestriction;
  final String? destinationIPAddress;
  final String? destinationMACAddress;
  final DMZSourceType sourceType;
  final DMZDestinationType destinationType;
  const DMZSettings({
    required this.isDMZEnabled,
    this.sourceRestriction,
    this.destinationIPAddress,
    this.destinationMACAddress,
    this.sourceType = DMZSourceType.auto,
    this.destinationType = DMZDestinationType.ip,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isDMZEnabled': isDMZEnabled,
      'sourceRestriction': sourceRestriction?.toMap(),
      'destinationIPAddress': destinationIPAddress,
      'destinationMACAddress': destinationMACAddress,
      'sourceType': sourceType.name,
      'destinationType': destinationType.name,
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
      sourceType: map['sourceType'] != null
          ? DMZSourceType.resolve(map['sourceType'])
          : DMZSourceType.auto,
      destinationType: map['destinationType'] != null
          ? DMZDestinationType.resolve(map['destinationType'])
          : DMZDestinationType.ip,
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
        sourceType,
        destinationType,
      ];

  DMZSettings copyWith({
    bool? isDMZEnabled,
    ValueGetter<DMZSourceRestriction?>? sourceRestriction,
    ValueGetter<String?>? destinationIPAddress,
    ValueGetter<String?>? destinationMACAddress,
    DMZSourceType? sourceType,
    DMZDestinationType? destinationType,
  }) {
    return DMZSettings(
      isDMZEnabled: isDMZEnabled ?? this.isDMZEnabled,
      sourceRestriction:
          sourceRestriction != null ? sourceRestriction() : this.sourceRestriction,
      destinationIPAddress: destinationIPAddress != null
          ? destinationIPAddress()
          : this.destinationIPAddress,
      destinationMACAddress: destinationMACAddress != null
          ? destinationMACAddress()
          : this.destinationMACAddress,
      sourceType: sourceType ?? this.sourceType,
      destinationType: destinationType ?? this.destinationType,
    );
  }
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
      lastIPAddress: (map['lastIPAddress'] ?? map['firstIPAddress']) as String,
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
