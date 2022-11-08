
import 'package:linksys_moab/repository/model/dummy_model.dart';

///
///  1. Local login
///  2. Verify recovery key
///  3. Get masked email
///  4. Set new password
///  6. Get cloud account information or has cloud account exist?
///  7. Get password hint
///  8. Create password
///
abstract class LocalAuthRepository {
  Future<DummyModel> createPassword(String password, String hint);
  Future<bool> localLogin(String password);
  Future<DummyModel> verifyRecoveryKey(String key);
  Future<DummyModel> getMaskedEmail();
  Future<DummyModel> resetPassword();
  Future<DummyModel> getCloudAccount();
  Future<DummyModel> getAdminPasswordInfo();
}