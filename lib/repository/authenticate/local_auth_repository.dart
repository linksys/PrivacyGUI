
import 'package:moab_poc/repository/model/dummy_model.dart';

///
///  1. Local login
///  2. Verify recovery key
///  3. Get masked email
///  4. Set new password
///  6. Get cloud account information or has cloud account exist?
///  7. Get password hint
///
abstract class LocalAuthRepository {

  Future<DummyModel> localLogin(String password);
  Future<DummyModel> verifyRecoveryKey(String key);
  Future<DummyModel> getMaskedEmail();
  Future<DummyModel> resetPassword();
  Future<DummyModel> getCloudAccount();
  Future<DummyModel> getAdminPasswordInfo();
}