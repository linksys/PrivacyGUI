

import 'package:linksys_moab/bloc/security/state.dart';

abstract class SecurityEvent {}

class SetUnsubscribedEvent extends SecurityEvent {

}

class SetTrialActiveEvent extends SecurityEvent {

}

class SetFormalActiveEvent extends SecurityEvent {

}

class SetTrialExpiredEvent extends SecurityEvent {

}

class SetExpiredEvent extends SecurityEvent {

}

class TurnOffSecurityEvent extends SecurityEvent {

}

class ContentFilterCreatedEvent extends SecurityEvent {

}

class CyberthreatDetectedEvent extends SecurityEvent {
  final CyberthreatType type;
  final int number;

  CyberthreatDetectedEvent({
    required this.type,
    required this.number,
  });
}