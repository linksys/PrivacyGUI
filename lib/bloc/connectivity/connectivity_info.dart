import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    this.type = ConnectivityResult.none,
    this.gatewayIp,
    this.ssid,
    this.isMoabRouter = false,
  });

  final ConnectivityResult type;
  final String? gatewayIp;
  final String? ssid;
  final bool isMoabRouter;

  ConnectivityInfo copyWith({
    ConnectivityResult? type,
    String? gatewayIp,
    String? ssid,
    bool? isMoabRouter,
  }) {
    return ConnectivityInfo(
      type: type ?? this.type,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      ssid: ssid ?? this.ssid,
      isMoabRouter: isMoabRouter ?? this.isMoabRouter,
    );
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid, isMoabRouter];
}
