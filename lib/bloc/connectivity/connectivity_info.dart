import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    this.type = ConnectivityResult.none,
    this.gatewayIp,
    this.ssid,
  });

  final ConnectivityResult type;
  final String? gatewayIp;
  final String? ssid;

  ConnectivityInfo copyWith({
    ConnectivityResult? type,
    String? gatewayIp,
    String? ssid,
  }) {
    return ConnectivityInfo(
      type: type ?? this.type,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      ssid: ssid ?? this.ssid,
    );
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid];
}
