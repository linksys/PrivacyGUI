import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/account/state.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';

import '../../util/logger.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({required LinksysCloudRepository repository})
      : _repo = repository,
        super(AccountState.empty());

  final LinksysCloudRepository _repo;

  Future<void> fetchAccount() async {
    const storage = FlutterSecureStorage();

    final account = await _repo.getAccount();
    final methods = (account.preferences?.mfaEnabled ?? false)
        ? await _repo.getMfaMethod()
        : null;
    final password = await storage.read(key: pUserPassword);
    emit(
      AccountState.fromCloudAccount(account)
          .copyWith(methods: methods ?? [])
          .copyWith(password: password),
    );
  }

  @override
  void onChange(Change<AccountState> change) {
    super.onChange(change);
    logger.i(
        'Profiles Cubit changed: ${change.currentState} -> ${change.nextState}');
  }
}
