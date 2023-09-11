import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_app/core/cloud/model/cloud_network_model.dart';
import 'package:linksys_app/provider/account/account_state.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';

final accountProvider =
    NotifierProvider<AccountNotifier, AccountState>(() => AccountNotifier());

class AccountNotifier extends Notifier<AccountState> {
  @override
  AccountState build() => AccountState.empty();

  Future<void> fetchAccount() async {
    final repo = ref.read(cloudRepositoryProvider);
    const storage = FlutterSecureStorage();

    final account = await repo.getAccount();
    final methods = (account.preferences?.mfaEnabled ?? false)
        ? await repo.getMfaMethod()
        : null;
    final password = await storage.read(key: pUserPassword);
    state = AccountState.fromCloudAccount(account)
        .copyWith(methods: methods ?? [])
        .copyWith(password: password);
  }

  void addMfaMethod(CommunicationMethod method) {
    state =
        state.copyWith(methods: [method, ...state.methods], mfaEnabled: true);
  }

  void removeMfaMethod(String mfaID) {
    final repo = ref.read(cloudRepositoryProvider);
    repo.deleteMfaMethod(mfaID).then((success) {
      if (success) {
        final newList =
            state.methods.where((element) => element.id != mfaID).toList();
        state =
            state.copyWith(methods: newList, mfaEnabled: newList.isNotEmpty);
      }
    });
  }

  Future setPhoneNumber(CAMobile mobile) {
    final repo = ref.read(cloudRepositoryProvider);

    return repo.setPreferences(CAPreferences(mobile: mobile)).then((value) {
      state = state.copyWith(mobile: mobile);
    });
  }

  Future setNewsletterOptIn(bool optIn) {
    final repo = ref.read(cloudRepositoryProvider);

    return repo
        .setPreferences(CAPreferences(newsletterOptIn: optIn.toString()))
        .then((success) {
      state = state.copyWith(newsletterOptIn: optIn);
    });
  }
}
