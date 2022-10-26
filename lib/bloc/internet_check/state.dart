import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/wan_settings.dart';

enum InternetCheckStatus {
  init,
  connectedToRouter,
  errorConnectedToRouter,
  detectWANStatus,
  getInternetConnectionStatus,
  pppoe,
  static,
  checkWiring,
  noInternet,
  connected,
  manually,
  checkVLAN,
}

class InternetCheckState extends Equatable {
  const InternetCheckState({
    this.status = InternetCheckStatus.init,
    this.device,
    this.isConfigured = false,
    this.wanConnectionStatus = 'Disconnected',
    this.isDetectingWANType = false,
    this.isInternetConnected = false,
    this.routerWANSettings,
  });

  final InternetCheckStatus status;
  final MoabNetwork? device;
  final bool isConfigured;
  final String wanConnectionStatus;
  final bool isDetectingWANType;
  final bool isInternetConnected;

  // For PPPoE and Static
  final RouterWANSettings? routerWANSettings;

  @override
  List<Object?> get props => [
        status,
        device,
        isConfigured,
        wanConnectionStatus,
        isDetectingWANType,
        isInternetConnected,
        runtimeType,
      ];

  InternetCheckState copyWith({
    InternetCheckStatus? status,
    MoabNetwork? device,
    bool? isConfigured,
    String? wanConnectionStatus,
    bool? isDetectingWANType,
    bool? isInternetConnected,
    RouterWANSettings? routerWANSettings,
  }) {
    return InternetCheckState(
      status: status ?? this.status,
      device: device ?? this.device,
      isConfigured: isConfigured ?? this.isConfigured,
      wanConnectionStatus: wanConnectionStatus ?? this.wanConnectionStatus,
      isDetectingWANType: isDetectingWANType ?? this.isDetectingWANType,
      isInternetConnected: isInternetConnected ?? this.isInternetConnected,
      routerWANSettings: routerWANSettings ?? this.routerWANSettings,
    );
  }
}
