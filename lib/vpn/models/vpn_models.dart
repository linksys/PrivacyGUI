import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// Status of the IPsec tunnel
///
/// #@ Disconnected
/// "Disconnected"
///
/// #@ Connecting
/// "Connecting"
///
/// #@ Connected
/// "Connected"
///
/// #@ Failed
/// "Failed"
///
/// #@ Unknown
/// "Unknown"
///
enum IPsecStatus {
  disconnected,
  connecting,
  connected,
  failed,
  unknown;

  String toDisplayName(BuildContext context) {
    switch (this) {
      case IPsecStatus.disconnected:
        return loc(context).vpnDisconnected;
      case IPsecStatus.connecting:
        return loc(context).vpnConnecting;
      case IPsecStatus.connected:
        return loc(context).vpnConnected;
      case IPsecStatus.failed:
        return loc(context).vpnFailed;
      case IPsecStatus.unknown:
        return loc(context).vpnUnknown;
    }
  }

  String toValue() {
    switch (this) {
      case IPsecStatus.disconnected:
        return 'disconnected';
      case IPsecStatus.connecting:
        return 'connecting';
      case IPsecStatus.connected:
        return 'connected';
      case IPsecStatus.failed:
        return 'failed';
      case IPsecStatus.unknown:
        return 'unknown';
    }
  }

  static IPsecStatus fromJson(String json) => IPsecStatus.values.firstWhere(
        (e) => e.toValue() == json,
        orElse: () => IPsecStatus.unknown,
      );
}

/// Types of IKE exchange mode

/// #@ IKEv1 mode
/// "IKEv1"
///
/// #@ IKEv2 mode
/// "IKEv2"
enum IKEMode {
  ikev1,
  ikev2;

  String toDisplayName(BuildContext context) {
    switch (this) {
      case IKEMode.ikev1:
        return 'IKEv1';
      case IKEMode.ikev2:
        return 'IKEv2';
    }
  }

  String toValue() {
    switch (this) {
      case IKEMode.ikev1:
        return 'ikev1';
      case IKEMode.ikev2:
        return 'ikev2';
    }
  }

  static IKEMode fromJson(String json) => IKEMode.values.firstWhere(
        (e) => e.toValue() == json,
        orElse: () => IKEMode.ikev2,
      );
}

/// Auth mode for VPN user credentials
///
/// #@ Pre-shared key authentication
/// "PSK"
///
/// #@ EAP authentication
/// "EAP"
///
/// #@ Certificate-based authentication
/// "Certificate"
enum AuthMode {
  psk,
  eap,
  certificate;

  String toDisplayName(BuildContext context) {
    switch (this) {
      case AuthMode.psk:
        return loc(context).psk;
      case AuthMode.eap:
        return loc(context).eap;
      case AuthMode.certificate:
        return loc(context).certificate;
    }
  }

  String toValue() {
    switch (this) {
      case AuthMode.psk:
        return "PSK";
      case AuthMode.eap:
        return "EAP";
      case AuthMode.certificate:
        return "Certificate";
    }
  }

  static AuthMode fromJson(String json) => AuthMode.values.firstWhere(
        (e) => e.toValue() == json,
        orElse: () => AuthMode.psk,
      );
}

class VPNUserCredentials extends Equatable {
  final String username;
  final AuthMode authMode;
  final String? secret;

  const VPNUserCredentials({
    required this.username,
    required this.authMode,
    this.secret,
  });

  @override
  List<Object?> get props => [username, authMode, secret];

  VPNUserCredentials copyWith({
    String? username,
    AuthMode? authMode,
    String? secret,
  }) {
    return VPNUserCredentials(
      username: username ?? this.username,
      authMode: authMode ?? this.authMode,
      secret: secret ?? this.secret,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'authMode': authMode.toValue(),
      'secret': secret,
    };
  }

  factory VPNUserCredentials.fromMap(Map<String, dynamic> json) {
    return VPNUserCredentials(
      username: json['username'] as String,
      authMode: AuthMode.values.firstWhere(
        (e) => e.toString().split('.').last == json['authMode'],
        orElse: () => AuthMode.psk,
      ),
      secret: json['secret'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory VPNUserCredentials.fromJson(String json) =>
      VPNUserCredentials.fromMap(jsonDecode(json));
}

class VPNGatewaySettings extends Equatable {
  final String gatewayAddress;
  final String dnsName;
  final IKEMode ikeMode;
  final String ikeProposal;
  final String espProposal;

  const VPNGatewaySettings({
    required this.gatewayAddress,
    required this.dnsName,
    required this.ikeMode,
    required this.ikeProposal,
    required this.espProposal,
  });

  @override
  List<Object> get props =>
      [gatewayAddress, dnsName, ikeMode, ikeProposal, espProposal];

  VPNGatewaySettings copyWith({
    String? gatewayAddress,
    String? dnsName,
    IKEMode? ikeMode,
    String? ikeProposal,
    String? espProposal,
  }) {
    return VPNGatewaySettings(
      gatewayAddress: gatewayAddress ?? this.gatewayAddress,
      dnsName: dnsName ?? this.dnsName,
      ikeMode: ikeMode ?? this.ikeMode,
      ikeProposal: ikeProposal ?? this.ikeProposal,
      espProposal: espProposal ?? this.espProposal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gatewayAddress': gatewayAddress,
      'dnsName': dnsName,
      'ikeMode': ikeMode.toValue(),
      'ikeProposal': ikeProposal,
      'espProposal': espProposal,
    };
  }

  factory VPNGatewaySettings.fromMap(Map<String, dynamic> json) {
    return VPNGatewaySettings(
      gatewayAddress: json['gatewayAddress'] as String,
      dnsName: json['dnsName'] as String,
      ikeMode: IKEMode.fromJson(json['ikeMode'] as String),
      ikeProposal: json['ikeProposal'] as String,
      espProposal: json['espProposal'] as String,
    );
  }
    Map<String, dynamic> toJson() => toMap();

  factory VPNGatewaySettings.fromJson(String json) =>
      VPNGatewaySettings.fromMap(jsonDecode(json));
}

class VPNStatistics extends Equatable {
  final int uptime;
  final int packetsSent;
  final int packetsReceived;
  final int bytesSent;
  final int bytesReceived;
  final int currentBandwidth;
  final int activeSAs;
  final int rekeyCount;

  const VPNStatistics({
    required this.uptime,
    required this.packetsSent,
    required this.packetsReceived,
    required this.bytesSent,
    required this.bytesReceived,
    required this.currentBandwidth,
    required this.activeSAs,
    required this.rekeyCount,
  });

  @override
  List<Object?> get props => [
        uptime,
        packetsSent,
        packetsReceived,
        bytesSent,
        bytesReceived,
        currentBandwidth,
        activeSAs,
        rekeyCount,
      ];

  VPNStatistics copyWith({
    int? uptime,
    int? packetsSent,
    int? packetsReceived,
    int? bytesSent,
    int? bytesReceived,
    int? currentBandwidth,
    int? activeSAs,
    int? rekeyCount,
  }) {
    return VPNStatistics(
      uptime: uptime ?? this.uptime,
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      currentBandwidth: currentBandwidth ?? this.currentBandwidth,
      activeSAs: activeSAs ?? this.activeSAs,
      rekeyCount: rekeyCount ?? this.rekeyCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'uptime': uptime,
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'bytesSent': bytesSent,
        'bytesReceived': bytesReceived,
        'currentBandwidth': currentBandwidth,
        'activeSAs': activeSAs,
        'rekeyCount': rekeyCount,
      };

  factory VPNStatistics.fromMap(Map<String, dynamic> map) => VPNStatistics(
        uptime: map['uptime'] as int,
        packetsSent: map['packetsSent'] as int,
        packetsReceived: map['packetsReceived'] as int,
        bytesSent: map['bytesSent'] as int,
        bytesReceived: map['bytesReceived'] as int,
        currentBandwidth: map['currentBandwidth'] as int,
        activeSAs: map['activeSAs'] as int,
        rekeyCount: map['rekeyCount'] as int,
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNStatistics.fromJson(String json) =>
      VPNStatistics.fromMap(jsonDecode(json));
}

class VPNServiceSetSettings extends Equatable {
  final bool enabled;
  final bool autoConnect;

  const VPNServiceSetSettings({
    required this.enabled,
    required this.autoConnect,
  });

  @override
  List<Object> get props => [enabled, autoConnect];

  VPNServiceSetSettings copyWith({
    bool? enabled,
    bool? autoConnect,
  }) {
    return VPNServiceSetSettings(
      enabled: enabled ?? this.enabled,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'autoConnect': autoConnect,
      };

  factory VPNServiceSetSettings.fromMap(Map<String, dynamic> map) =>
      VPNServiceSetSettings(
        enabled: map['enabled'] as bool,
        autoConnect: map['autoConnect'] as bool,
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNServiceSetSettings.fromJson(String json) =>
      VPNServiceSetSettings.fromMap(jsonDecode(json));
}

class VPNServiceSettings extends Equatable {
  final bool enabled;
  final bool autoConnect;
  final VPNStatistics? statistics;
  final IPsecStatus tunnelStatus;

  const VPNServiceSettings({
    required this.enabled,
    required this.autoConnect,
    required this.statistics,
    required this.tunnelStatus,
  });

  @override
  List<Object?> get props => [enabled, autoConnect, statistics, tunnelStatus];

  VPNServiceSettings copyWith({
    bool? enabled,
    bool? autoConnect,
    VPNStatistics? statistics,
    IPsecStatus? tunnelStatus,
  }) {
    return VPNServiceSettings(
      enabled: enabled ?? this.enabled,
      autoConnect: autoConnect ?? this.autoConnect,
      statistics: statistics ?? this.statistics,
      tunnelStatus: tunnelStatus ?? this.tunnelStatus,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'autoConnect': autoConnect,
        'statistics': statistics?.toMap(),
        'tunnelStatus': tunnelStatus.toValue(),
      };

  factory VPNServiceSettings.fromMap(Map<String, dynamic> map) =>
      VPNServiceSettings(
        enabled: map['enabled'] as bool,
        autoConnect: map['autoConnect'] as bool,
        statistics:
            VPNStatistics.fromMap(map['statistics'] as Map<String, dynamic>),
        tunnelStatus: IPsecStatus.fromJson(map['tunnelStatus'] as String),
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNServiceSettings.fromJson(String json) =>
      VPNServiceSettings.fromMap(jsonDecode(json));
}

class VPNTestResult extends Equatable {
  final bool success;
  final String statusMessage;
  final int latency;

  const VPNTestResult({
    required this.success,
    required this.statusMessage,
    required this.latency,
  });

  @override
  List<Object> get props => [success, statusMessage, latency];

  VPNTestResult copyWith({
    bool? success,
    String? statusMessage,
    int? latency,
  }) {
    return VPNTestResult(
      success: success ?? this.success,
      statusMessage: statusMessage ?? this.statusMessage,
      latency: latency ?? this.latency,
    );
  }

  Map<String, dynamic> toMap() => {
        'success': success,
        'statusMessage': statusMessage,
        'latency': latency,
      };

  factory VPNTestResult.fromMap(Map<String, dynamic> map) => VPNTestResult(
        success: map['success'] as bool,
        statusMessage: map['statusMessage'] as String,
        latency: map['latency'] as int,
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNTestResult.fromJson(String json) =>
      VPNTestResult.fromMap(jsonDecode(json));
}
