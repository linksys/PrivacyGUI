import 'dart:convert';

import 'package:moab_poc/network/http/model/base_response.dart';
import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_login_certs.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';
import 'package:moab_poc/network/http/model/cloud_phone.dart';
import 'package:moab_poc/network/http/model/cloud_preferences.dart';
import 'package:test/test.dart';

void main() {
  group('test Cloud Model', () {
    test('test CloudPhoneModel', () async {
      const CloudPhoneModel phone = CloudPhoneModel(
          country: 'TW', countryCallingCode: '+886', phoneNumber: '91234567');
      final jsonObj = phone.toJson();
      expect(jsonObj['country'], 'TW');
      expect(jsonObj['countryCallingCode'], '+886');
      expect(jsonObj['phoneNumber'], '91234567');
      expect(jsonObj['full'], '+88691234567');

      final convertBack = CloudPhoneModel.fromJson(jsonObj);
      expect(convertBack.country, 'TW');
      expect(convertBack.countryCallingCode, '+886');
      expect(convertBack.phoneNumber, '91234567');
      expect(convertBack.full, '+88691234567');
    });

    test('test CloudCommunicationMethod - method = SMS', () async {
      const CloudPhoneModel phone = CloudPhoneModel(
          country: 'TW', countryCallingCode: '+886', phoneNumber: '91234567');
      const CommunicationMethod method = CommunicationMethod(
          method: 'SMS', targetValue: '+88691234567', phone: phone);
      final jsonObj = method.toJson();
      expect(jsonObj['method'], 'SMS');
      expect(jsonObj['targetValue'], '+88691234567');
      expect(jsonObj['phone']['country'], 'TW');
      expect(jsonObj['phone']['countryCallingCode'], '+886');
      expect(jsonObj['phone']['phoneNumber'], '91234567');
      expect(jsonObj['phone']['full'], '+88691234567');

      final convertBack = CommunicationMethod.fromJson(jsonObj);
      expect(convertBack.method, 'SMS');
      expect(convertBack.targetValue, '+88691234567');
      expect(convertBack.phone?.country, 'TW');
      expect(convertBack.phone?.countryCallingCode, '+886');
      expect(convertBack.phone?.phoneNumber, '91234567');
      expect(convertBack.phone?.full, '+88691234567');
    });

    test('test CloudCommunicationMethod - method = EMAIL', () async {
      const CommunicationMethod method = CommunicationMethod(
        method: 'EMAIL',
        targetValue: 'austin.chang@linksys.com',
      );
      final jsonObj = method.toJson();
      expect(jsonObj['method'], 'EMAIL');
      expect(jsonObj['targetValue'], 'austin.chang@linksys.com');
      expect(jsonObj['phone'], null);

      final convertBack = CommunicationMethod.fromJson(jsonObj);
      expect(convertBack.method, 'EMAIL');
      expect(convertBack.targetValue, 'austin.chang@linksys.com');
      expect(convertBack.phone, null);
    });

    test('test AuthChallengeMethod', () async {
      const AuthChallengeMethod method = AuthChallengeMethod(
          token: 'token-for-auth-challenge',
          method: 'EMAIL',
          target: 'austin.chang@linksys.com');
      final jsonObj = method.toJson();
      expect(jsonObj['method'], 'EMAIL');
      expect(jsonObj['targetValue'], 'austin.chang@linksys.com');
      expect(jsonObj['token'], 'token-for-auth-challenge');

      final convertBack = AuthChallengeMethod.fromJson(jsonObj);
      expect(convertBack.method, 'EMAIL');
      expect(convertBack.target, 'austin.chang@linksys.com');
      expect(convertBack.token, 'token-for-auth-challenge');
    });

    test('test CloudPreference', () async {
      const CloudPreferences preferences = CloudPreferences(
          isoLanguageCode: 'zh', isoCountryCode: 'TW', timeZone: 'Asia/Taipei');
      final jsonObj = preferences.toJson();
      expect(jsonObj['isoLanguageCode'], 'zh');
      expect(jsonObj['isoCountryCode'], 'TW');
      expect(jsonObj['timeZone'], 'Asia/Taipei');

      final convertBack = CloudPreferences.fromJson(jsonObj);
      expect(convertBack.isoLanguageCode, 'zh');
      expect(convertBack.isoCountryCode, 'TW');
      expect(convertBack.timeZone, 'Asia/Taipei');
    });

    test('test CreateAccountVerified - PASSWORDLESS', () async {
      const CloudPreferences preferences = CloudPreferences(
        isoLanguageCode: 'zh',
        isoCountryCode: 'TW',
        timeZone: 'Asia/Taipei',
      );
      const CreateAccountVerified method = CreateAccountVerified(
        token: 'token-account-verified',
        authenticationMode: "PASSWORDLESS",
        preferences: preferences,
      );
      final jsonObj = method.toJson();
      expect(jsonObj['token'], 'token-account-verified');
      expect(jsonObj['authenticationMode'], 'PASSWORDLESS');
      expect(jsonObj['preferences']['isoLanguageCode'], 'zh');
      expect(jsonObj['preferences']['isoCountryCode'], 'TW');
      expect(jsonObj['preferences']['timeZone'], 'Asia/Taipei');

      final convertBack = CreateAccountVerified.fromJson(jsonObj);
      expect(convertBack.token, 'token-account-verified');
      expect(convertBack.authenticationMode, 'PASSWORDLESS');
      expect(convertBack.preferences.isoLanguageCode, 'zh');
      expect(convertBack.preferences.isoCountryCode, 'TW');
      expect(convertBack.preferences.timeZone, 'Asia/Taipei');
    });

    test('test CreateAccountVerified - PASSWORD', () async {
      const CloudPreferences preferences = CloudPreferences(
        isoLanguageCode: 'zh',
        isoCountryCode: 'TW',
        timeZone: 'Asia/Taipei',
      );
      const CreateAccountVerified method = CreateAccountVerified(
        token: 'token-account-verified',
        authenticationMode: "PASSWORD",
        password: "P4SSWORd!",
        preferences: preferences,
      );
      final jsonObj = method.toJson();
      expect(jsonObj['token'], 'token-account-verified');
      expect(jsonObj['authenticationMode'], 'PASSWORD');
      expect(jsonObj['password'], 'P4SSWORd!');
      expect(jsonObj['preferences']['isoLanguageCode'], 'zh');
      expect(jsonObj['preferences']['isoCountryCode'], 'TW');
      expect(jsonObj['preferences']['timeZone'], 'Asia/Taipei');

      final convertBack = CreateAccountVerified.fromJson(jsonObj);
      expect(convertBack.token, 'token-account-verified');
      expect(convertBack.authenticationMode, 'PASSWORD');
      expect(convertBack.password, 'P4SSWORd!');
      expect(convertBack.preferences.isoLanguageCode, 'zh');
      expect(convertBack.preferences.isoCountryCode, 'TW');
      expect(convertBack.preferences.timeZone, 'Asia/Taipei');
    });

    test('test CloudAccountInfo', () async {
      const CloudAccountInfo method = CloudAccountInfo(
        id: 'id-for-account-info',
        username: 'austin.chang@linksys.com',
        usernames: ['austin.chang@linksys.com'],
        status: 'ACTIVE',
        type: 'NORMAL',
        authenticationMode: 'PASSWORD',
        createAt: '2022-07-13T09:37:01.665063052Z',
        updateAt: '2022-07-13T09:37:01.665063052Z',
      );

      final jsonObj = method.toJson();
      expect(jsonObj['id'], 'id-for-account-info');
      expect(jsonObj['username'], 'austin.chang@linksys.com');
      expect(jsonObj['usernames'][0], 'austin.chang@linksys.com');
      expect(jsonObj['status'], 'ACTIVE');
      expect(jsonObj['type'], 'NORMAL');
      expect(jsonObj['authenticationMode'], 'PASSWORD');
      expect(jsonObj['createAt'], '2022-07-13T09:37:01.665063052Z');
      expect(jsonObj['updateAt'], '2022-07-13T09:37:01.665063052Z');

      final convertBack = CloudAccountInfo.fromJson(jsonObj);
      expect(convertBack.id, 'id-for-account-info');
      expect(convertBack.username, 'austin.chang@linksys.com');
      expect(convertBack.usernames.first, 'austin.chang@linksys.com');
      expect(convertBack.status, 'ACTIVE');
      expect(convertBack.type, 'NORMAL');
      expect(convertBack.authenticationMode, 'PASSWORD');
      expect(convertBack.createAt, '2022-07-13T09:37:01.665063052Z');
      expect(convertBack.updateAt, '2022-07-13T09:37:01.665063052Z');
    });

    test('test CloudLoginState', () async {
      const CloudLoginState method = CloudLoginState(
        state: 'PASSWORD_REQUIRED',
        data: CloudLoginStateData(token: 'token-for-login-state', authenticationMode: 'PASSWORD')
      );

      final jsonObj = method.toJson();
      expect(jsonObj['state'], 'PASSWORD_REQUIRED');
      expect(jsonObj['data']['token'], 'token-for-login-state');
      expect(jsonObj['data']['authenticationMode'], 'PASSWORD');


      final convertBack = CloudLoginState.fromJson(jsonObj);
      expect(convertBack.state, 'PASSWORD_REQUIRED');
      expect(convertBack.data?.token, 'token-for-login-state');
      expect(convertBack.data?.authenticationMode, 'PASSWORD');

    });

    test('test CloudLoginState state only', () async {
      const CloudLoginState method = CloudLoginState(
          state: 'PASSWORD_REQUIRED',
      );

      final jsonObj = method.toJson();
      expect(jsonObj['state'], 'PASSWORD_REQUIRED');



      final convertBack = CloudLoginState.fromJson(jsonObj);
      expect(convertBack.state, 'PASSWORD_REQUIRED');

    });

    test('test CloudDownloadCertTask', () async {
      final jsonObj = {
        "taskType": "CREATE_CERTIFICATE",
        "data": {
          "id": "RET-R1:492647359751711213641065353474088091562661625693",
          "rootCaId": "RET-ROOT1",
          "expiration": "2032-04-22T09:37:35.000+00:00",
          "serialNumber": "35ca07cbde04e779b5550bab457eab57",
          "publicKey": "-----BEGIN CERTIFICATE-----\n*****\n-----END CERTIFICATE-----",
          "privateKey": "-----BEGIN PRIVATE KEY-----\n*****\n-----END PRIVATE KEY-----"
        }
      };
      final cloudDownloadTask = CloudDownloadCertTask.fromJson(jsonObj);
      expect(cloudDownloadTask.taskType, 'CREATE_CERTIFICATE');
      expect(cloudDownloadTask.data.id, 'RET-R1:492647359751711213641065353474088091562661625693');
      expect(cloudDownloadTask.data.rootCaId, 'RET-ROOT1');
      expect(cloudDownloadTask.data.expiration, '2032-04-22T09:37:35.000+00:00');
      expect(cloudDownloadTask.data.serialNumber, '35ca07cbde04e779b5550bab457eab57');
      expect(cloudDownloadTask.data.publicKey, '-----BEGIN CERTIFICATE-----\n*****\n-----END CERTIFICATE-----');
      expect(cloudDownloadTask.data.privateKey, '-----BEGIN PRIVATE KEY-----\n*****\n-----END PRIVATE KEY-----');


      final convertBack = cloudDownloadTask.toJson();
      expect(convertBack['taskType'], 'CREATE_CERTIFICATE');
      expect(convertBack['data']['id'], 'RET-R1:492647359751711213641065353474088091562661625693');
      expect(convertBack['data']['rootCaId'], 'RET-ROOT1');
      expect(convertBack['data']['expiration'], '2032-04-22T09:37:35.000+00:00');
      expect(convertBack['data']['serialNumber'], '35ca07cbde04e779b5550bab457eab57');
      expect(convertBack['data']['publicKey'], '-----BEGIN CERTIFICATE-----\n*****\n-----END CERTIFICATE-----');
      expect(convertBack['data']['privateKey'], '-----BEGIN PRIVATE KEY-----\n*****\n-----END PRIVATE KEY-----');


    });

    test('test ErrorResponse #1', () async {
      const ErrorResponse method = ErrorResponse(
        code: 'USERNAME_ALREADY_EXISTS',
        errorMessage: 'Error',
        parameters: [
          {'name': 'username', 'value': 'austin.chang@linksys.com'},
        ],
      );
      final jsonObj = method.toJson();
      expect(jsonObj['code'], 'USERNAME_ALREADY_EXISTS');
      expect(jsonObj['errorMessage'], 'Error');
      expect((jsonObj['parameters'] as List).length, 1);
      expect((jsonObj['parameters'] as List<Map<String, dynamic>>)[0]['name'],
          'username');
      expect((jsonObj['parameters'] as List<Map<String, dynamic>>)[0]['value'],
          'austin.chang@linksys.com');

      final convertBack = ErrorResponse.fromJson(jsonObj);
      expect(convertBack.code, 'USERNAME_ALREADY_EXISTS');
      expect(convertBack.errorMessage, 'Error');
      expect(convertBack.parameters?.length, 1);
      expect(convertBack.parameters?[0]['name'], 'username');
      expect(convertBack.parameters?[0]['value'], 'austin.chang@linksys.com');
    });
    test('test ErrorResponse #2', () async {
      const ErrorResponse method = ErrorResponse(
        code: 'USERNAME_ALREADY_EXISTS',
        parameters: [
          {'name': 'username', 'value': 'austin.chang@linksys.com'},
        ],
      );
      final jsonObj = method.toJson();
      expect(jsonObj['code'], 'USERNAME_ALREADY_EXISTS');
      expect(jsonObj['errorMessage'], null);
      expect((jsonObj['parameters'] as List).length, 1);
      expect((jsonObj['parameters'] as List<Map<String, dynamic>>)[0]['name'],
          'username');
      expect((jsonObj['parameters'] as List<Map<String, dynamic>>)[0]['value'],
          'austin.chang@linksys.com');

      final convertBack = ErrorResponse.fromJson(jsonObj);
      expect(convertBack.code, 'USERNAME_ALREADY_EXISTS');
      expect(convertBack.errorMessage, null);
      expect(convertBack.parameters?.length, 1);
      expect(convertBack.parameters?[0]['name'], 'username');
      expect(convertBack.parameters?[0]['value'], 'austin.chang@linksys.com');
    });
    test('test ErrorResponse #3', () async {
      const ErrorResponse method = ErrorResponse(
        code: 'USERNAME_ALREADY_EXISTS',
        errorMessage: 'Error',
      );
      final jsonObj = method.toJson();
      expect(jsonObj['code'], 'USERNAME_ALREADY_EXISTS');
      expect(jsonObj['errorMessage'], 'Error');
      expect((jsonObj['parameters']), null);

      final convertBack = ErrorResponse.fromJson(jsonObj);
      expect(convertBack.code, 'USERNAME_ALREADY_EXISTS');
      expect(convertBack.errorMessage, 'Error');
      expect(convertBack.parameters, null);
    });
  });
}
