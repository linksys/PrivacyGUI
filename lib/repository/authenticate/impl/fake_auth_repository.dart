
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';

class FakeAuthRepository extends AuthRepository {
  final waitDuration = const Duration(seconds: 3);
  @override
  Future<void> addPhoneNumber(String phone) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> createAccount(String username) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<void> forgotPassword() async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> login(String username, String password) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<void> loginChallenge(int method) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<void> passwordLessLogin(String username, int method) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<void> resendPasswordLessCode() async {
    // TODO: implement resendPasswordLessCode
    throw UnimplementedError();
  }

  @override
  Future<DummyModel> resetPassword(String password) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<DummyModel> testUsername(String username) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<DummyModel> validateChallenge(String code) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<DummyModel> validatePasswordLessCode(String token, String code) async {
    await Future.delayed(waitDuration);
    return {};
  }
}
