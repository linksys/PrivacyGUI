import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:linksys_app/constants/cloud_const.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/utils/extension.dart';

extension AuthorizationService on LinksysHttpClient {
  Future<Response> passwordLogin({
    required String username,
    required String password,
    String? userAgentId,
    String? secret,
  }) {
    final endpoint =
        combineUrl(kOauthEndpoint, args: {kVarGrantType: 'password'});

    final authorization =
        base64Encode('$kClientTypeId:$kClientSecret'.codeUnits);

    final header = defaultHeader
      ..[HttpHeaders.contentTypeHeader] = 'application/x-www-form-urlencoded'
      ..[HttpHeaders.authorizationHeader] = 'Basic $authorization';

    final usernameEnc = Uri.encodeQueryComponent(username);
    final passwordEnc = Uri.encodeQueryComponent(password);

    final body = 'username=$usernameEnc&password=$passwordEnc';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const query = 'grant_type=password';

    if (userAgentId != null && secret != null) {
      final signature = '$query\n$body\n$timestamp'.toHmacSHA256(secret);
      header[kHeaderSignature] = signature;
      header[kHeaderUserAgentId] = userAgentId;
      header[kHeaderTimestamp] = '$timestamp';
    }

    return this.post(Uri.parse(endpoint), headers: header, body: body);
  }

  Future<Response> refreshToken({required String token}) {
    final endpoint =
        combineUrl(kOauthEndpoint, args: {kVarGrantType: 'refresh_token'});

    final authorization =
        base64Encode('$kClientTypeId:$kClientSecret'.codeUnits);

    final header = defaultHeader
      ..[HttpHeaders.contentTypeHeader] = 'application/x-www-form-urlencoded'
      ..[HttpHeaders.authorizationHeader] = 'Basic $authorization';

    final body = 'grant_type=refresh_token&refresh_token=$token';

    return this.post(Uri.parse(endpoint), headers: header, body: body);
  }

  Future<Response> mfaChallenge(
      {required String verificationToken,
      String method = 'EMAIL',
      String? token}) {
    final endpoint = combineUrl(kOauthChallengeEndpoint);

    final authorization =
        base64Encode('$kClientTypeId:$kClientSecret'.codeUnits);

    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = token == null
          ? 'Basic $authorization'
          : 'CiscoHNUserAuth session_token=$token';

    final body = {
      'challengeType': 'push-code',
      'communicationMethod': method,
      'verificationToken': verificationToken,
    };
    return this
        .post(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }

  Future<Response> oAuthMfaValidate({
    required String otpCode,
    required String verificationToken,
    bool rememberUserAgent = false,
  }) {
    final endpoint = combineUrl(kOauthEndpoint, args: {
      kVarGrantType: 'http://linksyssmartwifi.com/grant/mfa-validate'
    });

    final authorization =
        base64Encode('$kClientTypeId:$kClientSecret'.codeUnits);

    final header = defaultHeader
      ..[HttpHeaders.contentTypeHeader] = 'application/x-www-form-urlencoded'
      ..[HttpHeaders.authorizationHeader] = 'Basic $authorization';

    final body =
        'verification_token=$verificationToken&otp=$otpCode&remember_user_agent=$rememberUserAgent';

    return this.post(Uri.parse(endpoint), headers: header, body: body);
  }
}
