import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/repository/account/cloud_account_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/logger.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({required CloudAccountRepository repository})
      : _repo = repository,
        super(AccountState.empty());

  final CloudAccountRepository _repo;

  Future<void> fetchAccount() async {
    final account = await _repo.getAccount();
    final defaultGroupId = await _repo.getDefaultGroupId(account.id);
    logger.d('accountId: ${account.id}, defaultGroupId:$defaultGroupId');
    await SharedPreferences.getInstance().then((pref) async {
      await pref.setString(moabPrefCloudAccountId, account.id);
      await pref.setString(moabPrefCloudDefaultGroupId, defaultGroupId);
    });
    final isBiometricEnabled = (await SharedPreferences.getInstance())
            .getBool(moabPrefEnableBiometrics) ??
        false;
    emit(state
        .copyWithAccountInfo(
            info: account, isBiometricEnabled: isBiometricEnabled)
        .copyWith(groupId: defaultGroupId));
  }

  Future<String> startAddCommunicationMethod(CommunicationMethod method) async {
    return _repo.addCommunicationMethods(state.id, method);
  }

  Future<void> deleteCommunicationMethod(
      String method, String targetValue) async {
    return _repo.deleteCommunicationMethods(state.id, method, targetValue);
  }

  Future<void> changePassword(String password, String token) async {
    return _repo.changePassword(state.id, password, token);
  }

  Future<String> verifyPassword(String password) async {
    return _repo.verifyPassword(state.id, password);
  }

  Future<void> toggleBiometrics(bool value) async {
    final pref = await SharedPreferences.getInstance();
    if (value) {
      pref.setBool(moabPrefEnableBiometrics, value);
    } else {
      pref.remove(moabPrefEnableBiometrics);
    }
    emit(state.copyWith(isBiometricEnabled: value));
  }

  @override
  void onChange(Change<AccountState> change) {
    super.onChange(change);
    logger.i(
        'Profiles Cubit changed: ${change.currentState} -> ${change.nextState}');
  }
}
