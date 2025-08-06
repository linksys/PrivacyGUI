import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';
import 'package:privacy_gui/page/dual/models/connection_status.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/models/speed_status.dart';
import 'package:privacy_gui/page/dual/models/logging_option.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';

class DualWANSettingsState extends Equatable {
  final bool enable;
  final DualWANMode mode;
  final DualWANBalanceRatio? balanceRatio;
  final DualWANConfiguration primaryWAN;
  final DualWANConfiguration secondaryWAN;
  final ConnectionStatus connectionStatus;
  final SpeedStatus speedStatus;
  final LoggingOptions loggingOptions;

  const DualWANSettingsState({
    required this.enable,
    required this.mode,
    required this.balanceRatio,
    required this.primaryWAN,
    required this.secondaryWAN,
    required this.connectionStatus,
    required this.speedStatus,
    required this.loggingOptions,
  });

  factory DualWANSettingsState.init() {
    return const DualWANSettingsState(
      enable: false,
      mode: DualWANMode.failover,
      balanceRatio: DualWANBalanceRatio.equalDistribution,
      primaryWAN: DualWANConfiguration(
          ipv4ConnectionType: 'DHCP',
          supportedIPv4ConnectionType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
          supportedWANCombinations: [],
          mtu: 0),
      secondaryWAN: DualWANConfiguration(
          ipv4ConnectionType: 'DHCP',
          supportedIPv4ConnectionType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
          supportedWANCombinations: [],
          mtu: 0),
      connectionStatus: ConnectionStatus(),
      speedStatus: SpeedStatus(),
      loggingOptions: LoggingOptions(
        failoverEvents: true,
        wanUptime: true,
        speedChecks: false,
        throughputData: false,
      ),
    );
  }

  factory DualWANSettingsState.mock() {
    return const DualWANSettingsState(
      enable: true,
      mode: DualWANMode.failover,
      balanceRatio: DualWANBalanceRatio.equalDistribution,
      primaryWAN: DualWANConfiguration(
          ipv4ConnectionType: 'DHCP',
          supportedIPv4ConnectionType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
          supportedWANCombinations: [],
          mtu: 0),
      secondaryWAN: DualWANConfiguration(
          ipv4ConnectionType: 'DHCP',
          supportedIPv4ConnectionType: ['DHCP', 'Static', 'PPPoE', 'PPTP'],
          supportedWANCombinations: [],
          mtu: 0),
      connectionStatus: ConnectionStatus(
        primaryStatus: DualWANConnection.connected,
        secondaryStatus: DualWANConnection.active,
        primaryUptime: 123,
        secondaryUptime: 123,
        primaryWANIPAddress: '203.0.113.10',
        secondaryWANIPAddress: '198.51.100.25',
      ),
      speedStatus: SpeedStatus(
        primaryDownloadSpeed: 1234567890,
        primaryUploadSpeed: 1234567890,
        secondaryDownloadSpeed: 1234567890,
        secondaryUploadSpeed: 1234567890,
      ),
      loggingOptions: LoggingOptions(
        failoverEvents: true,
        wanUptime: true,
        speedChecks: false,
        throughputData: false,
      ),
    );
  }

  DualWANSettingsState copyWith({
    bool? enable,
    DualWANMode? mode,
    DualWANBalanceRatio? balanceRatio,
    DualWANConfiguration? primaryWAN,
    DualWANConfiguration? secondaryWAN,
    ConnectionStatus? connectionStatus,
    SpeedStatus? speedStatus,
    LoggingOptions? loggingOptions,
  }) {
    return DualWANSettingsState(
      enable: enable ?? this.enable,
      mode: mode ?? this.mode,
      balanceRatio: balanceRatio ?? this.balanceRatio,
      primaryWAN: primaryWAN ?? this.primaryWAN,
      secondaryWAN: secondaryWAN ?? this.secondaryWAN,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      speedStatus: speedStatus ?? this.speedStatus,
      loggingOptions: loggingOptions ?? this.loggingOptions,
    );
  }

  factory DualWANSettingsState.fromMap(Map<String, dynamic> map) {
    return DualWANSettingsState(
      enable: map['enable'],
      mode: DualWANMode.fromValue(map['mode']),
      balanceRatio: DualWANBalanceRatio.fromValue(map['balanceRatio']),
      primaryWAN: DualWANConfiguration.fromMap(map['primaryWAN']),
      secondaryWAN: DualWANConfiguration.fromMap(map['secondaryWAN']),
      connectionStatus: ConnectionStatus.fromMap(map['connectionStatus']),
      speedStatus: SpeedStatus.fromMap(map['speedStatus']),
      loggingOptions: LoggingOptions.fromMap(map['loggingOptions']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANSettingsState.fromJson(String source) =>
      DualWANSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enable': enable,
      'mode': mode.toValue(),
      'balanceRatio': balanceRatio?.toValue(),
      'primaryWAN': primaryWAN.toMap(),
      'secondaryWAN': secondaryWAN.toMap(),
      'connectionStatus': connectionStatus.toMap(),
      'speedStatus': speedStatus.toMap(),
      'loggingOptions': loggingOptions.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props =>
      [enable, mode, balanceRatio, primaryWAN, secondaryWAN];
}
