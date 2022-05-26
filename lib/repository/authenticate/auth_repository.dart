
import '../model/dummy_model.dart';

///
/// 1. username/password auth
/// 2. password less auth - email or phone
/// 3. 2sv - email or phone
/// 4. otp
/// 5. create account
/// 6. add phone
/// 7. forgot password
/// 8. reset password
///
abstract class AuthRepository {
  Future<DummyModel> testUsername(String username);
  Future<DummyModel> login(String username, String password);
  Future<void> passwordLessLogin(int method);
  Future<DummyModel> validatePasswordLessCode(String code);
  Future<void> resendPasswordLessCode();
  Future<void> loginChallenge(int method);
  Future<DummyModel> validateChallenge(String code);
  Future<DummyModel> createAccount(String username);
  Future<void> addPhoneNumber(String phone);
  Future<DummyModel> resetPassword(String password);
  Future<void> forgotPassword();

}