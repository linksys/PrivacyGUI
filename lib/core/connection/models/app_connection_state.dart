enum AppConnectionState {
  authenticated,
  waitingForRecovery,
  loggedOut,
}

enum RecoveryTrigger {
  natural,
  operationalWifiChange,
  operationalReboot,
  operationalFirmwareUpgrade,
}

class RecoveryContext {
  const RecoveryContext({
    required this.trigger,
    required this.cooldown,
  });

  final RecoveryTrigger trigger;
  final Duration cooldown;

  static const natural = RecoveryContext(
    trigger: RecoveryTrigger.natural,
    cooldown: Duration.zero,
  );
}
