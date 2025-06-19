import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/default_country_codes.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/region_code.dart';
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
  final String? username;
  final String? password;
  final String? localPassword;
  final String? localPasswordHint;
  final SessionToken? sessionToken;
  final LoginType loginType;

  const AuthState({
    this.username,
    this.password,
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
      username: json['username'],
      password: json['password'],
      localPassword: json['localPassword'],
      localPasswordHint: json['localPasswordHint'],
      sessionToken: sessionToken,
      loginType: loginType,
    );
  }

  AuthState copyWith({
    String? username,
    String? password,
    String? localPassword,
    String? localPasswordHint,
    SessionToken? sessionToken,
    LoginType? loginType,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      localPassword: localPassword ?? this.localPassword,
      localPasswordHint: localPasswordHint ?? this.localPasswordHint,
      sessionToken: sessionToken ?? this.sessionToken,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        localPassword,
        localPasswordHint,
        sessionToken,
        loginType,
      ];
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  bool _isInit = false;

  AuthNotifier() : super() {
    LinksysHttpClient.onError = (error) async {
      logger.e('Http Response Error: $error');
      if (error is ErrorResponse) {
        if (error.code == 'INVALID_SESSION_TOKEN') {
          final sessionToken =
              await checkSessionToken().onError(handleSessionTokenError);
          final invalidToken = error.errorMessage?.split(':')[1].trim() ?? '';
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
      // cloud username and password
      final username = await storage.read(key: pUsername);
      final password = await storage.read(key: pUserPassword);

      if (sessionToken != null) {
        loginType = LoginType.remote;
      } else if (localPassword != null) {
        loginType = LoginType.local;
      }
      logger.d(
          '[Auth]: Existence: cloud user name: ${username != null}, cloud pwd: ${password != null}, admin password: ${localPassword != null}. Login type = $loginType');
      return AuthState(
        username: username ?? '',
        loginType: loginType,
        sessionToken: sessionToken,
        password: password,
        localPassword: localPassword,
      );
    });
    return state.value;
  }

  Future<SessionToken?> checkSessionToken() async {
    logger.d(
        '[Auth]: Check expiration time for the cloud session token (if it exists)');
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
      final refreshToken = session.refreshToken;
      throw refreshToken == null
          ? SessionTokenExpiredException()
          : NeedToRefreshTokenException(refreshToken);
    }

    return session;
  }

  Future<SessionToken?> handleSessionTokenError(
      Object error, StackTrace trace) {
    if (error is NeedToRefreshTokenException) {
      logger.e('[Auth]: Start to refresh session token');
      return refreshToken(error.refreshToken);
    } else {
      // not handling at this moment
      logger.e('[Auth]: Unhandled session token error: $error');
      return Future.value(null);
    }
  }

  Future<SessionToken?> refreshToken(String refreshToken) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.refreshToken(refreshToken).then((value) async {
      logger.e('[Auth]: Session token refreshed successfully');
      await updateCloudCredientials(sessionToken: value);
      return value;
    });
  }

  Future cloudLogin({
    required String username,
    required String password,
    SessionToken? sessionToken,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cloud = ref.read(cloudRepositoryProvider);
      final newToken = sessionToken ??
          await cloud.login(username: username, password: password);
      // Save the new cloud credentials
      return await updateCloudCredientials(
        sessionToken: newToken,
        username: username,
        password: password,
      );
    });
    logger.d('[Auth]: Cloud login done: Auth state = $state');
  }

  Future<AuthState> updateCloudCredientials({
    SessionToken? sessionToken,
    String? username,
    String? password,
  }) async {
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
    if (username != null) {}
    if (password != null) {
      await storage.write(
        key: pUserPassword,
        value: password,
      );
    }
    // Update the auth state
    return (state.value ?? AuthState.empty()).copyWith(
      sessionToken: sessionToken,
      username: username,
      password: password,
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
      final response = await routerRepository.send(
        pnp ? JNAPAction.pnpCheckAdminPassword : JNAPAction.checkAdminPassword,
        // extraHeaders: pnp
        //     ? {
        //         kJNAPAuthorization:
        //             'Basic ${Utils.stringBase64Encode('admin:$password')}'
        //       }
        //     : {},
        extraHeaders: {
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
        // store encrypt local password to shared preferences
        final key = 'adminPassword'.padRight(32, '-'); // 32
        final iv = 'admin'.padRight(16, '-'); // 16
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'encryptLocalPassword', Utils.encryptAES(password, key, iv));

        return previousState.copyWith(
          localPassword: password,
          loginType: LoginType.local,
        );
      } else {
        throw response;
      }
    }, (error) => guardError);
    logger.d('[Auth]: Local login done: Auth state = $state');
  }

  Future<void> getPasswordHint() async {
    final previousState = state.value;
    if (previousState != null) {
      state = const AsyncValue.loading();
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
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pSelectedNetworkId);
      await prefs.remove(pCurrentSN);
      await prefs.remove(pDeviceToken);
      await prefs.remove('encryptLocalPassword');
      const storage = FlutterSecureStorage();
      await storage.delete(key: pSessionToken);
      await storage.delete(key: pSessionTokenTs);
      await storage.delete(key: pLocalPassword);
      await storage.delete(key: pUsername);
      await storage.delete(key: pUserPassword);
      await storage.delete(key: pLinksysToken);
      await storage.delete(key: pLinksysTokenTs);

      // RA sessions
      bool raMode = prefs.getBool(pRAMode) ?? false;
      if (raMode) {
        await ref
            .read(raSessionProvider.notifier)
            .raLogout()
            .onError((error, stackTrace) => null);
        ref.read(raSessionProvider.notifier).stopMonitorSession();
      }
      return AuthState.empty();
    });
    ref.read(pollingProvider.notifier).stopPolling();
    ref.read(selectedNetworkIdProvider.notifier).state = null;
  }

  bool isCloudLogin() => state.value?.loginType == LoginType.remote;

  // TODO refactor
  Future<List<RegionCode>> fetchRegionCodes() async {
    List<RegionCode> regions = [];
    var countryCodeJson = defaultCountryCodes;
    if (countryCodeJson.containsKey('countryCodes')) {
      final jsonArray = countryCodeJson['countryCodes'] as List<dynamic>;
      regions = List.from(jsonArray.map((e) => RegionCode.fromJson(e)));
    }
    return regions;
  }

  Future raLogin(
    String sessionToken,
    String networkId,
    String serialNumber,
  ) async {
    // update selected network id provider
    // update network id and sn to prefs
    await ref
        .read(dashboardManagerProvider.notifier)
        .saveSelectedNetwork(serialNumber, networkId);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(pRAMode, true);

    // Update credientials
    state = AsyncValue.data(await updateCloudCredientials(
        sessionToken: SessionToken(
            accessToken: sessionToken,
            tokenType: 'Bearer',
            expiresIn: DateTime.now().millisecondsSinceEpoch)));
  }
}
