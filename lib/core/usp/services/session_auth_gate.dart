import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'sse_operation_strategy.dart' show AuthBehavior;

/// Which session a request, a refresh or a poll was made for (#1666).
///
/// Taken **where the credential is read**, so that it names the credential the
/// work was sent with:
/// - `UspClient` reads the session token per request, so it takes the ticket
///   when a request starts;
/// - a reauth and a heartbeat refresh each take one when they start, and report
///   with it.
///
/// The bridge and the Remote Assistance poll follow the same rule: the local
/// bridge per request (it reads the client's token), the remote bridge at
/// construction (Guardian's token is fixed then), the poll when it starts.
///
/// A ticket that is no longer [SessionAuthGate.ticket] belongs to a session that
/// has been replaced, and nothing it reports can end the session that replaced
/// it.
@immutable
class SessionTicket {
  const SessionTicket._(this._epoch);

  final int _epoch;

  @override
  bool operator ==(Object other) =>
      other is SessionTicket && other._epoch == _epoch;

  @override
  int get hashCode => _epoch.hashCode;

  @override
  String toString() => 'SessionTicket($_epoch)';
}

/// How much a 401 on a request is allowed to decide.
enum RequestKind {
  /// The request's answer matters: a 401 means what the mode says it means.
  normal,

  /// Nothing depends on the answer, such as a health probe. A 401 is the
  /// caller's to swallow: no retry, and the session is not ended.
  bestEffort,
}

/// What a 401 means for the request that got it.
enum AuthDecision {
  /// The credential can be refreshed: reauthenticate, then send it once more.
  retry,

  /// The credential is gone and cannot be refreshed: end the session
  /// ([SessionAuthGate.end]), and fail the request.
  end,

  /// The 401 says nothing about the current session: fail the request and
  /// change nothing else.
  ignore,
}

enum _EpochState { none, live, ended }

/// Decides what a 401 does to the session (#1666), for every path that can see
/// one: `UspClient`'s commands, the heartbeat refresh, the session restore, the
/// bridge's REST requests and notification stream, and the Remote Assistance
/// session poll.
///
/// Before, five places decided it, each with its own subset of the rules:
/// `UspClient`, `UspAuthCoordinator`, the bridge's REST and SSE handling, and
/// the Remote Assistance poll. Two of them could never fire, because each was
/// written against a different idea of what the WASM client reports.
///
/// **Session epoch.** [begin] starts one, when a credential is obtained or
/// replaced. It is **live** until it ends, which happens once: either the gate
/// [end]s it, or `logout()` calls [markEnded], for any cause. It then stays
/// **ended** until the next [begin]. Before the first [begin] there is **none**.
///
/// | Ticket / state        | local, normal | remote, normal | bestEffort |
/// |-----------------------|---------------|----------------|------------|
/// | not the current one   | ignore        | ignore         | ignore     |
/// | none yet              | retry         | ignore         | ignore     |
/// | live                  | retry         | end            | ignore     |
/// | ended                 | ignore        | ignore         | ignore     |
///
/// "Ended" ignoring everything is what keeps a session's own teardown from
/// asking for another one, and why a late cleanup request (a fire-and-forget
/// unsubscribe that outlives the logout) cannot start a second teardown either.
///
/// Plain Dart on purpose: no Riverpod, no web. The mode's answer arrives as
/// [AuthBehavior] (from `CredentialStrategy.authBehavior`), and ending the
/// session is a callback, so the whole decision is testable on the VM through
/// this interface.
class SessionAuthGate {
  SessionAuthGate({
    required AuthBehavior authBehavior,
    required VoidCallback endSession,
  })  : _authBehavior = authBehavior,
        _endSession = endSession;

  static const _tag = '[USP][Auth]:';

  final AuthBehavior _authBehavior;
  final VoidCallback _endSession;

  int _epoch = 0;
  _EpochState _state = _EpochState.none;

  /// The current session's ticket. Before the first [begin], the ticket of
  /// "no session yet".
  SessionTicket get ticket => SessionTicket._(_epoch);

  /// Whether a session is live: begun and not ended.
  bool get isLive => _state == _EpochState.live;

  /// Whether the current session has ended and no new one has begun.
  bool get hasEnded => _state == _EpochState.ended;

  /// A credential was obtained or replaced: a new session begins.
  ///
  /// Every ticket taken before this call is superseded from now on, including a
  /// live session's. A caller that may run during a live session with the
  /// **same** credential (a page reload's restore reached again from a
  /// redirect) checks [isLive] first.
  void begin() {
    _epoch++;
    _state = _EpochState.live;
    logger.d('$_tag session ${ticket._epoch} begins');
  }

  /// `logout()` is ending the session, for whatever cause. A no-op unless one
  /// is live.
  void markEnded() {
    if (_state != _EpochState.live) return;
    _state = _EpochState.ended;
    logger.d('$_tag session ${ticket._epoch} ends');
  }

  /// What a 401 on a request sent with [ticket] means. Decides only; the
  /// caller acts on the answer, and an [AuthDecision.end] goes to [end].
  AuthDecision decideOn401(
    SessionTicket ticket, {
    RequestKind kind = RequestKind.normal,
  }) {
    if (ticket != this.ticket) return AuthDecision.ignore;
    if (kind == RequestKind.bestEffort) return AuthDecision.ignore;
    final canRefresh = _authBehavior.shouldRetryOnFailure;
    return switch (_state) {
      _EpochState.ended => AuthDecision.ignore,
      _EpochState.none => canRefresh ? AuthDecision.retry : AuthDecision.ignore,
      _EpochState.live => canRefresh ? AuthDecision.retry : AuthDecision.end,
    };
  }

  /// Ends the session [ticket] names: the credential it was sent with has been
  /// rejected and cannot be recovered.
  ///
  /// Only the live session, and only once. A superseded ticket, a session
  /// already ended and "no session yet" change nothing. A throwing
  /// `endSession` is logged and swallowed, so the caller still gets to report
  /// its own failure.
  void end(SessionTicket ticket) {
    if (ticket != this.ticket) {
      logger.d('$_tag a superseded session asked to end — ignored');
      return;
    }
    if (_state != _EpochState.live) return;
    _state = _EpochState.ended;
    logger.w('$_tag session ${ticket._epoch} credential rejected — ending it');
    try {
      _endSession();
    } catch (e) {
      logger.w('$_tag ending the session failed: $e');
    }
  }
}
