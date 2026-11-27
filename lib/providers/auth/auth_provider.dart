import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-export AuthState and LoginType for backward compatibility with existing code
export 'package:privacy_gui/providers/auth/auth_state.dart' show AuthState;
export 'package:privacy_gui/providers/auth/auth_types.dart' show LoginType;

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  Completer<AuthState?>? _initInProgress;

  /// The teardown in flight, if any; see [logout].
  Future<void>? _logoutInProgress;

  /// Why the most recent session ended: the [EndCause] of the [logout] that
  /// ran its teardown (the first caller's, when others joined it). Set when the
  /// teardown starts and kept after it, until the next one.
  ///
  /// For a surface that must tell "the session was lost" from "the user left"
  /// once the state reads signed out — the PnP shell, whose routes the login
  /// redirect passes through (#1666).
  EndCause? get lastEndCause => _lastEndCause;
  EndCause? _lastEndCause;

  @override
  Future<AuthState> build() => Future.value(AuthState.empty());

  AuthService get _authService => ref.read(authServiceProvider);

  Future<AuthState?> init() async {
    // Coalesce concurrent init calls — return in-flight result if one exists
    if (_initInProgress != null) {
      logger.d('[Auth]: init already in progress, awaiting...');
      return _initInProgress!.future;
    }

    _initInProgress = Completer<AuthState?>();
    try {
      // Note: Do NOT set `state = AsyncValue.loading()` synchronously here.
      // This method can be called during initState/widget mount, and a
      // synchronous state change would trigger provider notifications that
      // cause a !_dirty assertion in ProviderScope.
      state = await AsyncValue.guard(() async {
        // Try to restore USP session from stored token (sessionStorage).
        // restoreSession() ends nothing (#1666): a token it cannot restore
        // leaves the user signed out, which is the answer below.
        final coordinator = ref.read(uspAuthCoordinatorProvider);
        await coordinator.restoreSession();

        // Determine login type based on whether session was restored
        final isAuthenticated =
            ref.read(uspClientProvider)?.isAuthenticated ?? false;
        final loginType = isAuthenticated ? LoginType.local : LoginType.none;

        logger.d('[Auth]init: isAuthenticated=$isAuthenticated, '
            'loginType=$loginType');

        // A restored session begins — but only if none is live. `init()` also
        // runs from the `/` and `/localLoginPassword` redirects and from the
        // login view, so a user who presses Back to the login URL reaches here
        // in the middle of a session, with the same token: beginning again
        // would make every request already in flight read as a superseded
        // session's, its 401 neither retried nor ending anything.
        if (loginType == LoginType.local) {
          final gate = ref.read(sessionAuthGateProvider);
          if (!gate.isLive) gate.begin();
        }

        return AuthState(
          localPasswordHint: state.value?.localPasswordHint,
          loginType: loginType,
        );
      });
      // AsyncValue.guard never throws — it converts errors to AsyncError.
      // Propagate error to concurrent waiters if the guard failed.
      // Note: Do NOT rethrow here — callers (app.dart, router_provider.dart)
      // use bare .then() without .catchError, so throwing would leave the
      // splash screen stuck or break the redirect.
      if (state case AsyncError(:final error, :final stackTrace)) {
        _initInProgress!.completeError(error, stackTrace);
        return null;
      }
      _initInProgress!.complete(state.value);
      return state.value;
    } finally {
      _initInProgress = null;
    }
  }

  /// Open a session for whatever mode this build is in.
  ///
  /// **The entry funnel, mirroring [logout] as the exit funnel.** Both directions of
  /// cause 3 are consumed here and nowhere else, which is what keeps the two
  /// implementations of `SessionStrategy.start()` reachable from exactly one place
  /// each without either call site knowing which mode it is in.
  ///
  /// This method exists rather than the callers reading the profile themselves for a
  /// mechanical reason worth recording: `start` takes a riverpod `Ref`, and the
  /// remote caller is a widget holding a `WidgetRef` — the two have no common
  /// supertype in riverpod 2.x. A notifier is the nearest thing that has a real
  /// `Ref`, and this notifier is the one whose state the operation ends up changing
  /// in both modes (locally via [localLogin] below, remotely via the
  /// [setLoginType] that `activate()` calls).
  ///
  /// Mode-agnostic on purpose: it takes a [SessionRequest] and forwards it. A second
  /// method per mode here would put back exactly the branching #1474 removes.
  Future<void> openSession(SessionRequest request) =>
      ref.read(appModeProfileProvider).session.start(ref, request);

  /// Performs local login via USP.
  ///
  /// Password is used for authentication only — never stored.
  /// Session token is persisted by [UspAuthCoordinator] for page reload recovery.
  ///
  /// The two steps that *open* the session moved to `SessionStrategy.start()` in
  /// #1474 phase 9 — USP login, then device info while auth stays in loading so
  /// GoRouter cannot navigate before the fingerprint is ready. What stays here is
  /// the part that is the same in every mode: the loading/data/error state machine,
  /// the [guardError] escape hatch and the `ServiceError` translation.
  ///
  /// This method keeps its name and its local-only callers. It is not the remote
  /// entry under another name: the agent's session is opened by the confirm view,
  /// which has its own error surface and its own state machine, and reaches the
  /// same contract through [openSession].
  Future localLogin(
    String password, {
    bool guardError = true,
  }) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    try {
      await openSession(OwnCredentialsRequest(password));

      // A new credential: a new session, even if one was live — the requests
      // still in flight carry the old token, and their 401s must not end this
      // one (#1666).
      ref.read(sessionAuthGateProvider).begin();
      state = AsyncValue.data(previousState.copyWith(
        loginType: LoginType.local,
      ));
    } catch (e, st) {
      if (guardError) {
        // Map ServiceError to UnexpectedError with error code for View layer
        final viewError = _mapToViewError(e);
        state = AsyncValue.error(viewError, st);
      } else {
        rethrow;
      }
    }
    logger.d('[Auth]: localLogin: done, state=$state');
  }

  /// Maps ServiceError to UnexpectedError with proper error code for View layer.
  ServiceError _mapToViewError(Object error) {
    // Passthrough: the coordinator may already have produced an UnexpectedError
    // carrying an error-code identifier in `detail` (e.g. account-locked). Don't
    // overwrite it with the generic errorUnexpected below — keep it so the login
    // view's errorCodeHelper can resolve the specific message.
    if (error is UnexpectedError && error.detail == errorAdminAccountLocked) {
      return error;
    }
    if (error is InvalidCredentialsError) {
      return UnexpectedError(
        detail: errorInvalidAdminPassword,
        originalError: error,
      );
    }
    if (error is NetworkError) {
      return UnexpectedError(
        detail: errorUspNetworkError,
        originalError: error,
      );
    }
    if (error is ServiceNotInitializedError) {
      return UnexpectedError(
        detail: errorUspServiceNotInitialized,
        originalError: error,
      );
    }
    if (error is ServiceError) {
      return UnexpectedError(
        detail: errorUnexpected,
        originalError: error,
      );
    }
    return UnexpectedError(
      detail: errorUnexpected,
      originalError: error,
    );
  }

  /// Sets the login type directly without performing login.
  /// Used by Remote Assistance mode to set LoginType.remote.
  void setLoginType(LoginType type) {
    final previousState = state.value ?? AuthState.empty();
    state = AsyncValue.data(previousState.copyWith(loginType: type));
    logger.d('[Auth]: setLoginType: $type');
  }

  /// Retrieves password hint from the router.
  ///
  /// TODO: Re-implement using USP when available.
  Future<void> getPasswordHint() async {
    // No-op: password hint not available in USP-only mode
  }

  /// Retrieves admin password auth status from the router.
  ///
  /// TODO: Re-implement using USP when available.
  Future<Map<String, dynamic>?> getAdminPasswordAuthStatus() async {
    // No-op: not available in USP-only mode
    return null;
  }

  /// Performs logout, clearing credentials and resetting state.
  ///
  /// **The one funnel every session ending goes through**, which since #1323
  /// (phase 5) includes the mode's own teardown: eleven call sites reach this
  /// method and all of them now get `SessionStrategy.end` for free. Before that,
  /// Remote Assistance teardown — releasing the Guardian session and clearing
  /// `remoteAccessProvider` — lived in `remote_session_chip.dart`'s Disconnect
  /// handler alone, so the other ten paths (idle timeout, 401 on the bridge, SSE
  /// give-up, serial mismatch, factory reset, a failed relogin, …) left
  /// `sessionInfo` and `sessionToken` populated. `router_provider.dart`'s `/usp*`
  /// guard reads exactly those two and redirects to the confirm page with them,
  /// so an RA logout bounced the user back into the session they had just left
  /// (#1323 acceptance 3).
  ///
  /// [cause] defaults to [EndCause.sessionLost] because that is the majority — 8
  /// of the 11 sites are automatic — and because the failure modes are asymmetric:
  /// a missed `endSessionForCA` leaves a Guardian session to expire on its own
  /// timer, whereas an *attempted* one on a rejected token is a guaranteed failure
  /// on the commonest path. The three button handlers pass
  /// [EndCause.userRequested] explicitly.
  ///
  /// **One teardown at a time.** A logout asked for while one is running joins
  /// it and returns when it finishes, rather than starting a second. The
  /// teardown itself makes requests with the credential it is ending, and any
  /// of them can answer 401 — which the bridge reports by calling this method.
  /// Unguarded, that closed a loop on QA Guardian (2026-09-30): every teardown
  /// disconnected SSE, the remote disconnect cleanup read `/subscriptions`, the
  /// 401 asked for another logout, 770 times in four minutes. The first
  /// caller's [cause] stands, because it is the one that decided whether
  /// Guardian was told the session ended.
  ///
  /// **The session is marked ended first, for every cause (#1666).** From then
  /// on a 401 on any request for it — the teardown's own, a fire-and-forget
  /// cleanup that outlives it — is ignored by [sessionAuthGateProvider] until
  /// the next session begins. That is the guard against a second logout from a
  /// 401; [_logoutInProgress] below only lets a concurrent caller await the
  /// teardown already running.
  Future logout({EndCause cause = EndCause.sessionLost}) {
    ref.read(sessionAuthGateProvider).markEnded();
    final running = _logoutInProgress;
    if (running != null) {
      logger.d('[Auth]: logout: already in progress (cause: ${cause.name}) '
          '— joining it');
      return running;
    }
    _lastEndCause = cause;
    final teardown = _logout(cause);
    _logoutInProgress = teardown;
    return teardown.whenComplete(() => _logoutInProgress = null);
  }

  Future<void> _logout(EndCause cause) async {
    logger.d('[Auth]: logout: starting (cause: ${cause.name})');
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // The mode's own teardown goes FIRST: a Guardian call needs the token the
      // rest of this method is about to invalidate. Contractually non-throwing —
      // see SessionStrategy.end — because a throw inside this guard would leave
      // authProvider in an error state with the credential still present.
      await ref.read(appModeProfileProvider).session.end(ref, cause);

      // Disconnect SSE BEFORE USP logout: the disconnect ends the session's
      // subscriptions, and the remote strategy's cleanup of them on Guardian
      // is sent with this session's token. It is fire-and-forget, so this
      // only starts it while the token is still good; it may finish after the
      // logout. There is no separate unregister step: the disconnect has
      // already forgotten every subscription, so an `unregisterAll()` after it
      // had nothing left to send.
      final sseManager = ref.read(sseManagerProvider);
      if (sseManager != null) {
        logger.d('[Auth]: logout: disconnecting SSE');
        await sseManager.disconnect();
      }

      // Now safe to logout USP
      logger.d('[Auth]: logout: syncing USP logout');
      await ref.read(uspAuthCoordinatorProvider).syncAfterLogout();

      // Clear router fingerprint
      await ref.read(routerFingerprintServiceProvider).clear();

      // Clear credentials
      logger.d('[Auth]: logout: clearing credentials');
      await _authService.clearAllCredentials();

      // Clear RA-related prefs (legacy cleanup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pSelectedNetworkId);
      await prefs.remove(pCurrentSN);

      // Reset provider states
      ref.read(sessionProvider.notifier).clear();
      logger.d('[Auth]: logout: complete');
      return AuthState.empty();
    });
    ref.read(selectedNetworkIdProvider.notifier).state = null;
  }
}
