import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/constants/pref_key.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_login_certs.dart';
import 'package:moab_poc/network/http/model/cloud_task_model.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/authenticate/local_auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/http/model/cloud_account_info.dart';
import '../../network/http/model/cloud_auth_clallenge_method.dart';
import '../../network/http/model/cloud_create_account_verified.dart';
import '../../network/http/model/cloud_login_state.dart';
import '../../network/http/model/cloud_preferences.dart';

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
    on<RequireOtpCode>(_onRequireOtpCode);
    on<SetCloudPassword>(_onSetCloudPassword);
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

  void _onRequireOtpCode(RequireOtpCode event, Emitter<AuthState> emit) {
    switch (state.status) {
      case AuthStatus.onCreateAccount:
        createAccountPreparationUpdateMethod(event.otpInfo)
            .then((_) => authChallenge(event.otpInfo));
        break;
      case AuthStatus.onLogin:
        authChallenge(event.otpInfo);
        break;
      default:
        break;
    }
  }

  void _onSetCloudPassword(SetCloudPassword event, Emitter<AuthState> emit) {
    AccountInfo info = state.accountInfo
        .copyWith(password: event.password, loginType: LoginType.password);
    emit(state.copyWith(accountInfo: info));
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

  Future<void> authChallenge(OtpInfo method) async {
    return await _repository.authChallenge(AuthChallengeMethod(
        token: state.vToken,
        method: method.method.name.toUpperCase(),
        target: method.data));
  }

  Future<void> authChallengeVerify(String code) async {
    return await _repository.authChallengeVerify(state.vToken, code);
  }

  Future<AccountInfo> loginPassword(String password) async {
    return await _repository
        .loginPassword(state.vToken, password)
        .then((value) => _handleLoginPassword(value));
  }

  Future<bool> login() async {
    return await _repository
        .login(state.vToken)
        .then((value) => _handleLogin(value));
  }

  Future<void> createAccountPreparation(String email) async {
    return await _repository
        .createAccountPreparation(email)
        .then((value) => _handleCreateAccountPreparation(email, value));
  }

  Future<void> createAccountPreparationUpdateMethod(OtpInfo otpInfo) async {
    CommunicationMethod method = CommunicationMethod(
        method: OtpMethod.email.name.toUpperCase(), targetValue: otpInfo.data);
    switch (otpInfo.method) {
      case OtpMethod.email:
        break;
      case OtpMethod.sms:
        method = CommunicationMethod(
            method: OtpMethod.sms.name.toUpperCase(),
            targetValue: otpInfo.data);
        break;
      default:
        break;
    }
    return await _repository.createAccountPreparationUpdateMethod(
        state.vToken, method);
  }

  Future<void> createVerifiedAccount() async {
    // TODO: Need be modified
    CreateAccountVerified verified = CreateAccountVerified(
        token: state.vToken,
        authenticationMode: state.accountInfo.loginType.name.toUpperCase(),
        password: state.accountInfo.loginType == LoginType.password
            ? state.accountInfo.password
            : null,
        preferences: const CloudPreferences(
            isoLanguageCode: 'zh',
            isoCountryCode: 'TW',
            timeZone: 'Asia/Taipei'));
    return await _repository
        .createVerifiedAccount(verified)
        .then((value) => _handleCreateVerifiedAccount(value));
  }

  Future<AccountInfo> fetchOtpInfo(String username) async {
    switch (state.status) {
      case AuthStatus.onCreateAccount:
        List<OtpInfo> list = [];
        list.add(const OtpInfo(
          method: OtpMethod.sms,
          data: '',
        ));
        list.add(OtpInfo(
          method: OtpMethod.email,
          data: username,
        ));
        AccountInfo accountInfo = state.accountInfo.copyWith(otpInfo: list);
        emit(state.copyWith(accountInfo: accountInfo));
        return accountInfo;
      case AuthStatus.onLogin:
        return await getMaskedCommunicationMethods(username);
      default:
        return AccountInfo(
            username: username, loginType: LoginType.otp, otpInfo: []);
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

  Future<bool> _handleLogin(CloudLoginAcceptState acceptState) async {
    logger.d("handle login: $acceptState");
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final downloadTime = acceptState.data.downloadTime * 1000;
    final delta = downloadTime - currentTime;
    if (delta > 0) {
      await Future.delayed(Duration(milliseconds: delta));
    }
    await _repository.downloadCloudCert(
        taskId: acceptState.data.taskId, secret: acceptState.data.certSecret);
    return checkCertValidation();
  }

  Future<void> _handleCreateAccountPreparation(
      String email, String token) async {
    logger.d("handle create Account Preparation: $token");
    AccountInfo info = state.accountInfo.copyWith(username: email);
    emit(state.copyWith(vToken: token, accountInfo: info));
  }

  Future<void> _handleCreateVerifiedAccount(CloudAccountInfo info) async {
    logger.d("handle Create Verified Account: $info");
    // Put needed info to state
    // emit(state.copyWith());

    // Download cert (do log in) in future
    add(Authorized());
  }

  Future<bool> checkCertValidation() async {
    final isPrivateExist = File.fromUri(Storage.appPrivateKeyUri).existsSync();
    final isPublicExist = File.fromUri(Storage.appPublicKeyUri).existsSync();
    // final prefs = await SharedPreferences.getInstance();
    // final certData = CloudDownloadCertData.fromJson(
    //     jsonDecode(prefs.getString(moabPrefCloudCertDataKey) ?? ''));

    // TODO check expiration
    return isPrivateExist & isPublicExist;
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
    return await _localAuthRepository
        .createPassword(password, hint)
        .then((value) => _handleCreatePassword(password, hint));
  }

  _handleCreatePassword(String password, String? hint) {
    LocalLoginInfo info = state.localLoginInfo
        .copyWith(routerPassword: password, routerPasswordHint: hint);
    emit(state.copyWith(localLoginInfo: info));
  }
}
