import 'package:moab_poc/repository/authenticate/local_auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLocalAuthRepository implements LocalAuthRepository {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final waitDuration = const Duration(seconds: 2);

  @override
  Future<DummyModel> localLogin(String password) async {
    await Future.delayed(waitDuration);
    if (password == 'showmeerror') {
      throw CloudException('LOCAL_LOGIN_FAILED', 'Incorrect password');
    }
    return {};
  }

  @override
  Future<DummyModel> getCloudAccount() {
    // TODO: implement getCloudAccount
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> getMaskedEmail() async {
    await Future.delayed(waitDuration);
    return {'maskedEmail': 'au********@******.com'};
  }

  @override
  Future<DummyModel> getAdminPasswordInfo() async {
    // has admin password : false -> create admin password
    // has admin password : true -> local login
    await Future.delayed(waitDuration);
    // return {'hasAdminPassword': false};
    return {'hasAdminPassword': true, 'hint': 'linksys'};
  }

  @override
  Future<DummyModel> resetPassword() {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> verifyRecoveryKey(String key) {
    // TODO: implement verifyRecoveryKey
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> createPassword(String password, String hint) async {
    await Future.delayed(waitDuration);
    return {};
  }
}
