import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/router_password/router_password_state.dart';

final routerPasswordProvider =
    NotifierProvider<RouterPasswordNotifier, RouterPasswordState>(
        () => RouterPasswordNotifier());

class RouterPasswordNotifier extends Notifier<RouterPasswordState> {
  @override
  RouterPasswordState build() => RouterPasswordState.init();

  fetch() async {
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
          .send(JNAPAction.getAdminPasswordHint)
          .then((result) => result.output['passwordHint'] ?? '')
          .onError((error, stackTrace) => '');
    }
    const storage = FlutterSecureStorage();
    final password = await storage.read(key: pLocalPassword);

    state = state.copyWith(
        isLoading: false,
        isDefault: isAdminDefault,
        isSetByUser: isSetByUser,
        adminPassword: password ?? '',
        hint: passwordHint);
  }

  Future save(String password, String hint) async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.coreSetAdminPassword,
      data: {
        'adminPassword': password,
        'passwordHint': hint,
      },
      auth: true,
    )
        .then<void>((value) async {
      const storage = FlutterSecureStorage();
      await storage.write(key: pLocalPassword, value: password);
      await fetch();
    }).onError((error, stackTrace) {
      if (error is JNAPError) {
        // handle error
        state = state.copyWith(error: error.error);
      }
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
      return true;
    }).onError((error, stackTrace) {
      if (error is JNAPError) {
        // if (result.output.containsKey('attemptsRemaining')) {
        //   final remaining = result.output['attemptsRemaining'] as int;
        //   final errorCodePrompt =
        //       'That key didn\'t work. Check it and try again.\nTries remaining $remaining';
        //   state = state.copyWith(error: errorCodePrompt);
        // }
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
