/// What a caller hands `SessionStrategy.start()` to open a session.
///
/// Beside the contract for the same reason as `session_entry.dart` and
/// `session_end.dart`: the framework names it to state a signature.
library;

import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

/// The credential material a mode needs to open a session.
///
/// **Sealed, and the sealing is load-bearing.** The two modes' entries take
/// genuinely different inputs — a password versus a Guardian session id, a
/// temporary token and the session metadata the confirm view already fetched — so
/// `start()` cannot take a common parameter list without one mode ignoring half of
/// it. Sealing the union is what makes the mismatch a *type* error at the call site
/// instead of a runtime surprise.
///
/// That is also the defect phase 1 of #1474 filed and could only gate with a source
/// scan. A `?session=` URL arriving in a local build used to reach
/// `activate(config)`, registering a Guardian-proxied `UspClient` while
/// `BuildConfig.isRemote()` stayed false — local endpoint paths and no bearer token
/// against the Guardian origin, "is this RA?" answered two ways in one session.
/// With this union there is no expressible way to hand [SupportSessionRequest] to
/// the local strategy: the two `start()` implementations pattern-match, and the
/// wrong variant is an `ArgumentError` at the seam rather than a hybrid transport
/// eight request sites downstream.
sealed class SessionRequest {
  const SessionRequest();
}

/// Open a session with the user's own router credentials.
///
/// Only the password: everything else the local entry needs — the endpoint, the
/// admin username, the fingerprint — is either fixed or derived, and
/// `UspAuthCoordinator` already owns that derivation.
final class OwnCredentialsRequest extends SessionRequest {
  final String password;

  const OwnCredentialsRequest(this.password);
}

/// Open a Remote Assistance session against a Guardian engagement.
///
/// [sessionId] and [token] are the two URL parameters; the remaining two are what
/// the confirm view learned from `fetchSessionInfoForCA` before the user pressed
/// Connect and are optional because they are *display* state, not credentials.
/// `updateSessionInfo(null, null)` clears rather than throws, so a caller that has
/// validated but lost the info still opens a working session — it just shows no
/// countdown.
///
/// Note what is **not** here: `guardianBaseUrl` and `clientTypeId`. Both are build
/// configuration (`cloudEnvironmentConfig[kCloudBase]`, `kClientTypeId`), not
/// something a caller decides, and the strategy reads them itself. Passing them in
/// would let a caller point an RA session at the wrong Guardian, which is the class
/// of mistake this union exists to remove.
final class SupportSessionRequest extends SessionRequest {
  final String sessionId;
  final String token;
  final GRASessionInfo? sessionInfo;
  final int? remainingSeconds;

  const SupportSessionRequest({
    required this.sessionId,
    required this.token,
    this.sessionInfo,
    this.remainingSeconds,
  });
}
