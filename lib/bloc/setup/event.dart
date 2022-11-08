import 'package:equatable/equatable.dart';
import 'package:linksys_moab/bloc/add_nodes/state.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/setup/_setup.dart';
import 'package:linksys_moab/bloc/setup/state.dart';

abstract class SetupEvent extends Equatable {
  const SetupEvent();

  @override
  List<Object> get props => [];
}

class Init extends SetupEvent {}

class ResumePointChanged extends SetupEvent {
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

class SetAccountInfo extends SetupEvent {
  const SetAccountInfo({required this.accountInfo});

  final AccountInfo accountInfo;
}

class SetAdminPasswordHint extends SetupEvent {
  const SetAdminPasswordHint({
    required this.password,
    this.hint = '',
  });

  final String password;
  final String hint;
}

class SaveRouterSettings extends SetupEvent {}

class FetchNetworkId extends SetupEvent {}

class SetRouterProperties extends SetupEvent {
  const SetRouterProperties({required this.properties});

  final List<NodeProperties> properties;
}

class LocalAuthorizedCreatAccount extends SetupEvent {}
