import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    this.type = ConnectivityResult.none,
    this.gatewayIp,
    this.ssid,
    this.isBehindRouter = false,
  });

  final ConnectivityResult type;
  final String? gatewayIp;
  final String? ssid;
  final bool isBehindRouter;

  ConnectivityInfo copyWith({
    ConnectivityResult? type,
    String? gatewayIp,
    String? ssid,
    bool? isBehindRouter,
  }) {
    return ConnectivityInfo(
      type: type ?? this.type,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      ssid: ssid ?? this.ssid,
      isBehindRouter: isBehindRouter ?? this.isBehindRouter,
    );
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid, isBehindRouter];
}
