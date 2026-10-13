/// What one probe attempt found.
///
/// A model rather than part of `RecoveryProbeService`, because the firmware
/// recovery dialog shows it, and views may not depend on services
/// (constitution §5.4).
enum ProbeResult {
  /// The router did not answer, or answered and then failed a step that could
  /// still succeed later. Keep waiting.
  unreachable,

  /// The router is back and the app may keep the session it had.
  recovered,

  /// The router is back and it is not the same router. Only reachable where a
  /// stored fingerprint exists to disagree with — see
  /// `CredentialStrategy.reestablishAfterOutage`.
  serialMismatch,
}
