import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/network/http/model/cloud_phone.dart';
import 'package:linksys_moab/network/http/model/cloud_task_model.dart';
import 'package:linksys_moab/repository/authenticate/auth_repository.dart';
import 'package:linksys_moab/repository/authenticate/local_auth_repository.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import '../../constants/cloud_const.dart';
import '../../network/http/model/cloud_account_info.dart';
import '../../network/http/model/cloud_auth_clallenge_method.dart';
import '../../network/http/model/cloud_create_account_verified.dart';
import '../../network/http/model/cloud_login_state.dart';
import '../../network/http/model/cloud_preferences.dart';
import '../../utils.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final LocalAuthRepository _localAuthRepository;

  AuthBloc(
      {required AuthRepository repo, required LocalAuthRepository localRepo})
      : _repository = repo,
        _localAuthRepository = localRepo,
        super(AuthState.unknownAuth()) {
    on<InitAuth>(_onInitAuth);
    on<OnCloudLogin>(_onCloudLogin);
    on<OnLocalLogin>(_onLocalLogin);
    on<OnCreateAccount>(_onCreateAccount);
    on<Unauthorized>(_unauthorized);
    on<Authorized>(_authorized);
    on<RequireOtpCode>(_onRequireOtpCode);
    on<SetOtpInfo>(_onSetOtpInfo);
    on<SetLoginType>(_onSetLoginType);
    on<SetCloudPassword>(_onSetCloudPassword);
    on<CloudLogin>(_cloudLogin);
    on<LocalLogin>(_localLogin);
    on<Logout>(_onLogout);
  }

  _onInitAuth(InitAuth event, Emitter<AuthState> emit) async {
    logger.d('check auth status');
    final isValid = await checkCertValidation();
    logger.d('is auth valid: $isValid');
    if (isValid) {
      // TODO: Get key and accountInfo from shared preference
      emit(AuthState.authorized(
          accountInfo: AccountInfo.empty(), publicKey: '', privateKey: ''));
    } else {
      emit(AuthState.unAuthorized());
    }
  }

  _onCloudLogin(OnCloudLogin event, Emitter<AuthState> emit) {
    emit(AuthState.onCloudLogin(
        accountInfo: event.accountInfo, vToken: event.vToken));
  }

  _onLocalLogin(OnLocalLogin event, Emitter<AuthState> emit) {
    emit(AuthState.onLocalLogin(localLoginInfo: event.localLoginInfo));
  }

  _onCreateAccount(OnCreateAccount event, Emitter<AuthState> emit) {
    emit(AuthState.onCreateAccount(
        accountInfo: event.accountInfo, vToken: event.vToken));
  }

  _unauthorized(Unauthorized event, Emitter<AuthState> emit) {
    emit(AuthState.unAuthorized());
  }

  _authorized(Authorized event, Emitter<AuthState> emit) {
    emit(AuthState.authorized(
        accountInfo: event.accountInfo,
        publicKey: event.publicKey,
        privateKey: event.privateKey));
  }

  void _onRequireOtpCode(RequireOtpCode event, Emitter<AuthState> emit) {
    switch (state.runtimeType) {
      case AuthOnCreateAccountState:
        createAccountPreparationUpdateMethod(event.otpInfo)
            .then((_) => authChallenge(event.otpInfo));
        break;
      case AuthOnCloudLoginState:
        authChallenge(event.otpInfo);
        break;
      default:
        break;
    }
  }

  void _onSetOtpInfo(SetOtpInfo event, Emitter<AuthState> emit) {
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(otpInfo: event.otpInfo);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else if (_state is AuthOnCreateAccountState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(otpInfo: event.otpInfo);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else {
      logger.d('ERROR: _onSetOtpInfo: Unexpected state type');
    }
  }

  void _onSetLoginType(SetLoginType event, Emitter<AuthState> emit) {
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(loginType: event.loginType);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else if (_state is AuthOnCreateAccountState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(loginType: event.loginType);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else {
      logger.d('ERROR: _onSetOtpInfo: Unexpected state type');
    }
  }

  void _onSetCloudPassword(SetCloudPassword event, Emitter<AuthState> emit) {
    final _state = state;
    if (_state is AuthOnCreateAccountState) {
      AccountInfo accountInfo = _state.accountInfo.copyWith(
          password: event.password,
          loginType: event.password.isEmpty
              ? LoginType.passwordless
              : LoginType.password);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else {
      logger.d('ERROR: _onSetCloudPassword: Unexpected state type');
    }
  }

  void _cloudLogin(CloudLogin event, Emitter<AuthState> emit) {
    cloudLogin().then((value) {
      if (value == true) {
        // TODO: Get key from shared preference
        add(Authorized(
            accountInfo: (state as AuthOnCloudLoginState).accountInfo,
            publicKey: 'publicKey',
            privateKey: 'privateKey'));
      } else {
        add(Unauthorized());
      }
    });
  }

  void _localLogin(LocalLogin event, Emitter<AuthState> emit) {}

  void _onLogout(Logout event, Emitter<AuthState> emit) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(moabPrefCloudCertDataKey);
      prefs.remove(moabPrefCloudPublicKey);
      prefs.remove(moabPrefCloudPrivateKey);
      emit(AuthState.unAuthorized());
    });
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    logger.d("AuthBloc:: onTransition: $transition");
  }
}

extension AuthBlocCloud on AuthBloc {
  Future<void> loginPrepare(String username) async {
    // Reset state
    add(OnCloudLogin(accountInfo: AccountInfo.empty(), vToken: ''));
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
    String vToken = '';
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      vToken = _state.vToken;
    } else if (_state is AuthOnCreateAccountState) {
      vToken = _state.vToken;
    } else {
      logger.d('ERROR: authChallenge: Unexpected state type');
    }

    BaseAuthChallenge challenge;
    if (method.methodId.isNotEmpty) {
      challenge =
          AuthChallengeMethodId(token: vToken, commMethodId: method.methodId);
    } else {
      challenge = AuthChallengeMethod(
        token: vToken,
        method: method.method.name.toUpperCase(),
        target: method.data,
      );
    }
    return await _repository.authChallenge(challenge);
  }

  Future<void> authChallengeVerify(String code) async {
    String vToken = '';
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      vToken = _state.vToken;
    } else if (_state is AuthOnCreateAccountState) {
      vToken = _state.vToken;
    } else {
      logger.d('ERROR: authChallengeVerify: Unexpected state type');
    }

    return await _repository.authChallengeVerify(vToken, code);
  }

  Future<void> loginPassword(String password) async {
    // Reset state
    add(SetLoginType(loginType: LoginType.password));
    return await _repository
        .loginPassword((state as AuthOnCloudLoginState).vToken, password)
        .then((value) => _handleLoginPassword(value));
  }

  Future<bool> cloudLogin() async {
    return await _repository
        .login((state as AuthOnCloudLoginState).vToken)
        .then((value) => _handleLogin(value));
  }

  Future<void> createAccountPreparation(String email) async {
    // Reset state
    add(OnCreateAccount(accountInfo: AccountInfo.empty(), vToken: ''));
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
        // TODO throw exception if there has no phone number information
        assert(otpInfo.phoneNumber != null);
        final phoneNumber = otpInfo.phoneNumber!;
        method = CommunicationMethod(
            method: OtpMethod.sms.name.toUpperCase(),
            targetValue: otpInfo.data,
            phone: phoneNumber);
        break;
      default:
        break;
    }
    return await _repository.createAccountPreparationUpdateMethod(
        (state as AuthOnCreateAccountState).vToken, method);
  }

  Future<void> createVerifiedAccount() async {
    final _state = state as AuthOnCreateAccountState;
    CreateAccountVerified verified = CreateAccountVerified(
        token: _state.vToken,
        authenticationMode: _state.accountInfo.loginType.name.toUpperCase(),
        password: _state.accountInfo.loginType == LoginType.password
            ? _state.accountInfo.password
            : null,
        preferences: CloudPreferences(
            isoLanguageCode: Utils.getLanguageCode(),
            isoCountryCode: Utils.getCountryCode(),
            timeZone: await Utils.getTimeZone()));
    return await _repository
        .createVerifiedAccount(verified)
        .then((value) => _handleCreateVerifiedAccount(value));
  }

  Future<AccountInfo> fetchOtpInfo(String username) async {
    switch (state.runtimeType) {
      case AuthOnCreateAccountState:
        List<OtpInfo> list = [];
        list.add(const OtpInfo(
          method: OtpMethod.sms,
          data: '',
        ));
        list.add(OtpInfo(
          method: OtpMethod.email,
          data: username,
        ));

        add(SetOtpInfo(otpInfo: list));
        AccountInfo accountInfo = (state as AuthOnCreateAccountState)
            .accountInfo
            .copyWith(otpInfo: list);
        return accountInfo;
      case AuthOnCloudLoginState:
        return await getMaskedCommunicationMethods(username);
      default:
        return AccountInfo(
            username: username, loginType: LoginType.passwordless, otpInfo: []);
    }
  }

  Future<void> _handleLoginPrepare(
      String username, CloudLoginState cloudLoginState) async {
    logger.d("handle login prepare: $cloudLoginState");

    LoginType loginType = LoginType.passwordless;
    switch (cloudLoginState.state) {
      case keyRequire2sv:
        loginType = LoginType.passwordless;
        break;
      case keyPasswordRequired:
        loginType = LoginType.password;
        break;
      default:
        logger.d("error: cloud Login State = ${cloudLoginState.state}");
        break;
    }

    AccountInfo accountInfo =
        AccountInfo(username: username, loginType: loginType, otpInfo: []);
    add(OnCloudLogin(
        accountInfo: accountInfo, vToken: cloudLoginState.data?.token ?? ''));
  }

  Future<AccountInfo> _handleGetMaskedCommunicationMethods(
      List<CommunicationMethod> methods) async {
    logger.d("handle get Masked Communication Methods: $methods");

    List<OtpInfo> list = [];
    for (var data in methods) {
      final method = OtpMethod.values
          .firstWhere((element) => element.name == data.method.toLowerCase());
      final String target = method == OtpMethod.email
          ? (state as AuthOnCloudLoginState).accountInfo.username
          : data.targetValue;
      list.add(OtpInfo(
          method: method,
          methodId: data.id ?? '',
          data: target,
          maskedData: data.targetValue));
    }

    add(SetOtpInfo(otpInfo: list));
    AccountInfo accountInfo =
        (state as AuthOnCloudLoginState).accountInfo.copyWith(otpInfo: list);
    return accountInfo;
  }

  Future<void> _handleLoginPassword(CloudLoginState cloudLoginState) async {
    logger.d("handle login password: $cloudLoginState");
    final LoginType loginType = cloudLoginState.state == keyRequire2sv
        ? LoginType.passwordless
        : LoginType.password;

    add(SetLoginType(loginType: loginType));
  }

  Future<bool> _handleLogin(CloudLoginAcceptState acceptState) async {
    logger.d("handle login: $acceptState");
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final downloadTime = acceptState.data.downloadTime * 1000;
    final delta = downloadTime - currentTime + 1000;
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
    AccountInfo accountInfo = AccountInfo(
        username: email, loginType: LoginType.passwordless, otpInfo: []);
    add(OnCreateAccount(accountInfo: accountInfo, vToken: token));
  }

  Future<void> _handleCreateVerifiedAccount(CloudAccountInfo info) async {
    logger.d("handle Create Verified Account: $info");
    // Put needed info to state
    // emit(state.copyWith());

    // Download cert (do log in) in future
    add(Authorized(
        accountInfo: (state as AuthOnCreateAccountState).accountInfo,
        publicKey: '',
        privateKey: ''));
  }

  Future<bool> checkCertValidation() async {
    final prefs = await SharedPreferences.getInstance();
    bool isKeyExist = prefs.containsKey(moabPrefCloudPublicKey) &
        prefs.containsKey(moabPrefCloudPrivateKey) &
        prefs.containsKey(moabPrefCloudCertDataKey);
    if (!isKeyExist) {
      return false;
    }
    final certData = CloudDownloadCertData.fromJson(
        jsonDecode(prefs.getString(moabPrefCloudCertDataKey) ?? ''));
    final expiredDate = DateTime.parse(certData.expiration);
    if (expiredDate.millisecondsSinceEpoch -
            DateTime.now().millisecondsSinceEpoch <
        0) {
      return false;
    }
    return true;
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
    // LocalLoginInfo info = state.localLoginInfo
    //     .copyWith(routerPassword: password, routerPasswordHint: hint);
    // emit(state.copyWith(localLoginInfo: info));
  }
}
