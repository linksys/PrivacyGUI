import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

enum RouterType {
  behind,
  behindManaged,
  others,
}

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    this.type = ConnectivityResult.none,
    this.gatewayIp,
    this.ssid,
    this.routerType = RouterType.others,
  });

  final ConnectivityResult type;
  final String? gatewayIp;
  final String? ssid;
  final RouterType routerType;

  ConnectivityInfo copyWith({
    ConnectivityResult? type,
    String? gatewayIp,
    String? ssid,
    RouterType? routerType,
  }) {
    return ConnectivityInfo(
      type: type ?? this.type,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      ssid: ssid ?? this.ssid,
      routerType: routerType ?? this.routerType,
    );
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid, routerType];
}
