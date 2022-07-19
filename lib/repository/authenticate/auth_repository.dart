
import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';

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
  ///
  /// refer to [loginPrepare], [createAccountPreparation]
  Future<DummyModel> testUsername(String username);
  ///
  /// refer to [loginPassword], [login2]
  Future<DummyModel> login(String username, String password);
  ///
  ///  refer to [loginPrepare]
  Future<DummyModel> passwordLessLogin(String username, String method);
  ///
  /// refer to [authChallengeVerify]
  Future<DummyModel> validatePasswordLessCode(String token, String code);
  ///
  /// refer to [authChallenge]
  Future<void> resendPasswordLessCode(String token, String method);
  ///
  /// refer to [authChallenve]
  Future<void> loginChallenge(int method);
  ///
  /// refer to [authChallengeCerify]
  Future<DummyModel> validateChallenge(String code);
  ///
  /// refer to [createVerifiedAccount]
  Future<DummyModel> createAccount(String username);
  ///
  /// refer to [createAccountPreparationUpdateMethod]
  Future<void> addPhoneNumber(String phone);
  ///
  /// TBD
  Future<DummyModel> resetPassword(String password);
  ///
  /// TBD
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
  /// Initiate OTP Verify via EMAIL/SMS, OR resend code
  /// * Input: [AuthChallengeMethod]
  /// * return: void
  /// * error: INVALID_PARAMETER
  Future<void> authChallenge(AuthChallengeMethod method);
  ///
  /// Verify OTP code received from EMAIL/SMS
  /// * Input: token
  /// * Input: code
  /// * return: void
  /// * error: INVALID_OTP
  Future<void> authChallengeVerify(String token, String code);

  ///
  /// Do create account actually
  /// * Input: [CreateAccountVerified]
  /// * return: [CloudAccountInfo]
  /// * error: ?????
  Future<CloudAccountInfo> createVerifiedAccount(CreateAccountVerified verified);

  ///
  /// * state = PASSWORD_REQUIRED
  /// * state = REQUIRE_2SV
  Future<CloudLoginState> loginPrepare(CommunicationMethod method);

  ///
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(String username);

  ///
  /// * state = CAN_LOGIN
  /// * state = REQUIRE_2SV
  ///
  Future<CloudLoginState> loginPassword(String token, String password);

  /// TODO Please rename back to login after integrate the latest interface
  /// * state = ACCEPTED
  ///
  Future<CloudLoginState> login2(String token, String? certToken);
}