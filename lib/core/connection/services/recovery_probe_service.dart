import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// What one probe attempt found.
enum ProbeResult {
  /// The router did not answer, or answered and then failed a step that could
  /// still succeed later. Keep waiting.
  unreachable,

  /// The router is back and the app may keep the session it had.
  recovered,

  /// The router is back and it is not the same router. Only reachable where a
  /// stored fingerprint exists to disagree with — see
  /// [CredentialStrategy.reestablishAfterOutage].
  serialMismatch,
}

/// Probes the router while the app is waiting for it to come back.
///
/// **Deliberately one class taking strategies, not a Local/Remote pair.** The
/// three-step shape — reach it, re-establish, confirm it is the same box — is the
/// same shape in both modes; what differs is what each step *is*. Splitting the
/// service would duplicate the sequencing, the logging and the "a throw means
/// keep waiting" rule, and those two copies would then drift on everything
/// except the lines that actually differ. `mode_contract_roster_test.dart` pins
/// this: a `LocalRecoveryProbeService` turns it red.
///
/// Before #1323 the steps were hard-coded to the local answers, and each one
/// failed differently in Remote Assistance: the health endpoint does not exist on
/// Guardian, the temporary access token cannot be refreshed, and no fingerprint
/// was ever stored — so the probe reported `serialMismatch`, and the caller
/// turned that into a forced logout while the Guardian session was still alive.
class RecoveryProbeService {
  RecoveryProbeService({
    required this.ref,
    required this.transport,
    required this.credential,
  });

  /// Forwarded to the strategies so they can resolve what *they* need — the
  /// bridge, the `UspClient`, the auth coordinator, the fingerprint store. The
  /// service holds none of those: which of them a probe touches is the mode's
  /// answer, and resolving them here is what made the pre-#1323 provider read
  /// `bridge!` and throw a `TypeError` when a session ended mid-probe.
  final Ref ref;

  /// Cause 1 — is the router reachable over this path.
  final TransportStrategy transport;

  /// Cause 2 — may the app keep the session it had.
  final CredentialStrategy credential;

  /// One probe attempt.
  ///
  /// [healthOnly] stops after the reachability step. Used where the router did
  /// not restart and only its web server did (admin password change,
  /// `usp_admin_view.dart`), so re-establishing the credential is the caller's
  /// own next move rather than the probe's.
  Future<ProbeResult> probe({bool healthOnly = false}) async {
    // No try/catch: `isRouterReachable` is contractually non-throwing, because
    // what an exception means differs per path.
    if (!await transport.isRouterReachable(ref)) {
      return ProbeResult.unreachable;
    }

    if (healthOnly) {
      logger.d('[Recovery] Reachable (healthOnly) — recovered');
      return ProbeResult.recovered;
    }

    final bool sameRouter;
    try {
      sameRouter = await credential.reestablishAfterOutage(ref);
    } catch (e) {
      // Both of the old service's separate catch blocks — re-login failed, and
      // serial read failed — landed on `unreachable`, so collapsing them into
      // one changes nothing. A throw is "the box is answering but not yet
      // serving", which is a later retry's problem.
      logger.d('[Recovery] Could not re-establish the session: $e');
      return ProbeResult.unreachable;
    }

    if (!sameRouter) {
      logger.w('[Recovery] Router identity changed');
      return ProbeResult.serialMismatch;
    }

    logger.i('[Recovery] Recovered');
    return ProbeResult.recovered;
  }
}
