import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/authenticate/local_auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';

import '../../network/http/model/cloud_auth_clallenge_method.dart';
import '../../network/http/model/cloud_login_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final LocalAuthRepository _localAuthRepository;

  AuthBloc(
      {required AuthRepository repo, required LocalAuthRepository localRepo})
      : _repository = repo,
        _localAuthRepository = localRepo,
        super(AuthState.unknownAuth()) {
    on<InitAuth>(_onInitAuth);
    on<OnLogin>(_onLogin);
    on<OnCreateAccount>(_onCreateAccount);
    on<Unauthorized>(_unauthorized);
    on<Authorized>(_authorized);
    on<SetEmail>(_onSetEmail);
  }

  _onInitAuth(InitAuth event, Emitter<AuthState> emit) {
    // TODO check authorize from local
    emit(AuthState.unAuthorized());
    // emit(AuthState.authorized(method: AuthMethod.remote));
  }

  _onLogin(OnLogin event, Emitter<AuthState> emit) {
    emit(AuthState.onLogin());
  }

  _onCreateAccount(OnCreateAccount event, Emitter<AuthState> emit) {
    emit(AuthState.onCreateAccount());
  }

  _unauthorized(Unauthorized event, Emitter<AuthState> emit) {
    emit(AuthState.unAuthorized());
  }

  _authorized(Authorized event, Emitter<AuthState> emit) {
    emit(state.copyWith(status: AuthStatus.authorized));
  }

  void _onSetEmail(SetEmail event, Emitter<AuthState> emit) {
    emit(state.copyWith(
        accountInfo: AccountInfo(
            username: event.email, loginType: LoginType.otp, otpInfo: [])));
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    logger.d("AuthBloc:: onTransition: $transition");
  }
}

extension AuthBlocCloud on AuthBloc {
  Future<AccountInfo> loginPrepare(String username) async {
    return await _repository
        .loginPrepare(username)
        .then((value) => _handleLoginPrepare(username, value));
  }

  Future<AccountInfo> getMaskedCommunicationMethods(String username) async {
    return await _repository
        .getMaskedCommunicationMethods(username)
        .then((value) => _handleGetMaskedCommunicationMethods(value));
  }

  Future<void> authChallenge(OtpInfo method, String token) async {
    return await _repository.authChallenge(AuthChallengeMethod(
        token: token, method: method.method.name.toUpperCase(), target: method.data));
  }

  Future<void> authChallengeVerify(String token, String code) async {
    return await _repository.authChallengeVerify(token, code);
  }

  Future<AccountInfo> loginPassword(String token, String password) async {
    return await _repository
        .loginPassword(token, password)
        .then((value) => _handleLoginPassword(value));
  }

  Future<void> login(String token) async {
    // TODO: Need to be modified
    try {
      return await _repository.login(token).then((value) => _handleLogin(value));
    } catch (e) {
      print('error: $e');
    }
  }

  Future<AccountInfo> _handleLoginPrepare(
      String username, CloudLoginState cloudLoginState) async {
    logger.d("handle login prepare: $cloudLoginState");
    final LoginType loginType = cloudLoginState.state == 'REQUIRED_2SV'
        ? LoginType.otp
        : LoginType.password;

    AccountInfo accountInfo =
        state.accountInfo.copyWith(username: username, loginType: loginType);
    emit(state.copyWith(
        accountInfo: accountInfo, vToken: cloudLoginState.data?.token));
    return accountInfo;
  }

  Future<AccountInfo> _handleGetMaskedCommunicationMethods(
      List<CommunicationMethod> methods) async {
    logger.d("handle get Masked Communication Methods: $methods");

    List<OtpInfo> list = [];
    for (var data in methods) {
      final method = OtpMethod.values
          .firstWhere((element) => element.name == data.method.toLowerCase());
      final String target = method == OtpMethod.email
          ? state.accountInfo.username
          : data.targetValue;
      list.add(OtpInfo(
          method: method,
          methodId: data.id ?? '',
          data: target,
          maskedData: data.targetValue));
    }

    AccountInfo accountInfo = state.accountInfo.copyWith(otpInfo: list);
    emit(state.copyWith(accountInfo: accountInfo));
    return accountInfo;
  }

  Future<AccountInfo> _handleLoginPassword(
      CloudLoginState cloudLoginState) async {
    logger.d("handle login password: $cloudLoginState");
    final LoginType loginType = cloudLoginState.state == 'REQUIRED_2SV'
        ? LoginType.otp
        : LoginType.password;

    AccountInfo accountInfo = state.accountInfo.copyWith(loginType: loginType);
    emit(state.copyWith(accountInfo: accountInfo));
    return accountInfo;
  }

  Future<void> _handleLogin(CloudLoginState cloudLoginState) async {
    logger.d("handle login: $cloudLoginState");
  }

  // ---------------------------------------------------------------------------

  Future<void> forgotPassword() async {
    return await _repository.forgotPassword();
  }

  Future<DummyModel> resetPassword(String password) async {
    return await _repository.resetPassword(password);
  }

  _handleError(Object? error, StackTrace stackTrace, emit) {
    logger.d("error handler: $error, $stackTrace");
  }
}

extension AuthBlocLocal on AuthBloc {
  Future<DummyModel> localLogin(String password) async {
    return await _localAuthRepository.localLogin(password);
  }

  Future<DummyModel> verifyRecoveryKey(String key) async {
    return await _localAuthRepository.verifyRecoveryKey(key);
  }

  Future<String> getMaskedEmail() async {
    return await _localAuthRepository
        .getMaskedEmail()
        .then((value) => value['maskedEmail']);
  }

  Future<AdminPasswordInfo> getAdminPasswordInfo() async {
    return await _localAuthRepository.getAdminPasswordInfo().then((value) =>
        AdminPasswordInfo(
            hasAdminPassword: value['hasAdminPassword'] ?? false,
            hint: value['hint'] ?? ''));
  }

  Future<DummyModel> getAccountInfo() async {
    return await _localAuthRepository.getCloudAccount();
  }

  Future<DummyModel> createPassword(String password, String hint) async {
    return await _localAuthRepository.createPassword(password, hint);
  }
}
