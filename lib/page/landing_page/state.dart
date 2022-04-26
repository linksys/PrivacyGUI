import 'package:equatable/equatable.dart';

class LandingState extends Equatable {
  const LandingState._(
      {this.isConnectToDevice = false,
      this.ssid = '',
      this.gatewayIp = '',
      this.scanning = false});

  final String ssid;
  final String gatewayIp;
  final bool isConnectToDevice;
  final bool scanning;

  const LandingState.init() : this._();
  const LandingState.connectionChanged(
      {required String ip, required String ssid, required bool isConnected})
      : this._(gatewayIp: ip, ssid: ssid, isConnectToDevice: isConnected);

  const LandingState.scan() : this._(scanning: true);
  const LandingState.stopScanning() : this._(scanning: false);

  @override
  List<Object> get props => [gatewayIp, isConnectToDevice, ssid, scanning];
}
