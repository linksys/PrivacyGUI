import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/device_token_store.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_exception.dart';
import 'package:privacy_gui/utils.dart';

enum LoginType { none, local, remote }

class AuthState extends Equatable {
  final String? localPassword;
  final String? localPasswordHint;
  final SessionToken? sessionToken;
  final LoginType loginType;

  const AuthState({
    this.localPassword,
    this.localPasswordHint,
    this.sessionToken,
    required this.loginType,
  });

  factory AuthState.empty() {
    return const AuthState(loginType: LoginType.none);
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    final sessionToken = json['sessionToken'] == null
        ? null
        : SessionToken.fromJson(jsonDecode(json['sessionToken']));
    final loginType =
        LoginType.values.firstWhereOrNull((e) => e.name == json['loginType']) ??
            LoginType.none;
    return AuthState(
      localPassword: json['localPassword'],
      localPasswordHint: json['localPasswordHint'],
      sessionToken: sessionToken,
      loginType: loginType,
    );
  }

  AuthState copyWith({
    String? localPassword,
    String? localPasswordHint,
    SessionToken? sessionToken,
    LoginType? loginType,
  }) {
    return AuthState(
      localPassword: localPassword ?? this.localPassword,
      localPasswordHint: localPasswordHint ?? this.localPasswordHint,
      sessionToken: sessionToken ?? this.sessionToken,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        localPassword,
        localPasswordHint,
        sessionToken,
        loginType,
      ];
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  // Router AI builds only: set by the first init() of this app launch.
  bool _aiStartupReconciled = false;
  int _logoutGeneration = 0;

  /// Moves on at every logout, before the logout changes anything else.
  ///
  /// Work that belongs to a login reads it when the work begins, and asks
  /// [loggedOutSince] before each step that would reach the router (#1904).
  /// [RouterRepository.scheduledCommand] does this for each loop that is
  /// given a generation. In Router AI builds, a bootstrap that began before a
  /// logout never shows the widget after it.
  ///
  /// Where an API takes a generation that may be null, the convention is:
  /// - an entry point that starts work, such as
  ///   `FirmwareUpdateNotifier.fetchAvailableFirmwareUpdates`, reads null as
  ///   the current login;
  /// - [RouterRepository.scheduledCommand], which is handed work already
  ///   under way, reads null as not tied. It cannot tell when that work began,
  ///   so it cannot take the current login for it.
  int get logoutGeneration => _logoutGeneration;

  /// Whether a logout has happened since [generation] was read from
  /// [logoutGeneration]. The one place the two are compared (#1904).
  bool loggedOutSince(int generation) => _logoutGeneration != generation;

  AuthNotifier() : super() {
    LinksysHttpClient.onError = (error) async {
      logger.e('Http Response Error: $error');
      if (error is ErrorResponse) {
        // #1637: the cloud refuses every call made through an ended remote
        // assistance session. Handing it to the session state, not logging out
        // here, keeps the one session-ended flow the top bar already runs.
        if (error.code == errorRemoteSessionExpired) {
          if (state.value?.loginType == LoginType.remote) {
            ref.read(remoteClientProvider.notifier).markSessionExpired();
          }
        }
        // Remote login
        if (error.code == 'INVALID_SESSION_TOKEN') {
          final sessionToken =
              await checkSessionToken().onError(handleSessionTokenError);
          // The message reads "...: <token>". One without a colon names no
          // token, so it cannot match the stored one.
          final parts = error.errorMessage?.split(':') ?? const <String>[];
          final invalidToken = parts.length > 1 ? parts[1].trim() : '';
          if (sessionToken == null ||
              sessionToken.accessToken == invalidToken) {
            logger.f(
                '[Auth]: Force to log out: ${sessionToken == null ? 'Session token is Null' : 'Invalid session token'}');
            logout();
          }
        }
      } else if (error is JNAPError) {
        if (error.result == errorJNAPUnauthorized) {
          final sessionToken =
              await checkSessionToken().onError(handleSessionTokenError);
          if (sessionToken == null) {
            logger.f('[Auth]: Force to log out: Credential is Null in JNAP');
            logout();
          }
        }
      }
    };
  }

  @override
  Future<AuthState> build() => Future.value(AuthState.empty());

  Future<AuthState?> init() async {
    // if (_isInit) {
    //   logger.d(
    //       '[Auth]: auth provider has already been initialized: ${state.value?.loginType}');
    //   return state.value;
    // }
    // _isInit = true;

    state = const AsyncValue.loading();
    // check session token exist and is session token expored
    state = await AsyncValue.guard(() async {
      var loginType = LoginType.none;
      // Refresh token handle
      final sessionToken =
          await checkSessionToken().onError(handleSessionTokenError);
      const storage = FlutterSecureStorage();
      // local password
      final localPassword = await storage.read(key: pLocalPassword);

      if (sessionToken != null) {
        loginType = LoginType.remote;
      } else if (localPassword != null) {
        loginType = LoginType.local;
      }
      logger.d(
          '[Auth]: Existence: admin password: ${localPassword != null}. Login type = $loginType');
      return AuthState(
        localPasswordHint: state.value?.localPasswordHint,
        loginType: loginType,
        sessionToken: sessionToken,
        localPassword: localPassword,
      );
    });
    final restored = state.value;
    // init() runs at startup and again on every router redirect. The AI
    // session is reconciled with the stored login once per app launch: a
    // repeat would re-post the admin password on each navigation and abort
    // the previous request, orphaning server-side sessions. localLogin() and
    // logout() keep the AI session in step after that. The check-and-set has
    // no await, so concurrent startup calls reconcile exactly once.
    if (BuildConfig.enableRouterAi && !_aiStartupReconciled) {
      _aiStartupReconciled = true;
      if (!state.hasError &&
          restored?.loginType == LoginType.local &&
          restored?.localPassword != null) {
        unawaited(_bootstrapAiSession(restored!.localPassword!));
      } else {
        // No restored local login means nothing will bootstrap, so revoke any
        // AI session cookie left by a logout whose revocation never reached
        // the router — otherwise the widget's status poll resurrects the chat
        // and keeps sliding the server idle timeout.
        unawaited(_logoutAiSession());
      }
    }
    return restored;
  }

  Future<SessionToken?> checkSessionToken() async {
    // logger.d(
    //     '[Auth]: Check expiration time for the cloud session token (if it exists)');
    const storage = FlutterSecureStorage();
    final ts = await storage.read(key: pSessionTokenTs);
    final json = await storage.read(key: pSessionToken);
    if (ts == null || json == null) {
      throw NoSessionTokenFoundException();
    }
    final session = SessionToken.fromJson(jsonDecode(json));
    final expireTs = int.parse(ts) + session.expiresIn * 1000;
    final isExpired = expireTs - DateTime.now().millisecondsSinceEpoch < 0;
    logger.d(
        '[Auth]: Token session Ts: $ts, expire Ts: $expireTs. Expired: $isExpired');
    if (isExpired) {
      throw SessionTokenExpiredException();
    }

    return session;
  }

  /// Settles a [checkSessionToken] error as no token. Only the cloud account
  /// login, removed in #1849, stored a token that could be refreshed.
  Future<SessionToken?> handleSessionTokenError(
      Object error, StackTrace trace) {
    return Future.value(null);
  }

  Future cloudLoginAuth(
      {required String token,
      required String sn,
      required GRASessionInfo sessionInfo}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Save nid and sn to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pCurrentSN, sn);
      await prefs.setString(pGRASessionId, sessionInfo.id);
      // Save the new cloud credentials
      return await updateCloudCredientials(
          sessionToken: SessionToken(
              accessToken: token,
              tokenType: 'Bearer',
              expiresIn: DateTime.now()
                  .add(Duration(seconds: sessionInfo.expiredIn.abs()))
                  .millisecondsSinceEpoch));
    });
  }

  Future<GRASessionInfo?> testSessionAuthentication(
      {required String token, required String session}) async {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.getSessionInfo(token: token, sessionId: session);
  }

  Future<AuthState> updateCloudCredientials({
    SessionToken? sessionToken,
  }) async {
    // Whether there is a token, never the token: in debug builds Equatable's
    // toString prints every field, the access and refresh tokens among them.
    logger.d('[Auth]: Update cloud credientials: ${sessionToken != null}');
    const storage = FlutterSecureStorage();
    if (sessionToken != null) {
      await storage.write(
        key: pSessionToken,
        value: jsonEncode(
          sessionToken.toJson(),
        ),
      );
      await storage.write(
        key: pSessionTokenTs,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    // Update the auth state
    return (state.value ?? AuthState.empty()).copyWith(
      sessionToken: sessionToken,
      loginType: LoginType.remote,
    );
  }

  ///
  /// if guardError is true, error will not throw out, instead put into state as error state
  /// else error will throw out.
  ///
  Future localLogin(
    String password, {
    bool pnp = false,
    bool guardError = true,
  }) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final routerRepository = ref.read(routerRepositoryProvider);
      final loginAction = pnp
          ? JNAPAction.pnpCheckAdminPassword
          : JNAPAction.checkAdminPassword;
      final response = await routerRepository.send(
        loginAction,
        // No Basic header on the PnP path. `pnpCheckAdminPassword` resolves to
        // CheckAdminPassword2/3, whose contract is that the candidate password
        // arrives in the body: during PnP there is no session to authorize
        // against, and presenting an unverified password as credentials asks the
        // JNAP layer to reject the request before the action can answer whether
        // the password was right. Do not add the header back without checking
        // that against the minimum supported firmware.
        extraHeaders: pnp
            ? {}
            : {
                kJNAPAuthorization:
                    'Basic ${Utils.stringBase64Encode('admin:$password')}'
              },
        data: {
          'adminPassword': password,
        },
        cacheLevel: CacheLevel.noCache,
      );
      // Check the login result
      if (response.result == jnapResultOk) {
        // Save the new local credentials
        const storage = FlutterSecureStorage();
        await storage.write(key: pLocalPassword, value: password);
        return previousState.copyWith(
          localPassword: password,
          loginType: LoginType.local,
        );
      } else {
        throw response;
      }
    }, (error) => guardError);
    if (BuildConfig.enableRouterAi &&
        !state.hasError &&
        state.value?.loginType == LoginType.local) {
      unawaited(_bootstrapAiSession(password));
    }
    logger.d(
        '[Auth]: Local login done: authenticated=${state.value?.loginType == LoginType.local}');
  }

  Future<void> getPasswordHint() async {
    final previousState = state.value;
    if (previousState != null) {
      state = await AsyncValue.guard(() async {
        final routerRepository = ref.read(routerRepositoryProvider);
        final result = await routerRepository.send(
          JNAPAction.getAdminPasswordHint,
        );
        return previousState.copyWith(
          localPasswordHint: result.output['passwordHint'] ?? '',
        );
      });
    }
  }

  Future<Map<String, dynamic>?> getAdminPasswordAuthStatus(
      List<String> services) async {
    if (serviceHelper.isSupportAdminPasswordAuthStatus(services) != true) {
      return null;
    }
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.getAdminPasswordAuthStatus,
    );
    return result.output;
  }

  Future<void> getDeviceInfo() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository.send(
      JNAPAction.getDeviceInfo,
    );
  }

  Future logout() async {
    logger.d('[Prepare]: Logout');
    // First, before the login is forgotten (#1904). Work tied to the login
    // ends before its next request. Polling stops before a Router AI build
    // empties the auth state below: a poll that ticked while the stores are
    // cleared would go out with the factory default password.
    _logoutGeneration++;
    ref.read(pollingProvider.notifier).stopPolling();
    if (BuildConfig.enableRouterAi) {
      // A logout settles this launch's AI session. If the first init() is
      // still reading storage, it must not bootstrap the old password after
      // this revocation.
      _aiStartupReconciled = true;
      // A widget bundle still downloading must not re-arm itself on the login
      // screen when it finishes.
      ref.read(routerAiDisarmProvider)();
      // Optional server revocation must not delay native logout or retain the
      // previous authenticated state while the endpoint is unavailable.
      unawaited(_logoutAiSession());
      state = AsyncValue.data(AuthState.empty());
    } else {
      state = const AsyncValue.loading();
    }

    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pSelectedNetworkId);
      await prefs.remove(pCurrentSN);
      await prefs.remove(pDeviceToken);
      await prefs.remove(pGRASessionId);
      const storage = FlutterSecureStorage();
      await storage.delete(key: pSessionToken);
      await storage.delete(key: pSessionTokenTs);
      await storage.delete(key: pLocalPassword);
      // The account login (#1849) stored these, and nothing writes them now.
      // Logout still clears what an older install kept.
      await storage.delete(key: pUsername);
      await storage.delete(key: pUserPassword);
      await const DeviceTokenStore().clear();

      ref.read(deviceManagerProvider.notifier).init();
      ref.read(pollingProvider.notifier).init();
      return AuthState.empty();
    });
    // Again: a start-up that was already under way may have started polling
    // while the stores were cleared, in a build that keeps the login until
    // then.
    ref.read(pollingProvider.notifier).stopPolling();
    ref.read(selectedNetworkIdProvider.notifier).state = null;
    // The nodes a firmware install saved belong to this login's router. The
    // next login, maybe to another router, would show them in place of its
    // own (#1904).
    ref.read(firmwareUpdateCandidateProvider.notifier).state = null;
  }

  Future<void> _logoutAiSession() async {
    try {
      await ref.read(aiSessionServiceProvider).logout();
    } catch (_) {
      logger.w('[Auth]: AI session logout was unavailable');
    }
  }

  Future<void> _bootstrapAiSession(String password) async {
    final logoutGeneration = _logoutGeneration;
    try {
      final active =
          await ref.read(aiSessionServiceProvider).bootstrap(password);
      if (!active) {
        logger.w('[Auth]: Instant AI session bootstrap was unavailable');
        return;
      }
      // The widget appears only once the router login and the AI session are
      // both authenticated, never on the login screen. A logout while the
      // bootstrap was in flight normally cancels it (it throws); the
      // generation also covers a logout that lands between the response and
      // this line. It is used instead of the auth state because init() re-runs
      // on every redirect and briefly puts the state into loading.
      if (!loggedOutSince(logoutGeneration)) {
        ref.read(routerAiLoaderProvider)();
      }
    } catch (_) {
      logger.w('[Auth]: Instant AI session bootstrap was unavailable');
    }
  }

  bool isCloudLogin() => state.value?.loginType == LoginType.remote;
}
