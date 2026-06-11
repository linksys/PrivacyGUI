import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-export AuthState and LoginType for backward compatibility with existing code
export 'package:privacy_gui/providers/auth/auth_state.dart' show AuthState;
export 'package:privacy_gui/providers/auth/auth_types.dart' show LoginType;

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => Future.value(AuthState.empty());

  AuthService get _authService => ref.read(authServiceProvider);

  Future<AuthState?> init() async {
    // Note: Do NOT set `state = AsyncValue.loading()` synchronously here.
    // This method can be called during initState/widget mount, and a
    // synchronous state change would trigger provider notifications that
    // cause a !_dirty assertion in ProviderScope.
    state = await AsyncValue.guard(() async {
      // Determine login type from stored credentials
      final loginTypeResult = await _authService.getStoredLoginType();
      final loginType = loginTypeResult.when(
        success: (type) => type,
        failure: (_) => LoginType.none,
      );

      // Get stored local password
      final passwordResult = await _authService.getStoredLocalPassword();
      final localPassword = passwordResult.when(
        success: (p) => p,
        failure: (_) => null,
      );

      logger.d(
          '[Auth]init: hasPassword=${localPassword != null}, loginType=$loginType');

      // Restore USP session on page reload / app restart (local login only)
      if (loginType == LoginType.local) {
        await ref.read(uspAuthCoordinatorProvider).restoreSession();
      }

      return AuthState(
        localPasswordHint: state.value?.localPasswordHint,
        loginType: loginType,
        localPassword: localPassword,
      );
    });
    return state.value;
  }

  /// Performs local login via USP.
  Future localLogin(
    String password, {
    bool guardError = true,
  }) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    try {
      final uspCoordinator = ref.read(uspAuthCoordinatorProvider);
      final uspSuccess = await uspCoordinator.tryUspLogin(password);
      if (!uspSuccess) throw Exception('USP login failed');

      await const FlutterSecureStorage()
          .write(key: pLocalPassword, value: password);
      logger.d('[Auth]: localLogin: USP login succeeded');

      // Fetch device info and store fingerprint while auth stays in loading —
      // prevents GoRouter from navigating before fingerprint is ready.
      await ref
          .read(sessionProvider.notifier)
          .fetchDeviceInfoAndInitializeServices();

      state = AsyncValue.data(previousState.copyWith(
        localPassword: password,
        loginType: LoginType.local,
      ));
    } catch (e, st) {
      if (guardError) {
        state = AsyncValue.error(e, st);
      } else {
        rethrow;
      }
    }
    logger.d('[Auth]: localLogin: done, state=$state');
  }

  /// Persists local credentials without attempting USP login.
  ///
  /// Use this when the USP session is already established (e.g., PnP flow)
  /// and you only need to save credentials for future session restore.
  Future<void> persistLocalCredentials(String password) async {
    final previousState = state.value ?? AuthState.empty();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Store password for session restore
      await const FlutterSecureStorage()
          .write(key: pLocalPassword, value: password);
      logger.d('[Auth]: persistLocalCredentials: credentials saved');
      return previousState.copyWith(
        localPassword: password,
        loginType: LoginType.local,
      );
    });
    logger.d('[Auth]: persistLocalCredentials: done, state=$state');
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
  Future logout() async {
    logger.d('[Auth]: logout: starting');
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Disconnect SSE and unregister subscriptions BEFORE USP logout —
      // subscription cleanup uses authenticated requests, so the token
      // must still be valid.
      final sseManager = ref.read(sseManagerProvider);
      if (sseManager != null) {
        logger.d('[Auth]: logout: disconnecting SSE');
        await sseManager.disconnect();
        await sseManager.registry.unregisterAll();
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
