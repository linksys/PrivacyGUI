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
    state = await AsyncValue.guard(() async {
      final uspCoordinator = ref.read(uspAuthCoordinatorProvider);
      final uspSuccess = await uspCoordinator.tryUspLogin(password);
      if (uspSuccess) {
        // Store password for session restore
        await const FlutterSecureStorage()
            .write(key: pLocalPassword, value: password);
        logger.d('[Auth]localLogin: USP login succeeded');

        // Fetch device info and store fingerprint before completing login —
        // keeps auth state in loading so the login spinner stays visible.
        await ref
            .read(sessionProvider.notifier)
            .fetchDeviceInfoAndInitializeServices();

        return previousState.copyWith(
          localPassword: password,
          loginType: LoginType.local,
        );
      }
      throw Exception('USP login failed');
    }, (error) => guardError);
    logger.d('[Auth]localLogin: done, state=$state');
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
    logger.d('[Auth]logout: starting');

    // Capture refs before state change invalidates them.
    final sseManager = ref.read(sseManagerProvider);
    final uspCoordinator = ref.read(uspAuthCoordinatorProvider);
    final fingerprintService = ref.read(routerFingerprintServiceProvider);
    final session = ref.read(sessionProvider.notifier);

    // Disconnect SSE first (fast) — stops reconnect attempts and prevents
    // dashboard orchestrator from calling connect() after state change.
    if (sseManager != null) {
      logger.d('[Auth]logout: disconnecting SSE');
      await sseManager.disconnect();
    }

    // Clear credentials BEFORE setting state — otherwise GoRouter redirect
    // calls init() which reads the password back and re-authenticates.
    logger.d('[Auth]logout: clearing credentials');
    await _authService.clearAllCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pSelectedNetworkId);
    await prefs.remove(pCurrentSN);

    // Now safe to set state — init() will find no stored password.
    state = AsyncValue.data(AuthState.empty());
    ref.read(selectedNetworkIdProvider.notifier).state = null;
    session.clear();

    // Remaining cleanup in background — slow but non-fatal if it fails.
    () async {
      try {
        if (sseManager != null) {
          await sseManager.registry.unregisterAll();
        }
        logger.d('[Auth]logout: syncing USP logout');
        await uspCoordinator.syncAfterLogout();
        await fingerprintService.clear();
        logger.d('[Auth]logout: complete');
      } catch (e) {
        logger.w('[Auth]logout: cleanup error (non-fatal): $e');
      }
    }();
  }
}
