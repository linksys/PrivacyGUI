/// What `UspAuthCoordinator.restoreSession` found (#1666).
///
/// It reports nothing itself: whoever asked decides what the outcome means.
/// `UspClient.reauth` ends the session on [rejected]; a recovery after an outage
/// ignores it, because a router that is still coming back is expected to fail.
enum SessionRestoreOutcome {
  /// A token was refreshed, in memory or from storage. The session goes on.
  restored,

  /// The router refused every token there was, or there was none to try. The
  /// credential is gone.
  rejected,

  /// The router could not be asked: a network error, no client, or a retry
  /// inside the cooldown after a failure. Says nothing about the credential.
  unreachable,
}
