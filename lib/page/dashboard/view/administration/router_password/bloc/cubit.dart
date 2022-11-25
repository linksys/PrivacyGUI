import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/page/dashboard/view/administration/router_password/bloc/state.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

class RouterPasswordCubit extends Cubit<RouterPasswordState> {
  RouterPasswordCubit(RouterRepository repository)
      : _repository = repository,
        super(RouterPasswordState.init());

  final RouterRepository _repository;

  fetch() async {
    final results = await _repository.fetchIsConfigured();
    final bool isAdminDefault = results[JNAPAction.isAdminPasswordDefault]
            ?.output['isAdminPasswordDefault'] ??
        false;
    final bool isSetByUser = results[JNAPAction.isAdminPasswordSetByUser]
            ?.output['isAdminPasswordSetByUser'] ??
        true;
    String passwordHint = '';
    if (isSetByUser) {
      passwordHint = await _repository
          .getAdminPasswordHint()
          .then((result) => result.output['passwordHint'] ?? '')
          .onError((error, stackTrace) => '');
    }
    const storage = FlutterSecureStorage();
    final password = await storage.read(key: linksysPrefLocalPassword);

    emit(state.copyWith(
        isDefault: isAdminDefault,
        isSetByUser: isSetByUser,
        adminPassword: password ?? '',
        hint: passwordHint));
  }

  Future save(String password, String hint) async {
    return _repository
        .createAdminPassword(password, hint)
        .then<void>((value) async {
      const storage = FlutterSecureStorage();
      await storage.write(key: linksysPrefLocalPassword, value: password);
      await fetch();
    }).onError((error, stackTrace) => onError(error ?? Object(), stackTrace));
  }

  setEdited(bool hasEdited) {
    emit(state.copyWith(hasEdited: hasEdited));
  }

  setValidate(bool isValid) {
    emit(state.copyWith(isValid: isValid));
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JNAPError) {
      // handle error
      emit(state.copyWith(error: error.error));
    }
  }

  @override
  void onChange(Change<RouterPasswordState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
