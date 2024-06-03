// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class FirewallSettings extends Equatable {
  final bool blockAnonymousRequests;
  final bool blockIDENT;
  final bool blockIPSec;
  final bool blockL2TP;
  final bool blockMulticast;
  final bool blockNATRedirection;
  final bool blockPPTP;
  final bool isIPv4FirewallEnabled;
  final bool isIPv6FirewallEnabled;
  const FirewallSettings({
    required this.blockAnonymousRequests,
    required this.blockIDENT,
    required this.blockIPSec,
    required this.blockL2TP,
    required this.blockMulticast,
    required this.blockNATRedirection,
    required this.blockPPTP,
    required this.isIPv4FirewallEnabled,
    required this.isIPv6FirewallEnabled,
  });

  FirewallSettings copyWith({
    bool? blockAnonymousRequests,
    bool? blockIDENT,
    bool? blockIPSec,
    bool? blockL2TP,
    bool? blockMulticast,
    bool? blockNATRedirection,
    bool? blockPPTP,
    bool? isIPv4FirewallEnabled,
    bool? isIPv6FirewallEnabled,
  }) {
    return FirewallSettings(
      blockAnonymousRequests:
          blockAnonymousRequests ?? this.blockAnonymousRequests,
      blockIDENT: blockIDENT ?? this.blockIDENT,
      blockIPSec: blockIPSec ?? this.blockIPSec,
      blockL2TP: blockL2TP ?? this.blockL2TP,
      blockMulticast: blockMulticast ?? this.blockMulticast,
      blockNATRedirection: blockNATRedirection ?? this.blockNATRedirection,
      blockPPTP: blockPPTP ?? this.blockPPTP,
      isIPv4FirewallEnabled:
          isIPv4FirewallEnabled ?? this.isIPv4FirewallEnabled,
      isIPv6FirewallEnabled:
          isIPv6FirewallEnabled ?? this.isIPv6FirewallEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'blockAnonymousRequests': blockAnonymousRequests,
      'blockIDENT': blockIDENT,
      'blockIPSec': blockIPSec,
      'blockL2TP': blockL2TP,
      'blockMulticast': blockMulticast,
      'blockNATRedirection': blockNATRedirection,
      'blockPPTP': blockPPTP,
      'isIPv4FirewallEnabled': isIPv4FirewallEnabled,
      'isIPv6FirewallEnabled': isIPv6FirewallEnabled,
    };
  }

  factory FirewallSettings.fromMap(Map<String, dynamic> map) {
    return FirewallSettings(
      blockAnonymousRequests: map['blockAnonymousRequests'] as bool,
      blockIDENT: map['blockIDENT'] as bool,
      blockIPSec: map['blockIPSec'] as bool,
      blockL2TP: map['blockL2TP'] as bool,
      blockMulticast: map['blockMulticast'] as bool,
      blockNATRedirection: map['blockNATRedirection'] as bool,
      blockPPTP: map['blockPPTP'] as bool,
      isIPv4FirewallEnabled: map['isIPv4FirewallEnabled'] as bool,
      isIPv6FirewallEnabled: map['isIPv6FirewallEnabled'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirewallSettings.fromJson(String source) =>
      FirewallSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      blockAnonymousRequests,
      blockIDENT,
      blockIPSec,
      blockL2TP,
      blockMulticast,
      blockNATRedirection,
      blockPPTP,
      isIPv4FirewallEnabled,
      isIPv6FirewallEnabled,
    ];
  }
}
