// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/constants/default_country_codes.dart';
import 'package:linksys_app/constants/error_code.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/core/cloud/model/region_code.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/providers/auth/auth_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginType { none, local, remote }

class AuthState extends Equatable {
  final String? username;
  final String? password;
  final String? localPassword;
  final SessionToken? sessionToken;
  final LoginType loginType;

  const AuthState({
    this.username,
    this.password,
    this.localPassword,
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
      sessionToken: sessionToken,
      loginType: loginType,
    );
  }

  AuthState copyWith({
    String? username,
    String? password,
    String? localPassword,
    SessionToken? sessionToken,
    LoginType? loginType,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      localPassword: localPassword ?? this.localPassword,
      sessionToken: sessionToken ?? this.sessionToken,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        localPassword,
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
      logger.d('Http Response Error: $error');
      if (error is ErrorResponse) {
        if (error.code == 'INVALID_SESSION_TOKEN') {
          final sessionToken =
              await checkSessionToken().onError(handleSessionTokenError);
          final invalidToken = error.errorMessage?.split(':')[1].trim() ?? '';
          if (sessionToken == null ||
              sessionToken.accessToken == invalidToken) {
            logout();
          }
        }
      } else if (error is JNAPError) {
        if (error.result == errorJNAPUnauthorized) {
          final sessionToken =
              await checkSessionToken().onError(handleSessionTokenError);
          if (sessionToken == null) {
            logout();
          }
        }
      }
    };
  }

  @override
  Future<AuthState> build() => Future.value(AuthState.empty());

  Future<AuthState?> init() async {
    if (_isInit) {
      logger.d('auth provider has been inited');
      return state.value;
    }
    _isInit = true;

    state = const AsyncValue.loading();
    // check session token exist and is session token expored

    state = await AsyncValue.guard(() async {
      var loginType = LoginType.none;

      // Refresh token handle
      final sessionToken =
          await checkSessionToken().onError(handleSessionTokenError);

      logger.d('check local password...');
      const storage = FlutterSecureStorage();

      // check local password
      final localPassword = await storage.read(key: pLocalPassword);

      logger.d('check cloud credientials...');
      // check cloud username and password
      final username = await storage.read(key: pUsername);
      final password = await storage.read(key: pUserPassword);

      logger.d('check login type...');
      if (sessionToken != null) {
        loginType = LoginType.remote;
      } else if (localPassword != null) {
        loginType = LoginType.local;
      }

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
    logger.d('check cloud session expiration...');
    const storage = FlutterSecureStorage();
    final ts = await storage.read(key: pSessionTokenTs);
    final json = await storage.read(key: pSessionToken);
    if (ts == null || json == null) {
      throw NoSessionTokenFoundException();
    }
    final session = SessionToken.fromJson(jsonDecode(json));
    final expireTs = int.parse(ts) + session.expiresIn * 1000;
    logger.d('sessionTs: $ts, expireTs: $expireTs');
    if (expireTs - DateTime.now().millisecondsSinceEpoch < 0) {
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
      logger.d('refresh token...');
      return refreshToken(error.refreshToken);
    } else {
      // not handling at this moment
      return Future.value(null);
    }
  }

  Future<SessionToken?> refreshToken(String refreshToken) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.refreshToken(refreshToken).then((value) async {
      await updateCredientials(sessionToken: value);
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

      return await updateCredientials(
        sessionToken: newToken,
        username: username,
        password: password,
      );
    });
    logger.d('after cloud login: $state');
  }

  Future<AuthState> updateCredientials({
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

    return (state.value ?? AuthState.empty()).copyWith(
      sessionToken: sessionToken,
      username: username,
      password: password,
      loginType: LoginType.remote,
    );
  }

  Future localLogin(String password) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final routerRepository = ref.read(routerRepositoryProvider);
      final response = await routerRepository.send(
        JNAPAction.checkAdminPassword,
        data: {
          'adminPassword': password,
        },
      );
      if (response.result == jnapResultOk) {
        const storage = FlutterSecureStorage();
        await storage.write(key: pLocalPassword, value: password);
        return previousState.copyWith(
          localPassword: password,
          loginType: LoginType.local,
        );
      } else {
        throw response;
      }
    });
  }

  Future getAdminPasswordInfo() async {
    final routerRepository = ref.read(routerRepositoryProvider);

    return await routerRepository
        .send(JNAPAction.getAdminPasswordHint)
        .then((value) => value.output['passwordHint'] ?? '');
  }

  // TODO
  Future<void> createAdminPassword(String password, String hint) async {
    // final repo = ref.read(routerRepositoryProvider);
    // await repo.createAdminPassword('admin', hint);
  }

  Future logout() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pSelectedNetworkId);
      await prefs.remove(pCurrentSN);
      await prefs.remove(pDeviceToken);
      const storage = FlutterSecureStorage();
      await storage.delete(key: pSessionToken);
      await storage.delete(key: pSessionTokenTs);
      await storage.delete(key: pLocalPassword);
      await storage.delete(key: pUsername);
      await storage.delete(key: pUserPassword);
      return AuthState.empty();
    });
    ref.read(pollingProvider.notifier).stopPolling();
    ref.read(selectedNetworkIdProvider.notifier).state = null;
    //TODO: XXXXXX Clear state of managers
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
}
