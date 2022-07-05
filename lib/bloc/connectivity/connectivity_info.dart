import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityInfo {
  const ConnectivityInfo({this.type = ConnectivityResult.none, required this.gatewayIp, required this.ssid});

  final ConnectivityResult type;
  final String gatewayIp;
  final String ssid;
}