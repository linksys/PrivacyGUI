import 'dart:convert';

import 'package:moab_poc/config/cloud_environment_manager.dart';
import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';

class CloudAuthRepository extends AuthRepository {
  CloudAuthRepository(MoabHttpClient httpClient) : _httpClient = httpClient;

  final MoabHttpClient _httpClient;

  @deprecated
  @override
  Future<void> addPhoneNumber(String phone) {
    // TODO: implement addPhoneNumber
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> createAccount(String username) {
    // TODO: implement createAccount
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword() {
    // TODO: implement forgotPassword
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> login(String username, String password) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<void> loginChallenge(int method) {
    // TODO: implement loginChallenge
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> passwordLessLogin(String username, String method) {
    // TODO: implement passwordLessLogin
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<void> resendPasswordLessCode(String token, String method) {
    // TODO: implement resendPasswordLessCode
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> resetPassword(String password) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> testUsername(String username) {
    // TODO: implement testUsername
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> validateChallenge(String code) {
    // TODO: implement validateChallenge
    throw UnimplementedError();
  }

  @deprecated
  @override
  Future<DummyModel> validatePasswordLessCode(String token, String code) {
    // TODO: implement validatePasswordLessCode
    throw UnimplementedError();
  }

  @override
  Future<void> authChallenge(AuthChallengeMethod method) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient.authChallenge(method,
            id: cloudApp.id, secret: cloudApp.appSecret));
  }

  @override
  Future<void> authChallengeVerify(String token, String code) {
    return _httpClient.authChallengeVerify(token: token, code: code);
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
  Future<CloudAccountInfo> createVerifiedAccount(
      CreateAccountVerified verified) {
    return _httpClient.createAccount(verified).then(
        (response) => CloudAccountInfo.fromJson(json.decode(response.body)));
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
  Future<CloudLoginState> login2(String token, String? certToken) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .login(token, certToken,
                id: cloudApp.id, secret: cloudApp.appSecret)
            .then((response) =>
                CloudLoginState.fromJson(json.decode(response.body))));
  }

  @override
  Future<CloudLoginState> loginPassword(String token, String password) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .loginPassword(token, password,
                id: cloudApp.id, secret: cloudApp.appSecret)
            .then((response) =>
                CloudLoginState.fromJson(json.decode(response.body))));
  }

  @override
  Future<CloudLoginState> loginPrepare(CommunicationMethod method) {
    return CloudEnvironmentManager().loadCloudApp().then((cloudApp) =>
        _httpClient
            .loginPrepare(method, id: cloudApp.id, secret: cloudApp.appSecret)
            .then((response) =>
                CloudLoginState.fromJson(json.decode(response.body))));
  }
}