import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/auth_requests.dart';
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

  @override
  Future<void> addPhoneNumber(String phone) {
    // TODO: implement addPhoneNumber
    throw UnimplementedError();
  }

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

  @override
  Future<DummyModel> login(String username, String password) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<void> loginChallenge(int method) {
    // TODO: implement loginChallenge
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> passwordLessLogin(String username, String method) {
    // TODO: implement passwordLessLogin
    throw UnimplementedError();
  }

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

  @override
  Future<DummyModel> testUsername(String username) {
    // TODO: implement testUsername
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> validateChallenge(String code) {
    // TODO: implement validateChallenge
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> validatePasswordLessCode(String token, String code) {
    // TODO: implement validatePasswordLessCode
    throw UnimplementedError();
  }

  @override
  Future<void> authChallenge(
      String id, String secret, AuthChallengeMethod method) {
    // TODO: implement authChallenge
    throw UnimplementedError();
  }

  @override
  Future<void> authChallengeVerify(String token, String code) {
    // TODO: implement authChallengeVerify
    throw UnimplementedError();
  }

  @override
  Future<String> createAccountPreparation(String email) async {
    return _httpClient
        .createAccountPreparation(email)
        .then((response) => json.decode(response.body)['token']);
  }

  @override
  Future<void> createAccountPreparationUpdateMethod(
      String token, CommunicationMethod method) {
    // TODO: implement createAccountPreparationUpdateMethod
    throw UnimplementedError();
  }

  @override
  Future<CloudAccountInfo> createVerifiedAccount(
      String token, CreateAccountVerified verified) {
    // TODO: implement createVerifiedAccount
    throw UnimplementedError();
  }

  @override
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(String username) {
    // TODO: implement getMaskedCommunicationMethods
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> login2(String token, String? certToken) {
    // TODO: implement login2
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> loginPassword(String token, String password) {
    // TODO: implement loginPassword
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> loginPrepare(CommunicationMethod method) {
    // TODO: implement loginPrepare
    throw UnimplementedError();
  }
}
