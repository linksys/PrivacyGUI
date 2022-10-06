import 'dart:convert';

import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/constants.dart';
import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_create_account_verified.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/network/http/model/cloud_login_state.dart';
import 'package:linksys_moab/network/http/model/cloud_session_data.dart';
import 'package:linksys_moab/network/http/model/cloud_task_model.dart';
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
  Future<CloudLoginAcceptState> login(String token) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .login(token, id: cloudApp.id, secret: cloudApp.appSecret!)
            .then((response) =>
                CloudLoginAcceptState.fromJson(json.decode(response.body))));
  }

  @override
  Future<CloudLoginState> loginPassword(String token, String password) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .loginPassword(token, password,
                id: cloudApp.id, secret: cloudApp.appSecret!)
            .then((response) =>
                CloudLoginState.fromJson(json.decode(response.body))));
  }

  @override
  Future<CloudLoginState> loginPrepare(String username) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .loginPrepare(username,
                id: cloudApp.id, secret: cloudApp.appSecret!)
            .then((response) =>
                CloudLoginState.fromJson(json.decode(response.body))));
  }

  @override
  Future<void> downloadCloudCert({required taskId, required secret}) {
    return _httpClient
        .downloadCloudCerts(taskId: taskId, secret: secret)
        .then((response) {
      final task = CloudDownloadCertTask.fromJson(json.decode(response.body));
      String publicKey = task.data.publicKey;
      String privateKey = task.data.privateKey;

      SharedPreferences.getInstance().then((pref) {
        pref.setString(
            moabPrefCloudCertDataKey, jsonEncode(task.data.toJson()));
        pref.setString(moabPrefCloudPrivateKey, privateKey);
        pref.setString(moabPrefCloudPublicKey, publicKey);
      });
    });
  }

  @override
  Future<CertInfoData> extendCertificate({required String certId}) async {
    final _secureClient = MoabHttpClient.withCert(await get());
    return CloudEnvironmentManager()
        .loadCloudApp()
        .then((cloudApp) => _secureClient.extendCertificates(
            certId, cloudApp.id, cloudApp.appSecret!))
        .then((response) {
      return CertInfoData.fromJson(json.decode(response.body));
    });
  }

  @override
  Future<CloudSessionData> requestSession({required String certId}) async {
    final _secureClient = MoabHttpClient.withCert(await get());
    return CloudEnvironmentManager()
        .loadCloudApp()
        .then((cloudApp) => _secureClient.requestAuthSession(
        certId, cloudApp.id, cloudApp.appSecret!))
        .then((response) {
      return CloudSessionData.fromJson(json.decode(response.body));
    });
  }

  @override
  Future<List<RegionCode>> fetchRegionCodes() async {
    List<RegionCode> regions = [];
    final response = await _httpClient.fetchRegionCodes();
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    if (jsonMap.containsKey('countryCodes')) {
      final jsonArray = jsonMap['countryCodes'] as List<dynamic>;
      regions = List.from(jsonArray.map((e) => RegionCode.fromJson(e)));
    }
    return regions;
  }
}
