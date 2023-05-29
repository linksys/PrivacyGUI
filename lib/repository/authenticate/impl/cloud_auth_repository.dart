import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/default_country_codes.dart';
import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_create_account_verified.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';
import 'package:linksys_moab/repository/authenticate/auth_repository.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudAuthRepository extends AuthRepository with SCLoader {
  CloudAuthRepository(MoabHttpClient httpClient) : _httpClient = httpClient;

  final MoabHttpClient _httpClient;

  @override
  Future<void> forgotPassword() {
    // TODO: implement forgotPassword
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> resetPassword(String password) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future<String> createAccountPreparation(String email) {
    return _httpClient
        .createAccountPreparation(email)
        .then((response) => json.decode(response.body)['token']);
  }

  @override
  Future<void> createAccountPreparationUpdateMethod(
      String token, CommunicationMethod method) {
    return _httpClient.createAccountVerifyPreparation(token, method);
  }

  @override
  Future<CloudAccountVerifyInfo> createVerifiedAccount(
      CreateAccountVerified verified) {
    return _httpClient.createAccount(verified).then((response) =>
        CloudAccountVerifyInfo.fromJson(json.decode(response.body)));
  }

  @override
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(
      String username) {
    return _httpClient.getMaskedCommunicationMethods(username).then((response) {
      return List.from((json.decode(response.body) as List)
          .map((e) => CommunicationMethod.fromJson(e)));
    });
  }

  @override
  Future<void> downloadCloudCert({required taskId, required secret}) {
    return _httpClient
        .downloadCloudCerts(taskId: taskId, secret: secret)
        .then((response) async {
      final task = CloudDownloadCertTask.fromJson(json.decode(response.body));
      String publicKey = task.data.publicKey;
      String privateKey = task.data.privateKey;

      const storage = FlutterSecureStorage();
      await storage.write(
          key: linksysPrefCloudCertDataKey, value: jsonEncode(task.data.toJson()));
      await storage.write(key: linksysPrefCloudPrivateKey, value: privateKey);

      SharedPreferences.getInstance().then((pref) {
        pref.setString(linksysPrefCloudPublicKey, publicKey);
      });
    });
  }

  @override
  Future<List<RegionCode>> fetchRegionCodes() async {
    List<RegionCode> regions = [];
    var countryCodeJson = defaultCountryCodes;
    if (countryCodeJson.containsKey('countryCodes')) {
      final jsonArray = countryCodeJson['countryCodes'] as List<dynamic>;
      regions = List.from(jsonArray.map((e) => RegionCode.fromJson(e)));
    }
    return regions;
  }

}
