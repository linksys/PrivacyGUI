import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_status.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/connection_status.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/speed_status.dart';
import 'package:privacy_gui/page/dual/models/logging_option.dart';
import 'package:privacy_gui/page/dual/models/port.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';

class DualWANSettings extends Equatable {
  final bool enable;
  final DualWANMode mode;
  final DualWANBalanceRatio? balanceRatio;
  final DualWANConfiguration primaryWAN;
  final DualWANConfiguration secondaryWAN;
  final LoggingOptions? loggingOptions;

  const DualWANSettings({
    required this.enable,
    required this.mode,
    required this.balanceRatio,
    required this.primaryWAN,
    required this.secondaryWAN,
    this.loggingOptions,
  });

  factory DualWANSettings.init() {
    return const DualWANSettings(
      enable: false,
      mode: DualWANMode.failover,
      balanceRatio: DualWANBalanceRatio.equalDistribution,
      primaryWAN:
          DualWANConfiguration(wanType: 'DHCP', supportedWANType: [], mtu: 0),
      secondaryWAN:
          DualWANConfiguration(wanType: 'DHCP', supportedWANType: [], mtu: 0),
      loggingOptions: null,
    );
  }

  DualWANSettings copyWith({
    bool? enable,
    DualWANMode? mode,
    DualWANBalanceRatio? balanceRatio,
    DualWANConfiguration? primaryWAN,
    DualWANConfiguration? secondaryWAN,
    LoggingOptions? loggingOptions,
  }) {
    return DualWANSettings(
      enable: enable ?? this.enable,
      mode: mode ?? this.mode,
      balanceRatio: balanceRatio ?? this.balanceRatio,
      primaryWAN: primaryWAN ?? this.primaryWAN,
      secondaryWAN: secondaryWAN ?? this.secondaryWAN,
      loggingOptions: loggingOptions ?? this.loggingOptions,
    );
  }

  factory DualWANSettings.fromMap(Map<String, dynamic> map) {
    return DualWANSettings(
      enable: map['enable'],
      mode: DualWANMode.fromValue(map['mode']),
      balanceRatio: DualWANBalanceRatio.fromValue(map['balanceRatio']),
      primaryWAN: DualWANConfiguration.fromMap(map['primaryWAN']),
      secondaryWAN: DualWANConfiguration.fromMap(map['secondaryWAN']),
      loggingOptions: LoggingOptions.fromMap(map['loggingOptions']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANSettings.fromJson(String source) =>
      DualWANSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enable': enable,
      'mode': mode.toValue(),
      'balanceRatio': balanceRatio?.toValue(),
      'primaryWAN': primaryWAN.toMap(),
      'secondaryWAN': secondaryWAN.toMap(),
      'loggingOptions': loggingOptions?.toMap(),
    }..removeWhere((key, value) => value == null);
  }
  factory DualWANSettings.fromData(RouterDualWANSettings data) {
    return DualWANSettings(
      enable: data.enabled,
      mode: DualWANMode.fromValue(data.mode),
      balanceRatio: data.ratio != null ? DualWANBalanceRatio.fromValue(data.ratio!) : null,
      primaryWAN: DualWANConfiguration.fromData(data.primaryWAN),
      secondaryWAN: DualWANConfiguration.fromData(data.secondaryWAN),
    );
  }
  RouterDualWANSettings toData() {
    return RouterDualWANSettings(
      enabled: enable,
      mode: DualWANModeData.fromJson(mode.toValue()),
      ratio: DualWANRatioData.fromJson(balanceRatio?.toValue() ?? ''),
      primaryWAN: primaryWAN.toData(),
      secondaryWAN: secondaryWAN.toData(),
    );
  }
  @override
  List<Object?> get props => [
        enable,
        mode,
        balanceRatio,
        primaryWAN,
        secondaryWAN,
        loggingOptions,
      ];
}

class DualWANStatus extends Equatable {
  final DualWANConnectionStatus connectionStatus;
  final SpeedStatus? speedStatus;
  final List<DualWANPort> ports;

  const DualWANStatus({
    required this.connectionStatus,
    this.speedStatus,
    required this.ports,
  });

  factory DualWANStatus.init() {
    return const DualWANStatus(
      connectionStatus: DualWANConnectionStatus(),
      ports: [],
    );
  }

  DualWANStatus copyWith({
    DualWANConnectionStatus? connectionStatus,
    SpeedStatus? speedStatus,
    List<DualWANPort>? ports,
  }) {
    return DualWANStatus(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      speedStatus: speedStatus ?? this.speedStatus,
      ports: ports ?? this.ports,
    );
  }

  factory DualWANStatus.fromMap(Map<String, dynamic> map) {
    return DualWANStatus(
      connectionStatus:
          DualWANConnectionStatus.fromMap(map['connectionStatus']),
      speedStatus: SpeedStatus.fromMap(map['speedStatus']),
      ports: map['ports'].map((x) => DualWANPort.fromMap(x)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANStatus.fromJson(String source) =>
      DualWANStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'connectionStatus': connectionStatus.toMap(),
      'speedStatus': speedStatus?.toMap(),
      'ports': ports.map((x) => x.toMap()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        connectionStatus,
        speedStatus,
        ports,
      ];

  factory DualWANStatus.fromData({required RouterDualWANStatus data, List<DualWANPort>? ports}) {
    return DualWANStatus(
      connectionStatus: DualWANConnectionStatus.fromData(data),
      ports: ports ?? [],
    );
  }
}

class DualWANSettingsState extends Equatable {
  final DualWANSettings settings;
  final DualWANStatus status;

  const DualWANSettingsState({
    required this.settings,
    required this.status,
  });

  factory DualWANSettingsState.init() {
    return DualWANSettingsState(
      settings: DualWANSettings.init(),
      status: DualWANStatus.init(),
    );
  }

  DualWANSettingsState copyWith({
    DualWANSettings? settings,
    DualWANStatus? status,
  }) {
    return DualWANSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  factory DualWANSettingsState.fromMap(Map<String, dynamic> map) {
    return DualWANSettingsState(
      settings: DualWANSettings.fromMap(map['settings']),
      status: DualWANStatus.fromMap(map['status']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANSettingsState.fromJson(String source) =>
      DualWANSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
      'status': status.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        settings,
        status,
      ];
}
