import 'package:equatable/equatable.dart';
import 'package:moab_poc/bloc/setup/state.dart';

abstract class SetupEvent extends Equatable{
  const SetupEvent();

  @override
  List<Object> get props => [];
}

class ResumePointChanged extends SetupEvent{
  const ResumePointChanged({required this.status});

  final SetupResumePoint status;

  @override
  List<Object> get props => [status];
}

class SetWIFISSIDAndPassword extends SetupEvent {
  const SetWIFISSIDAndPassword({required this.ssid, required this.password});

  final String ssid;
  final String password;

  @override
  List<Object> get props => [ssid, password];
}

