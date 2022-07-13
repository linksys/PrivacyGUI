
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';

class CloudAuthRepository extends AuthRepository {

  CloudAuthRepository(MoabHttpClient httpClient): _httpClient = httpClient;

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

}