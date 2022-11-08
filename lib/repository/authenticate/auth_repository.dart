import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_create_account_verified.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/network/http/model/cloud_login_state.dart';
import 'package:linksys_moab/network/http/model/cloud_session_data.dart';
import 'package:linksys_moab/network/http/model/cloud_task_model.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';

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
  Future<void> createAccountPreparationUpdateMethod(
      String token, CommunicationMethod method);

  ///
  /// Do create account actually
  /// * Input: [CreateAccountVerified]
  /// * return: [CloudAccountVerifyInfo]
  /// * error: ?????
  Future<CloudAccountVerifyInfo> createVerifiedAccount(
      CreateAccountVerified verified);

  ///
  /// * state = PASSWORD_REQUIRED
  /// * state = REQUIRE_2SV
  Future<CloudLoginState> loginPrepare(String username);

  ///
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(
      String username);

  ///
  /// * state = CAN_LOGIN
  /// * state = REQUIRE_2SV
  ///
  Future<CloudLoginState> loginPassword(String token, String password);

  ///
  /// * state = ACCEPTED
  ///
  Future<CloudLoginAcceptState> login(String token);

  ///
  ///
  ///
  Future<void> downloadCloudCert({required String taskId, required String secret});

  Future<CertInfoData> extendCertificate({required String certId});
  Future<CloudSessionData> requestSession({required String certId});
  ///
  ///
  ///
  Future<List<RegionCode>> fetchRegionCodes();

  Future<ChangeAuthenticationModeChallenge> changeAuthenticationModePrepare(
      String accountId,
      String? password,
      String authenticationMode,
      );

  Future<void> changeAuthenticationMode(
      String accountId, String token, String? password);
}
