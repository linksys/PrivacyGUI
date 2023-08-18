import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
}
