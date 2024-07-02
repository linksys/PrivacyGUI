import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/network_admin/providers/router_password_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

final routerPasswordProvider =
    NotifierProvider<RouterPasswordNotifier, RouterPasswordState>(
        () => RouterPasswordNotifier());

class RouterPasswordNotifier extends Notifier<RouterPasswordState> {
  @override
  RouterPasswordState build() => RouterPasswordState.init();

  Future fetch([bool force = false]) async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchIsConfigured();
    final bool isAdminDefault = JNAPTransactionSuccessWrap.getResult(
                JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
            ?.output['isAdminPasswordDefault'] ??
        false;
    final bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
                JNAPAction.isAdminPasswordSetByUser, Map.fromEntries(results))
            ?.output['isAdminPasswordSetByUser'] ??
        true;
    String passwordHint = '';
    if (isSetByUser) {
      passwordHint = await repo
          .send(JNAPAction.getAdminPasswordHint, fetchRemote: force)
          .then((result) => result.output['passwordHint'] ?? '')
          .onError((error, stackTrace) => '');
    }
    const storage = FlutterSecureStorage();
    final password = await storage.read(key: pLocalPassword);

    state = state.copyWith(
        isDefault: isAdminDefault,
        isSetByUser: isSetByUser,
        adminPassword: password ?? '',
        hint: passwordHint);
  }

  Future<void> setAdminPasswordWithResetCode(
      String password, String hint, String code) async {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.setupSetAdminPassword,
      data: {
        'adminPassword': password,
        'passwordHint': hint,
        'resetCode': code,
      },
      type: CommandType.local,
    )
        .then<void>((value) {
      state = state.copyWith(
        error: null,
      );
    });
  }

  Future setAdminPasswordWithCredentials(String? password,
      [String? hint]) async {
    final repo = ref.read(routerRepositoryProvider);
    final pwd = password ?? ref.read(authProvider).value?.localPassword;
    return repo
        .send(
      JNAPAction.coreSetAdminPassword,
      data: {
        'adminPassword': pwd,
        'passwordHint': hint ?? state.hint,
      },
      type: CommandType.local,
      auth: true,
    )
        .then<void>((value) async {
      await ref
          .read(authProvider.notifier)
          .localLogin(pwd ?? '', guardError: false);
      await fetch(true);
    });
  }

  Future<bool> checkRecoveryCode(String code) async {
    final repo = ref.read(routerRepositoryProvider);
    return repo.send(
      JNAPAction.verifyRouterResetCode,
      data: {
        'resetCode': code,
      },
    ).then((result) {
      state = state.copyWith(
        remainingErrorAttempts: null,
        error: null,
      );
      return true;
    }).onError((error, stackTrace) {
      if (error is JNAPError) {
        if (error.result == errorInvalidResetCode) {
          final errorOutput = jsonDecode(error.error!) as Map<String, dynamic>;
          final remaining = errorOutput['attemptsRemaining'] as int;
          state = state.copyWith(remainingErrorAttempts: remaining);
        }
      }
      return false;
    });
  }

  setEdited(bool hasEdited) {
    state = state.copyWith(hasEdited: hasEdited);
  }

  setValidate(bool isValid) {
    state = state.copyWith(isValid: isValid);
  }
}
