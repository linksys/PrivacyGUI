import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/network.dart';

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
}

class InternetCheckState extends Equatable {
  const InternetCheckState({
    this.status = InternetCheckStatus.init,
    this.device,
    this.isConfigured = false,
    this.wanConnectionStatus = 'Disconnected',
    this.isDetectingWANType = false,
    this.isInternetConnected = false,
  });

  final InternetCheckStatus status;
  final MoabNetwork? device;
  final bool isConfigured;
  final String wanConnectionStatus;
  final bool isDetectingWANType;
  final bool isInternetConnected;

  @override
  List<Object?> get props => [
        status,
        device,
        isConfigured,
        wanConnectionStatus,
        isDetectingWANType,
        isInternetConnected,
      ];

  InternetCheckState copyWith({
    InternetCheckStatus? status,
    MoabNetwork? device,
    bool? isConfigured,
    String? wanConnectionStatus,
    bool? isDetectingWANType,
    bool? isInternetConnected,
  }) {
    return InternetCheckState(
      status: status ?? this.status,
      device: device ?? this.device,
      isConfigured: isConfigured ?? this.isConfigured,
      wanConnectionStatus: wanConnectionStatus ?? this.wanConnectionStatus,
      isDetectingWANType: isDetectingWANType ?? this.isDetectingWANType,
      isInternetConnected: isInternetConnected ?? this.isInternetConnected,
    );
  }
}
