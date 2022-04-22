import 'package:equatable/equatable.dart';

abstract class LandingEvent extends Equatable {
  const LandingEvent();

  @override
  List<Object> get props => [];
}

class Initial extends LandingEvent {}

class CheckingConnection extends LandingEvent {}

class ScanQrCode extends LandingEvent {}

class ConnectionChanged extends LandingEvent {}
