

abstract class SecurityEvent {}


class SetTrialSubscription extends SecurityEvent {

}

class SetTrialExpiredSubscription extends SecurityEvent {

}

class SetActiveSubscription extends SecurityEvent {

}

class SetExpiredSubscription extends SecurityEvent {

}

class TurnOffSecurity extends SecurityEvent {

}

class ContentFilterCreated extends SecurityEvent {

}

class CyberThreatDetected extends SecurityEvent {

}