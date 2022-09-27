import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/bloc/security/state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc(): super(SecurityState()) {
    on<SetUnsubscribedEvent>(_onSetUnsubscribedEvent);
    on<SetTrialActiveEvent>(_onSetTrialActiveEvent);
    on<SetFormalActiveEvent>(_onSetFormalActiveEvent);
    on<SetTrialExpiredEvent>(_onSetTrialExpiredEvent);
    on<SetExpiredEvent>(_onSetExpiredEvent);
    on<TurnOffSecurityEvent>(_onTurnOffSecurityEvent);
    on<ContentFilterCreatedEvent>(_onContentFilterCreatedEvent);
    on<CyberthreatDetectedEvent>(_onCyberthreatDetectedEvent);
  }

  void _onSetUnsubscribedEvent(SetUnsubscribedEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const inspectionCount = 11;
    const blockedVirusCount = 11;
    const blockedMalwareCount = 11;
    const blockedBotnetCount = 11;
    const blockedWebsiteCount = 11;
    const incidentCount = 11;
    const hasFilter = false;
    const updateDate = 'Aug 15, 2011';
    const range = SecurityEvaluatedRange.week;

    emit(UnsubscribedState(
      numOfInspection: inspectionCount,
      numOfBlockedVirus: blockedVirusCount,
      numOfBlockedMalware: blockedMalwareCount,
      numOfBlockedBotnet: blockedBotnetCount,
      numOfBlockedWebsite: blockedWebsiteCount,
      numOfIncidents: incidentCount,
      hasFilterCreated: hasFilter,
      latestUpdateDate: updateDate,
      evaluatedRange: range,
    ));
  }

  void _onSetTrialActiveEvent(SetTrialActiveEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const inspectionCount = 22;
    const blockedVirusCount = 22;
    const blockedMalwareCount = 22;
    const blockedBotnetCount = 22;
    const blockedWebsiteCount = 22;
    const incidentCount = 22;
    const hasFilter = false;
    const updateDate = 'Aug 15, 2022';
    const range = SecurityEvaluatedRange.week;
    const remaining = 22;

    emit(TrialActiveState(
      numOfInspection: inspectionCount,
      numOfBlockedVirus: blockedVirusCount,
      numOfBlockedMalware: blockedMalwareCount,
      numOfBlockedBotnet: blockedBotnetCount,
      numOfBlockedWebsite: blockedWebsiteCount,
      numOfIncidents: incidentCount,
      hasFilterCreated: hasFilter,
      latestUpdateDate: updateDate,
      evaluatedRange: range,
      remainingTrialDays: remaining,
    ));
  }

  void _onSetFormalActiveEvent(SetFormalActiveEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const inspectionCount = 33;
    const blockedVirusCount = 33;
    const blockedMalwareCount = 33;
    const blockedBotnetCount = 33;
    const blockedWebsiteCount = 33;
    const incidentCount = 33;
    const hasFilter = false;
    const updateDate = 'Aug 15, 2033';
    const range = SecurityEvaluatedRange.month;

    emit(FormalActiveState(
      numOfInspection: inspectionCount,
      numOfBlockedVirus: blockedVirusCount,
      numOfBlockedMalware: blockedMalwareCount,
      numOfBlockedBotnet: blockedBotnetCount,
      numOfBlockedWebsite: blockedWebsiteCount,
      numOfIncidents: incidentCount,
      hasFilterCreated: hasFilter,
      latestUpdateDate: updateDate,
      evaluatedRange: range,
    ));
  }

void _onSetTrialExpiredEvent(SetTrialExpiredEvent event, Emitter<SecurityState> emit) {
  //TODO: Remove the fake data
  const inspectionCount = 44;
  const blockedVirusCount = 44;
  const blockedMalwareCount = 44;
  const blockedBotnetCount = 44;
  const blockedWebsiteCount = 44;
  const incidentCount = 44;
  const hasFilter = false;
  const updateDate = 'Aug 15, 2044';
  const range = SecurityEvaluatedRange.day;

  emit(TrialExpiredState(
    numOfInspection: inspectionCount,
    numOfBlockedVirus: blockedVirusCount,
    numOfBlockedMalware: blockedMalwareCount,
    numOfBlockedBotnet: blockedBotnetCount,
    numOfBlockedWebsite: blockedWebsiteCount,
    numOfIncidents: incidentCount,
    hasFilterCreated: hasFilter,
    latestUpdateDate: updateDate,
    evaluatedRange: range,
  ));
}

  void _onSetExpiredEvent(SetExpiredEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const inspectionCount = 55;
    const blockedVirusCount = 55;
    const blockedMalwareCount = 55;
    const blockedBotnetCount = 55;
    const blockedWebsiteCount = 55;
    const incidentCount = 55;
    const hasFilter = false;
    const updateDate = 'Aug 15, 2055';
    const range = SecurityEvaluatedRange.day;

    emit(ExpiredState(
      numOfInspection: inspectionCount,
      numOfBlockedVirus: blockedVirusCount,
      numOfBlockedMalware: blockedMalwareCount,
      numOfBlockedBotnet: blockedBotnetCount,
      numOfBlockedWebsite: blockedWebsiteCount,
      numOfIncidents: incidentCount,
      hasFilterCreated: hasFilter,
      latestUpdateDate: updateDate,
      evaluatedRange: range,
    ));
  }

  void _onTurnOffSecurityEvent(TurnOffSecurityEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const inspectionCount = 66;
    const blockedVirusCount = 66;
    const blockedMalwareCount = 66;
    const blockedBotnetCount = 66;
    const blockedWebsiteCount = 66;
    const incidentCount = 66;
    const hasFilter = false;
    const updateDate = 'Aug 15, 2066';
    const range = SecurityEvaluatedRange.day;

    emit(TurnedOffState(
      numOfInspection: inspectionCount,
      numOfBlockedVirus: blockedVirusCount,
      numOfBlockedMalware: blockedMalwareCount,
      numOfBlockedBotnet: blockedBotnetCount,
      numOfBlockedWebsite: blockedWebsiteCount,
      numOfIncidents: incidentCount,
      hasFilterCreated: hasFilter,
      latestUpdateDate: updateDate,
      evaluatedRange: range,
    ));
  }

  void _onContentFilterCreatedEvent(ContentFilterCreatedEvent event, Emitter<SecurityState> emit) {
    //TODO: Remove the fake data
    const hasFilter = true;

    if (state is TrialActiveState) {
      emit((state as TrialActiveState).copyWith(
        hasFilterCreated: hasFilter,
      ));
    } else if (state is FormalActiveState) {
      emit((state as FormalActiveState).copyWith(
        hasFilterCreated: hasFilter,
      ));
    }
  }

  void _onCyberthreatDetectedEvent(CyberthreatDetectedEvent event, Emitter<SecurityState> emit) {
    int numOfBlockedVirus = state.numOfBlockedVirus;
    int numOfBlockedMalware = state.numOfBlockedMalware;
    int numOfBlockedBotnet = state.numOfBlockedBotnet;
    int numOfBlockedWebsite = state.numOfBlockedWebsite;
    switch(event.type) {
      case CyberthreatType.virus:
        numOfBlockedVirus += event.number;
        break;
      case CyberthreatType.malware:
        numOfBlockedMalware += event.number;
        break;
      case CyberthreatType.botnet:
        numOfBlockedBotnet += event.number;
        break;
      case CyberthreatType.website:
        numOfBlockedWebsite += event.number;
        break;
    }

    if (state is TrialActiveState) {
      emit((state as TrialActiveState).copyWith(
        numOfBlockedVirus: numOfBlockedVirus,
        numOfBlockedMalware: numOfBlockedMalware,
        numOfBlockedBotnet: numOfBlockedBotnet,
        numOfBlockedWebsite: numOfBlockedWebsite,
      ));
    } else if (state is FormalActiveState) {
      emit((state as FormalActiveState).copyWith(
        numOfBlockedVirus: numOfBlockedVirus,
        numOfBlockedMalware: numOfBlockedMalware,
        numOfBlockedBotnet: numOfBlockedBotnet,
        numOfBlockedWebsite: numOfBlockedWebsite,
      ));
    }
  }
}