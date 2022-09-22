import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/bloc/security/state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc(): super(SecurityState.init()) {
    on<SetTrialSubscription>(_onSetTrialSubscriptionEvent);
    on<SetTrialExpiredSubscription>(_onSetTrialExpiredSubscriptionEvent);
    on<SetActiveSubscription>(_onSetActiveSubscriptionEvent);
    on<SetExpiredSubscription>(_onSetExpiredSubscriptionEvent);
    on<TurnOffSecurity>(_onTurnOffSecurityEvent);
    on<ContentFilterCreated>(_onContentFilterCreatedEvent);
    on<CyberThreatDetected>(_onCyberThreatDetectedEvent);
  }

  void _onSetTrialSubscriptionEvent(SetTrialSubscription event, Emitter<SecurityState> emit) {
    var remainingDays = 22;
    emit(state.copyWith(
      subscriptionStatus: SubscriptionStatus.activeTrial,
      remainingTrialDays: remainingDays
    ));
  }

  void _onSetTrialExpiredSubscriptionEvent(SetTrialExpiredSubscription event, Emitter emit) {
    emit(state.copyWith(subscriptionStatus: SubscriptionStatus.trialExpired));
  }

  void _onSetActiveSubscriptionEvent(SetActiveSubscription event, Emitter emit) {
    emit(state.copyWith(subscriptionStatus: SubscriptionStatus.active));
  }

  void _onSetExpiredSubscriptionEvent(SetExpiredSubscription event, Emitter emit) {
    emit(state.copyWith(subscriptionStatus: SubscriptionStatus.expired));
  }

  void _onTurnOffSecurityEvent(TurnOffSecurity event, Emitter emit) {
    emit(state.copyWith(subscriptionStatus: SubscriptionStatus.activeTurnedOff));
  }

  void _onContentFilterCreatedEvent(ContentFilterCreated event, Emitter emit) {

  }

  void _onCyberThreatDetectedEvent(CyberThreatDetected event, Emitter emit) {

  }
}