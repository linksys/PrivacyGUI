
import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';

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
  Future<DummyModel> passwordLessLogin(String username, String method);
  Future<DummyModel> validatePasswordLessCode(String token, String code);
  Future<void> resendPasswordLessCode(String token, String method);
  Future<void> loginChallenge(int method);
  Future<DummyModel> validateChallenge(String code);
  Future<DummyModel> createAccount(String username);
  Future<void> addPhoneNumber(String phone);
  Future<DummyModel> resetPassword(String password);
  Future<void> forgotPassword();

  ///
  /// Initiate create account verify first flow
  /// * Input: email
  /// * return: token
  /// * error: INVALID_PARAMETER, general error
  /// * error: USERNAME_ALREADY_EXISTS, parameters: {"name": "username", "value":"xxxxx"}
  ///
  Future<String> createAccountPreparation(String email);
  ///
  /// Update a communication methods
  /// * Input: [CommunicationMethod]
  /// * Input: token
  /// * return: void
  /// * error: INVALID_PARAMETER, invalid communication method
  ///
  Future<void> createAccountPreparationUpdateMethod(String token, CommunicationMethod method);
  ///
  /// Initiate OTP Verify via EMAIL/SMS
  /// * Input: [AuthChallengeMethod]
  /// * Input: App Id
  /// * Input: App Secret
  /// * return: void
  /// * error: INVALID_PARAMETER
  Future<void> authChallenge(String id, String secret, AuthChallengeMethod method);
  ///
  /// Verify OTP code received from EMAIL/SMS
  /// * Input: token
  /// * Input: code
  /// * return: void
  /// * error: INVALID_OTP
  Future<void> authChallengeVerify(String token, String code);

  ///
  /// Do create account actually
  /// * Input: token
  /// * Input: [CreateAccountVerified]
  /// * return: [CloudAccountInfo]
  /// * error: ?????
  Future<CloudAccountInfo> createVerifiedAccount(String token, CreateAccountVerified verified);
}