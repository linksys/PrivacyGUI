import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:moab_poc/bloc/connectivity/availability_info.dart';

class ConnectivityInfo extends Equatable {
  const ConnectivityInfo(
      {this.type = ConnectivityResult.none,
      required this.gatewayIp,
      required this.ssid,
      this.availabilityInfo});

  final ConnectivityResult type;
  final String gatewayIp;
  final String ssid;
  final AvailabilityInfo? availabilityInfo;

  ConnectivityInfo copyWith(
      {ConnectivityResult? type,
      String? gatewayIp,
      String? ssid,
      AvailabilityInfo? availabilityInfo}) {
    return ConnectivityInfo(
        type: type ?? this.type,
        gatewayIp: gatewayIp ?? this.gatewayIp,
        ssid: ssid ?? this.ssid,
        availabilityInfo: availabilityInfo ?? this.availabilityInfo);
  }

  @override
  List<Object?> get props => [type, gatewayIp, ssid];
}
