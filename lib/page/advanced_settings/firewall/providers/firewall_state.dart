import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

/// UI model for firewall settings - bridges Data layer and Presentation layer
/// This isolates the Presentation layer from JNAP protocol details.
class FirewallUISettings extends Equatable {
  /// Whether to block requests from anonymous sources
  final bool blockAnonymousRequests;

  /// Whether to block IDENT protocol (port 113)
  final bool blockIDENT;

  /// Whether to block IPSec protocol
  final bool blockIPSec;

  /// Whether to block L2TP protocol (Layer 2 Tunneling Protocol)
  final bool blockL2TP;

  /// Whether to block multicast traffic
  final bool blockMulticast;

  /// Whether to block NAT redirection
  final bool blockNATRedirection;

  /// Whether to block PPTP protocol (Point-to-Point Tunneling Protocol)
  final bool blockPPTP;

  /// Whether IPv4 firewall is enabled
  final bool isIPv4FirewallEnabled;

  /// Whether IPv6 firewall is enabled
  final bool isIPv6FirewallEnabled;

  const FirewallUISettings({
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

  /// Create a copy with optional field overrides
  FirewallUISettings copyWith({
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
    return FirewallUISettings(
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

  /// Convert to Map for serialization
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

  /// Create from Map for deserialization
  factory FirewallUISettings.fromMap(Map<String, dynamic> map) {
    return FirewallUISettings(
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

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory FirewallUISettings.fromJson(String source) =>
      FirewallUISettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [
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

class FirewallState extends FeatureState<FirewallUISettings, EmptyStatus> {
  const FirewallState({
    required super.settings,
    required super.status,
  });

  @override
  FirewallState copyWith({
    Preservable<FirewallUISettings>? settings,
    EmptyStatus? status,
  }) {
    return FirewallState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': {},
    };
  }

  factory FirewallState.fromMap(Map<String, dynamic> map) {
    return FirewallState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) =>
            FirewallUISettings.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: const EmptyStatus(),
    );
  }

  factory FirewallState.fromJson(String source) =>
      FirewallState.fromMap(json.decode(source) as Map<String, dynamic>);
}
