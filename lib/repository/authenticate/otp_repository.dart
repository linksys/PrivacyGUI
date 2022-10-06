import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';

class OtpRepository {
  OtpRepository({required MoabHttpClient httpClient}) : _httpClient = httpClient;
  final MoabHttpClient _httpClient;

  ///
  /// Initiate OTP Verify via EMAIL/SMS, OR resend code
  /// * Input: [AuthChallengeMethod]
  /// * return: void
  /// * error: INVALID_PARAMETER
  Future<void> authChallenge(BaseAuthChallenge method) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient.authChallenge(method,
            id: cloudApp.id, secret: cloudApp.appSecret!));
  }
  ///
  /// Verify OTP code received from EMAIL/SMS
  /// * Input: token
  /// * Input: code
  /// * return: void
  /// * error: INVALID_OTP
  Future<void> authChallengeVerify(String token, String code) {
    return _httpClient.authChallengeVerify(token: token, code: code);
  }

  ///
  /// Verify OTP code received from EMAIL/SMS
  /// * Input: token
  /// * Input: code
  /// * return: void
  /// * error: INVALID_OTP
  Future<void> authChallengeVerifyAccept(String token, String code) {
    return _httpClient.authChallengeVerifyAccepted(token: token, code: code);
  }
}
