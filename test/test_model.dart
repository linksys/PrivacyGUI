import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
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
  });
}
