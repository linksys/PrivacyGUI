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
    this.healthOnly = false,
  });

  final RecoveryTrigger trigger;
  final Duration cooldown;

  /// When true, the probe only waits for the router to respond to health check.
  /// Session restore and serial verification are skipped.
  /// Used for factory reset where old credentials are wiped.
  final bool healthOnly;

  static const natural = RecoveryContext(
    trigger: RecoveryTrigger.natural,
    cooldown: Duration.zero,
  );
}
