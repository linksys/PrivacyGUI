import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';

class VPNSettings extends Equatable {
  final bool isEditingCredentials;
  final VPNUserCredentials? userCredentials;
  final VPNGatewaySettings? gatewaySettings;
  final VPNServiceSetSettings? serviceSettings;
  final String? tunneledUserIP;

  const VPNSettings({
    this.isEditingCredentials = false,
    this.userCredentials,
    this.gatewaySettings,
    this.serviceSettings,
    this.tunneledUserIP,
  });

  @override
  List<Object?> get props => [
        isEditingCredentials,
        userCredentials,
        gatewaySettings,
        serviceSettings,
        tunneledUserIP,
      ];

  VPNSettings copyWith({
    bool? isEditingCredentials,
    VPNUserCredentials? userCredentials,
    VPNGatewaySettings? gatewaySettings,
    VPNServiceSetSettings? serviceSettings,
    String? tunneledUserIP,
  }) {
    return VPNSettings(
      isEditingCredentials: isEditingCredentials ?? this.isEditingCredentials,
      userCredentials: userCredentials ?? this.userCredentials,
      gatewaySettings: gatewaySettings ?? this.gatewaySettings,
      serviceSettings: serviceSettings ?? this.serviceSettings,
      tunneledUserIP: tunneledUserIP ?? this.tunneledUserIP,
    );
  }

  Map<String, dynamic> toMap() => {
        'isEditingCredentials': isEditingCredentials,
        if (userCredentials != null)
          'userCredentials': userCredentials!.toJson(),
        if (gatewaySettings != null)
          'gatewaySettings': gatewaySettings!.toJson(),
        if (serviceSettings != null)
          'serviceSettings': serviceSettings!.toJson(),
        if (tunneledUserIP != null) 'tunneledUserIP': tunneledUserIP,
      };

  factory VPNSettings.fromMap(Map<String, dynamic> map) => VPNSettings(
        isEditingCredentials: map['isEditingCredentials'] ?? false,
        userCredentials: map['userCredentials'] != null
            ? VPNUserCredentials.fromMap(
                map['userCredentials'] as Map<String, dynamic>)
            : null,
        gatewaySettings: map['gatewaySettings'] != null
            ? VPNGatewaySettings.fromMap(
                map['gatewaySettings'] as Map<String, dynamic>)
            : null,
        serviceSettings: map['serviceSettings'] != null
            ? VPNServiceSetSettings.fromMap(
                map['serviceSettings'] as Map<String, dynamic>)
            : null,
        tunneledUserIP: map['tunneledUserIP'] as String?,
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNSettings.fromJson(String json) =>
      VPNSettings.fromMap(jsonDecode(json));
}

class VPNStatus extends Equatable {
  final VPNStatistics? statistics;
  final IPsecStatus tunnelStatus;
  final VPNTestResult? testResult;

  const VPNStatus({
    this.statistics,
    required this.tunnelStatus,
    this.testResult,
  });

  @override
  List<Object?> get props => [statistics, tunnelStatus, testResult];

  VPNStatus copyWith({
    VPNStatistics? statistics,
    IPsecStatus? tunnelStatus,
    VPNTestResult? testResult,
  }) {
    return VPNStatus(
      statistics: statistics ?? this.statistics,
      tunnelStatus: tunnelStatus ?? this.tunnelStatus,
      testResult: testResult ?? this.testResult,
    );
  }

  Map<String, dynamic> toMap() => {
        if (statistics != null) 'statistics': statistics!.toMap(),
        'tunnelStatus': tunnelStatus.toValue(),
        if (testResult != null) 'testResult': testResult!.toMap(),
      };

  factory VPNStatus.fromMap(Map<String, dynamic> map) => VPNStatus(
        statistics: map['statistics'] != null
            ? VPNStatistics.fromMap(map['statistics'] as Map<String, dynamic>)
            : null,
        tunnelStatus: IPsecStatus.values.firstWhere(
          (e) => e.toValue() == map['tunnelStatus'],
          orElse: () => IPsecStatus.unknown,
        ),
        testResult: map['testResult'] != null
            ? VPNTestResult.fromMap(map['testResult'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNStatus.fromJson(String json) =>
      VPNStatus.fromMap(jsonDecode(json));
}

class VPNState extends Equatable {
  final VPNStatus status;
  final VPNSettings settings;

  const VPNState({
    required this.status,
    required this.settings,
  });

  const VPNState.init()
      : status = const VPNStatus(
          statistics: null,
          tunnelStatus: IPsecStatus.disconnected,
          testResult: null,
        ),
        settings = const VPNSettings(
          userCredentials: null,
          gatewaySettings: null,
          serviceSettings: null,
          tunneledUserIP: null,
        );

  @override
  List<Object> get props => [status, settings];

  VPNState copyWith({
    VPNStatus? status,
    VPNSettings? settings,
  }) {
    return VPNState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.toMap(),
        'settings': settings.toMap(),
      };

  factory VPNState.fromMap(Map<String, dynamic> map) => VPNState(
        status: VPNStatus.fromMap(map['status'] as Map<String, dynamic>),
        settings: VPNSettings.fromMap(map['settings'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => toMap();

  factory VPNState.fromJson(String json) => VPNState.fromMap(jsonDecode(json));
}
