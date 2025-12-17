import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';
import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

final routerPasswordProvider =
    NotifierProvider<RouterPasswordNotifier, RouterPasswordState>(
        () => RouterPasswordNotifier());

class RouterPasswordNotifier extends Notifier<RouterPasswordState> {
  @override
  RouterPasswordState build() => RouterPasswordState.init();

  Future fetch([bool force = false]) async {
    try {
      final service = ref.read(routerPasswordServiceProvider);
      final result = await service.fetchPasswordConfiguration();

      state = state.copyWith(
        isDefault: result['isDefault'] as bool,
        isSetByUser: result['isSetByUser'] as bool,
        adminPassword: result['storedPassword'] as String,
        hint: result['hint'] as String,
      );
      logger.d('[State]:[RouterPassword]:${state.toJson()}');
    } on JNAPError catch (error) {
      logger.e('[RouterPassword] JNAP error in fetch: ${error.result}');
      rethrow;
    } catch (error) {
      logger.e('[RouterPassword] Error in fetch: $error');
      rethrow;
    }
  }

  Future<void> setAdminPasswordWithResetCode(
      String password, String hint, String code) async {
    try {
      final service = ref.read(routerPasswordServiceProvider);
      await service.setPasswordWithResetCode(password, hint, code);
      state = state.copyWith(error: null);
    } on JNAPError catch (error) {
      logger.e(
          '[RouterPassword] JNAP error in setPasswordWithResetCode: ${error.result}');
      rethrow;
    }
  }

  Future setAdminPasswordWithCredentials(String? password,
      [String? hint]) async {
    try {
      final service = ref.read(routerPasswordServiceProvider);
      final pwd = password ?? ref.read(authProvider).value?.localPassword;

      await service.setPasswordWithCredentials(pwd ?? '', hint ?? state.hint);

      // Keep AuthProvider.localLogin in notifier (per architecture decision)
      await ref
          .read(authProvider.notifier)
          .localLogin(pwd ?? '', guardError: false);
      await fetch(true);
    } on JNAPError catch (error) {
      logger.e(
          '[RouterPassword] JNAP error in setPasswordWithCredentials: ${error.result}');
      rethrow;
    }
  }

  Future<bool> checkRecoveryCode(String code) async {
    try {
      final service = ref.read(routerPasswordServiceProvider);
      final result = await service.verifyRecoveryCode(code);

      final isValid = result['isValid'] as bool;
      final attemptsRemaining = result['attemptsRemaining'] as int?;

      if (isValid) {
        state = state.copyWith(
          remainingErrorAttempts: null,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(remainingErrorAttempts: attemptsRemaining);
        return false;
      }
    } on JNAPError catch (error) {
      logger.e(
          '[RouterPassword] JNAP error in checkRecoveryCode: ${error.result}');
      rethrow;
    }
  }

  setEdited(bool hasEdited) {
    state = state.copyWith(hasEdited: hasEdited);
  }

  setValidate(bool isValid) {
    state = state.copyWith(isValid: isValid);
  }
}
