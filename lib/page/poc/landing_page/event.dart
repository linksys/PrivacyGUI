import 'package:equatable/equatable.dart';
import 'package:moab_poc/bloc/connectivity/connectivity_info.dart';

abstract class LandingEvent extends Equatable {
  const LandingEvent();

  @override
  List<Object> get props => [];
}

class Initial extends LandingEvent {}

class CheckingConnection extends LandingEvent {

  const CheckingConnection({required this.info});

  final ConnectivityInfo info;
}

class ScanQrCode extends LandingEvent {}

class StopScanningQrCode extends LandingEvent {}

class ConnectionChanged extends LandingEvent {}
