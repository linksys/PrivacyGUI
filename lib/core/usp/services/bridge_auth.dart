import 'package:privacy_gui/core/utils/logger.dart';

import 'session_auth_gate.dart';

/// The token a bridge request is sent with, and the session that token
/// belongs to (#1666).
///
/// Read together, because a ticket is taken where the credential is read:
/// - **A fixed token** (Remote Assistance: Guardian's `temporaryAccessToken`,
///   given at construction). The ticket is the session that was live then.
///   After a re-activation, the old bridge, still disposing, carries the old
///   session's ticket, so its 401s cannot end the session that replaced it
///   (`721939aa8`).
/// - **The client's token** (local: read per request). The ticket is read at
///   the same moment, so a local bridge, built once per tab, follows every
///   session in it.
///
/// Platform-neutral, so the rule is tested on the VM; the bridge itself is
/// web-only.
class BridgeCredential {
  BridgeCredential({
    String? fixedToken,
    required String? Function() sessionToken,
    required SessionAuthGate gate,
  })  : _fixedToken = fixedToken,
        _sessionToken = sessionToken,
        _gate = gate,
        _fixedTicket = fixedToken == null ? null : gate.ticket;

  final String? _fixedToken;
  final String? Function() _sessionToken;
  final SessionAuthGate _gate;
  final SessionTicket? _fixedTicket;

  /// The token to send now, and the session it names. Throws [StateError]
  /// when there is no fixed token and the client holds none.
  ({String token, SessionTicket ticket}) read() {
    final fixed = _fixedToken;
    if (fixed != null) return (token: fixed, ticket: _fixedTicket!);
    final token = _sessionToken();
    if (token == null) {
      throw StateError('Session token not available. '
          'Ensure the WASM client exports sessionToken() and login is complete.');
    }
    return (token: token, ticket: _gate.ticket);
  }
}

/// Whether a bridge request answered 401 should be sent again (#1666). Decides
/// through [gate], with the [ticket] the request was sent with, and acts:
///
/// - **retry** (a local session, a request that matters): [reauth], then send
///   once more. If the resent request is answered 401 too (the credential was
///   refreshed and the router still refuses it), the session ends. A reauth
///   that fails ends nothing more here: `UspClient.reauth` has already ended
///   the session if the router refused the token, and a router it could not
///   reach says nothing about the credential.
/// - **end** (a Remote Assistance token cannot be refreshed): the session
///   ends.
/// - **ignore** (a session that is over or not this one, or a
///   [RequestKind.bestEffort] request): nothing.
///
/// Returns true only when the request should be sent again. [resent] says the
/// 401 answered a request already sent again.
Future<bool> resendAfter401({
  required SessionAuthGate gate,
  required SessionTicket ticket,
  required bool resent,
  required Future<void> Function() reauth,
  RequestKind kind = RequestKind.normal,
}) async {
  switch (gate.decideOn401(ticket, kind: kind)) {
    case AuthDecision.ignore:
      return false;
    case AuthDecision.end:
      gate.end(ticket);
      return false;
    case AuthDecision.retry:
      if (resent) {
        gate.end(ticket);
        return false;
      }
      try {
        await reauth();
        return true;
      } catch (e) {
        logger.w('[USP][Auth]: reauth after a bridge 401 failed: $e');
        return false;
      }
  }
}
