import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    this.type = ConnectivityResult.none,
    this.gatewayIp,
    this.ssid,
    this.isManagedRouter = false,
  });

  final ConnectivityResult type;
  final String? gatewayIp;
  final String? ssid;
  final bool isManagedRouter;

  ConnectivityInfo copyWith({
    ConnectivityResult? type,
    String? gatewayIp,
    String? ssid,
    bool? isManagedRouter,
  }) {
    return ConnectivityInfo(
      type: type ?? this.type,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      ssid: ssid ?? this.ssid,
      isManagedRouter: isManagedRouter ?? this.isManagedRouter,
    );
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid, isManagedRouter];
}
