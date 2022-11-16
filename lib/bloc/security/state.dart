
enum SubscriptionStatus {
  unsubscribed(displayTitle: 'Unsubscribed'),
  trialActive(displayTitle: 'Active (trial)'),
  active(displayTitle: 'Active'),
  trialExpired(displayTitle: 'Expired'),
  expired(displayTitle: 'Expired'),
  turnedOff(displayTitle: 'OFF');

  const SubscriptionStatus({required this.displayTitle});

  final String displayTitle;
}

enum CyberthreatType {
  virus(displayTitle: 'Viruses'),
  botnet(displayTitle: 'Botnet'),
  website(displayTitle: 'Malicious\nwebsites');

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

class SecurityState {
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.unsubscribed;
  final int numOfInspection;
  final int numOfBlockedVirus;
  final int numOfBlockedBotnet;
  final int numOfBlockedWebsite;
  final int numOfIncidents;
  final bool hasFilterCreated;
  final String latestUpdateDate;
  final SecurityEvaluatedRange evaluatedRange;
  bool get hasBlockedThreat {
    return numOfBlockedVirus > 0 ||
        numOfBlockedBotnet > 0 ||
        numOfBlockedWebsite > 0;
  }

  SecurityState({
    this.numOfInspection = 0,
    this.numOfBlockedVirus = 0,
    this.numOfBlockedBotnet = 0,
    this.numOfBlockedWebsite = 0,
    this.numOfIncidents = 0,
    this.hasFilterCreated = false,
    this.latestUpdateDate = '',
    this.evaluatedRange = SecurityEvaluatedRange.week,
  });
}

class UnsubscribedState extends SecurityState {
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.unsubscribed;

  UnsubscribedState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
  }) : super();
}

class TrialActiveState extends SecurityState {
  final int remainingTrialDays;
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.trialActive;

  TrialActiveState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
    this.remainingTrialDays = 0,
  }) : super();

  TrialActiveState copyWith({
    int? numOfInspection,
    int? numOfBlockedVirus,
    int? numOfBlockedBotnet,
    int? numOfBlockedWebsite,
    int? numOfIncidents,
    bool? hasFilterCreated,
    String? latestUpdateDate,
    SecurityEvaluatedRange? evaluatedRange,
    int? remainingTrialDays,
  }) {
    return TrialActiveState(
      numOfInspection: numOfInspection ?? super.numOfInspection,
      numOfBlockedVirus: numOfBlockedVirus ?? super.numOfBlockedVirus,
      numOfBlockedBotnet: numOfBlockedBotnet ?? super.numOfBlockedBotnet,
      numOfBlockedWebsite: numOfBlockedWebsite ?? super.numOfBlockedWebsite,
      numOfIncidents: numOfIncidents ?? super.numOfIncidents,
      hasFilterCreated: hasFilterCreated ?? super.hasFilterCreated,
      latestUpdateDate: latestUpdateDate ?? super.latestUpdateDate,
      evaluatedRange: evaluatedRange ?? super.evaluatedRange,
      remainingTrialDays: remainingTrialDays ?? this.remainingTrialDays,
    );
  }
}

class FormalActiveState extends SecurityState {
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.active;

  FormalActiveState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
  });

  FormalActiveState copyWith({
    int? numOfInspection,
    int? numOfBlockedVirus,
    int? numOfBlockedBotnet,
    int? numOfBlockedWebsite,
    int? numOfIncidents,
    bool? hasFilterCreated,
    String? latestUpdateDate,
    SecurityEvaluatedRange? evaluatedRange,
  }) {
    return FormalActiveState(
      numOfInspection: numOfInspection ?? super.numOfInspection,
      numOfBlockedVirus: numOfBlockedVirus ?? super.numOfBlockedVirus,
      numOfBlockedBotnet: numOfBlockedBotnet ?? super.numOfBlockedBotnet,
      numOfBlockedWebsite: numOfBlockedWebsite ?? super.numOfBlockedWebsite,
      numOfIncidents: numOfIncidents ?? super.numOfIncidents,
      hasFilterCreated: hasFilterCreated ?? super.hasFilterCreated,
      latestUpdateDate: latestUpdateDate ?? super.latestUpdateDate,
      evaluatedRange: evaluatedRange ?? super.evaluatedRange,
    );
  }
}

class TrialExpiredState extends SecurityState {
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.trialExpired;

  TrialExpiredState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
  }) : super();
}

class ExpiredState extends SecurityState {
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.expired;

  ExpiredState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
  }) : super();
}

class TurnedOffState extends SecurityState {
  @override
  SubscriptionStatus get subscriptionStatus => SubscriptionStatus.turnedOff;

  TurnedOffState({
    super.numOfInspection,
    super.numOfBlockedVirus,
    super.numOfBlockedBotnet,
    super.numOfBlockedWebsite,
    super.numOfIncidents,
    super.hasFilterCreated,
    super.latestUpdateDate,
    super.evaluatedRange,
  }) : super();
}


