import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/core/cloud/model/create_account_input.dart';

import '../../../constants/_constants.dart';

extension UserService on LinksysHttpClient {
  Future<Response> createAccount({required CreateAccountInput input}) {
    final endpoint = combineUrl(kUserAccountEndpoint);

    final header = defaultHeader;

    return this.post(Uri.parse(endpoint),
        headers: header, body: jsonEncode({'account': input}));
  }

  Future<Response> getPreferences({
    required String token,
  }) {
    final endpoint = combineUrl(kUserAccountPreferencesEndpoint);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> setPreferences(
      {required String token, required CAPreferences preferences}) {
    final endpoint = combineUrl(kUserAccountPreferencesEndpoint);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.put(Uri.parse(endpoint),
        headers: header,
        body: jsonEncode({'preferences': preferences.toJson()}));
  }

  Future<Response> getPhoneCallingCodes({required String token}) {
    final endpoint = combineUrl(kUserPhoneCallingCodesEndpoint);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> getMaskedMfaMethods({required String username}) {
    final endpoint =
        combineUrl(kUserGetMaskedMfaMethods, args: {kVarUsername: username});
    final header = defaultHeader;

    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> getMfaMethods({
    required String token,
  }) {
    final endpoint = combineUrl(kUserMfaMethods);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> prepareAddMfaMethod({
    required String token,
  }) {
    final endpoint = combineUrl(kUserMfaMethods);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.post(Uri.parse(endpoint), headers: header);
  }

  Future<Response> deleteMfaMethod(
      {required String token, required String mfaID}) {
    final endpoint = combineUrl(
      kUserMfaMethodsDelete,
      args: {
        kVarId: mfaID,
      },
    );
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.delete(Uri.parse(endpoint), headers: header);
  }

  Future<Response> mfaValidate(
      {required token,
      required String verificationToken,
      required String code}) {
    final endpoint = combineUrl(kUserMfaValidate);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.post(Uri.parse(endpoint),
        headers: header,
        body: jsonEncode({
          'verificationToken': verificationToken,
          'otp': code,
        }));
  }

  Future<Response> checkPhoneNumber({
    required String token,
    required String countryCode,
    required String phoneNumber,
  }) {
    final endpoint = combineUrl(kUserPhoneNumberCheckEndpoint);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    final body = {
      'mobile': {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
      }
    };
    return this
        .post(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }

  Future<Response> getAccount({
    required String token,
  }) {
    final endpoint = combineUrl(kUserGetAccount);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.get(Uri.parse(endpoint), headers: header);
  }
}
