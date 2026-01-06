import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/default_country_codes.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/model/region_code.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-export AuthState and LoginType for backward compatibility with existing code
export 'package:privacy_gui/providers/auth/auth_state.dart' show AuthState;
export 'package:privacy_gui/providers/auth/auth_types.dart' show LoginType;

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  // bool _isInit = false;

  AuthNotifier() : super() {
    LinksysHttpClient.onError = (error) async {
      logger.e('Http Response Error: $error');
      if (error is ErrorResponse) {
        // Remote login
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

  /// Lazy-initialized AuthService instance.
  ///
  /// This getter provides access to the AuthService singleton via Riverpod.
  /// It's lazily initialized to avoid issues with the constructor's
  /// LinksysHttpClient.onError setup.
  AuthService get _authService => ref.read(authServiceProvider);

  Future<AuthState?> init() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Validate/refresh session token using AuthService
      final tokenResult = await _authService.validateSessionToken();
      final sessionToken = tokenResult.when(
        success: (token) => token,
        failure: (_) => null, // Token validation failed, continue without it
      );

      // Get all stored credentials using AuthService
      final credsResult = await _authService.getStoredCredentials();
      final creds = credsResult.when(
        success: (c) => c,
        failure: (_) => null, // Failed to get credentials, use defaults
      );

      // Determine login type using AuthService
      final loginTypeResult = await _authService.getStoredLoginType();
      final loginType = loginTypeResult.when(
        success: (type) => type,
        failure: (_) => LoginType.none, // Default to none on failure
      );

      logger.d(
          '[Auth]: Existence: cloud user name: ${creds?.username != null}, cloud pwd: ${creds?.password != null}, admin password: ${creds?.localPassword != null}. Login type = $loginType');

      return AuthState(
        localPasswordHint: state.value?.localPasswordHint,
        username: creds?.username ?? '',
        loginType: loginType,
        sessionToken: sessionToken,
        password: creds?.password,
        localPassword: creds?.localPassword,
      );
    });
    return state.value;
  }

  /// Validates session token by delegating to AuthService.
  ///
  /// This method maintains backward compatibility with existing code that
  /// calls checkSessionToken(). It now delegates to AuthService.
  ///
  /// Returns:
  /// - SessionToken if valid or successfully refreshed
  /// - null if no token exists or validation failed
  ///
  /// Throws:
  /// - NoSessionTokenError if no token exists (for backward compatibility)
  /// - SessionTokenExpiredError if token expired without refresh token
  Future<SessionToken?> checkSessionToken() async {
    final result = await _authService.validateSessionToken();
    return result.when(
      success: (token) {
        if (token == null) {
          throw const NoSessionTokenError();
        }
        return token;
      },
      failure: (error) {
        // For backward compatibility, maintain exception-based flow
        throw const NoSessionTokenError();
      },
    );
  }

  /// Handles session token errors for backward compatibility.
  ///
  /// This method is kept for backward compatibility with the existing
  /// exception-based error handling. New code should use AuthService directly.
  Future<SessionToken?> handleSessionTokenError(
      Object error, StackTrace trace) {
    // Simply return null for all errors - AuthService already handled refresh
    return Future.value(null);
  }

  /// Refreshes token by delegating to AuthService.
  ///
  /// This method maintains backward compatibility while delegating to AuthService.
  Future<SessionToken?> refreshToken(String refreshToken) async {
    final result = await _authService.refreshSessionToken(refreshToken);
    return result.when(
      success: (token) async {
        if (token != null) {
          // Update credentials after successful refresh
          await _authService.updateCloudCredentials(sessionToken: token);
        }
        return token;
      },
      failure: (_) => null,
    );
  }

  /// Performs cloud login auth with GRA session info.
  ///
  /// This method is used for Guardian Remote Assistance authentication.
  /// It delegates credential storage to AuthService.
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

      // Create session token
      final sessionToken = SessionToken(
          accessToken: token,
          tokenType: 'Bearer',
          expiresIn: DateTime.now()
              .add(Duration(seconds: sessionInfo.expiredIn * -1))
              .millisecondsSinceEpoch);

      // Delegate credential storage to AuthService
      await _authService.updateCloudCredentials(sessionToken: sessionToken);

      // Update auth state
      return (state.value ?? AuthState.empty()).copyWith(
        sessionToken: sessionToken,
        loginType: LoginType.remote,
      );
    });
  }

  Future<GRASessionInfo?> testSessionAuthentication(
      {required String token, required String session}) async {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.getSessionInfo(token: token, sessionId: session);
  }

  /// Performs cloud login by delegating to AuthService.
  ///
  /// This method maintains the existing async state management while
  /// delegating business logic to AuthService.
  Future cloudLogin({
    required String username,
    required String password,
    SessionToken? sessionToken,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Delegate to AuthService
      final result = await _authService.cloudLogin(
        username: username,
        password: password,
        sessionToken: sessionToken,
      );

      return result.when(
        success: (loginInfo) {
          // Convert LoginInfo to AuthState
          return AuthState(
            username: loginInfo.username,
            password: loginInfo.password,
            sessionToken: loginInfo.sessionToken,
            loginType: loginInfo.loginType,
            localPasswordHint: state.value?.localPasswordHint,
          );
        },
        failure: (error) {
          // Re-throw error to be caught by AsyncValue.guard
          throw error;
        },
      );
    });
    logger.d('[Auth]: Cloud login done: Auth state = $state');
  }

  /// Performs local login by delegating to AuthService.
  ///
  /// This method maintains the existing async state management while
  /// delegating business logic to AuthService.
  ///
  /// Parameters:
  /// - [password]: Router admin password
  /// - [pnp]: If true, uses PnP-specific JNAP action
  /// - [guardError]: If true, errors are put into state; if false, thrown
  Future localLogin(
    String password, {
    bool pnp = false,
    bool guardError = true,
  }) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Delegate to AuthService
      final result = await _authService.localLogin(password, pnp: pnp);

      return result.when(
        success: (loginInfo) {
          // Convert LoginInfo to AuthState
          return previousState.copyWith(
            localPassword: loginInfo.localPassword,
            loginType: loginInfo.loginType,
          );
        },
        failure: (error) {
          // Re-throw error to be caught by AsyncValue.guard
          throw error;
        },
      );
    }, (error) => guardError);
    logger.d('[Auth]: Local login done: Auth state = $state');
  }

  /// Retrieves password hint by delegating to AuthService.
  ///
  /// This method maintains the existing state management while
  /// delegating business logic to AuthService.
  Future<void> getPasswordHint() async {
    final previousState = state.value;
    if (previousState != null) {
      state = await AsyncValue.guard(() async {
        // Delegate to AuthService
        final result = await _authService.getPasswordHint();

        return result.when(
          success: (hint) {
            return previousState.copyWith(localPasswordHint: hint);
          },
          failure: (error) {
            // Re-throw to be caught by AsyncValue.guard
            throw error;
          },
        );
      });
    }
  }

  /// Retrieves admin password auth status by delegating to AuthService.
  ///
  /// This method maintains backward compatibility while delegating to AuthService.
  Future<Map<String, dynamic>?> getAdminPasswordAuthStatus(
      List<String> services) async {
    final result = await _authService.getAdminPasswordAuthStatus(services);
    return result.when(
      success: (status) => status,
      failure: (_) => null, // Return null on failure for backward compatibility
    );
  }

  Future<void> getDeviceInfo() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository.send(
      JNAPAction.getDeviceInfo,
    );
  }

  /// Performs logout by delegating to AuthService for credential cleanup.
  ///
  /// This method delegates credential clearing to AuthService while maintaining
  /// responsibility for provider state resets and RA session cleanup.
  Future logout() async {
    logger.d('[Prepare]: Logout');
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();

      // Handle RA sessions before clearing credentials
      bool raMode = prefs.getBool(pRAMode) ?? false;
      if (raMode) {
        await ref
            .read(raSessionProvider.notifier)
            .raLogout()
            .onError((error, stackTrace) => null);
        ref.read(raSessionProvider.notifier).stopMonitorSession();
      }

      // Delegate credential cleanup to AuthService
      await _authService.clearAllCredentials();

      // Reset provider states
      ref.read(deviceManagerProvider.notifier).init();
      ref.read(pollingProvider.notifier).init();
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

  /// Performs RA login by delegating to AuthService.
  ///
  /// This method delegates credential storage to AuthService while maintaining
  /// responsibility for network provider and dashboard manager updates.
  Future raLogin(
    String sessionToken,
    String networkId,
    String serialNumber,
  ) async {
    // Update selected network via dashboard manager
    await ref
        .read(dashboardManagerProvider.notifier)
        .saveSelectedNetwork(serialNumber, networkId);

    // Delegate to AuthService
    final result = await _authService.raLogin(
      sessionToken,
      networkId,
      serialNumber,
    );

    // Update state based on result
    state = result.when(
      success: (loginInfo) {
        return AsyncValue.data(AuthState(
          sessionToken: loginInfo.sessionToken,
          loginType: loginInfo.loginType,
          username: state.value?.username,
          password: state.value?.password,
          localPassword: state.value?.localPassword,
          localPasswordHint: state.value?.localPasswordHint,
        ));
      },
      failure: (error) {
        return AsyncValue.error(error, StackTrace.current);
      },
    );
  }
}
