import 'package:equatable/equatable.dart';

enum SubscriptionStatus {
  unsubscribed(displayTitle: 'Unsubscribed'),
  active(displayTitle: 'Active'),
  activeTrial(displayTitle: 'Active (trial)'),
  activeTurnedOff(displayTitle: 'Active (Turned Off)'),
  expired(displayTitle: 'Expired'),
  trialExpired(displayTitle: 'Expired');

  const SubscriptionStatus({required this.displayTitle});

  final String displayTitle;
}

enum CyberthreatType {
  virus(displayTitle: 'Virus'),
  malware(displayTitle: 'Ransomware & Malware'),
  botnet(displayTitle: 'Botnet'),
  website(displayTitle: 'Malicious websites');

  const CyberthreatType({required this.displayTitle});

  final String displayTitle;
}

enum SecurityEvaluatedRange {
  day(displayTitle: 'day'),
  week(displayTitle: 'week'),
  month(displayTitle: 'month');

  const SecurityEvaluatedRange({required this.displayTitle});

  final String displayTitle;
}

class SecurityState extends Equatable {
  final SubscriptionStatus subscriptionStatus;
  final SecurityEvaluatedRange evaluatedRange;
  final String latestUpdateDate;
  final int remainingTrialDays;
  final int numOfInspection;
  final int numOfIncidents;
  final bool hasFilterCreated;
  final int numOfBlockedVirus;
  final int numOfBlockedMalware;
  final int numOfBlockedBotnet;
  final int numOfBlockedWebsite;
  bool get hasBlockedThreat {
    return numOfBlockedVirus > 0 ||
        numOfBlockedMalware > 0 ||
        numOfBlockedBotnet > 0 ||
        numOfBlockedWebsite > 0;
  }

  const SecurityState({
    required this.subscriptionStatus,
    required this.evaluatedRange,
    required this.latestUpdateDate,
    required this.remainingTrialDays,
    required this.numOfInspection,
    required this.numOfIncidents,
    required this.hasFilterCreated,
    required this.numOfBlockedVirus,
    required this.numOfBlockedMalware,
    required this.numOfBlockedBotnet,
    required this.numOfBlockedWebsite,
  });

  SecurityState.init()
      : subscriptionStatus = SubscriptionStatus.unsubscribed,
        evaluatedRange = SecurityEvaluatedRange.week,
        latestUpdateDate = 'Aug 15, 2022',
        remainingTrialDays = 30,
        numOfInspection = 924,
        numOfIncidents = 21,
        hasFilterCreated = true,
        numOfBlockedVirus = 3,
        numOfBlockedMalware = 6,
        numOfBlockedBotnet = 11,
        numOfBlockedWebsite = 4;

  SecurityState copyWith({
    String? headerPrompt,
    SubscriptionStatus? subscriptionStatus,
    SecurityEvaluatedRange? evaluatedRange,
    String? latestUpdateDate,
    int? remainingTrialDays,
    int? numOfInspection,
    int? numOfIncidents,
    bool? hasFilterCreated,
    int? numOfBlockedVirus,
    int? numOfBlockedMalware,
    int? numOfBlockedBotnet,
    int? numOfBlockedWebsite,
  }) {
    return SecurityState(
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      evaluatedRange: evaluatedRange ?? this.evaluatedRange,
      latestUpdateDate: latestUpdateDate ?? this.latestUpdateDate,
      remainingTrialDays: remainingTrialDays ?? this.remainingTrialDays,
      numOfInspection: numOfInspection ?? this.numOfInspection,
      numOfIncidents: numOfIncidents ?? this.numOfIncidents,
      hasFilterCreated: hasFilterCreated ?? this.hasFilterCreated,
      numOfBlockedVirus: numOfBlockedVirus ?? this.numOfBlockedVirus,
      numOfBlockedMalware: numOfBlockedMalware ?? this.numOfBlockedMalware,
      numOfBlockedBotnet: numOfBlockedBotnet ?? this.numOfBlockedBotnet,
      numOfBlockedWebsite: numOfBlockedWebsite ?? this.numOfBlockedWebsite,
    );
  }

  @override
  List<Object?> get props => [
    subscriptionStatus,
    evaluatedRange,
    latestUpdateDate,
    remainingTrialDays,
    numOfInspection,
    numOfIncidents,
    hasFilterCreated,
    numOfBlockedVirus,
    numOfBlockedMalware,
    numOfBlockedBotnet,
    numOfBlockedWebsite,
  ];
}
