import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_login_certs.dart';
import 'package:linksys_moab/network/http/model/cloud_session_data.dart';
import 'package:linksys_moab/network/http/model/cloud_task_model.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';
import 'package:linksys_moab/repository/authenticate/auth_repository.dart';
import 'package:linksys_moab/repository/model/dummy_model.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/cloud_const.dart';
import '../../network/http/model/cloud_account_info.dart';
import '../../network/http/model/cloud_auth_clallenge_method.dart';
import '../../network/http/model/cloud_create_account_verified.dart';
import '../../network/http/model/cloud_login_state.dart';
import '../../network/http/model/cloud_preferences.dart';
import '../../utils.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> with StateStreamRegister {
  final AuthRepository _repository;
  final RouterRepository _routerRepository;
  StreamSubscription? _errorStreamSubscription;

  AuthBloc({
    required AuthRepository repo,
    required RouterRepository routerRepo,
  })  : _repository = repo,
        _routerRepository = routerRepo,
        super(AuthState.unknownAuth()) {
    on<InitAuth>(_onInitAuth);
    on<OnCloudLogin>(_onCloudLogin);
    on<OnLocalLogin>(_onLocalLogin);
    on<OnCreateAccount>(_onCreateAccount);
    on<Unauthorized>(_unauthorized);
    on<Authorized>(_authorized);
    on<SetLoginType>(_onSetLoginType);
    on<SetCloudPassword>(_onSetCloudPassword);
    on<SetEnableBiometrics>(_onSetEnableBiometrics);
    on<CloudLogin>(_cloudLogin);
    on<LocalLogin>(_localLogin);
    on<Logout>(_onLogout);
    on<OnRequestSession>(_onRequestSession);

    //
    _errorStreamSubscription = errorResponseStream.listen((error) {
      logger.e(
          'Receive http response error: ${error.status}, ${error.code}, ${error.errorMessage}');
      if (error.status == 401) {
        add(Unauthorized());
      }
    });
    //
    shareStream = stream;
    register(routerRepo);
  }

  @override
  Future<void> close() {
    _errorStreamSubscription?.cancel();
    return super.close();
  }

  _onInitAuth(InitAuth event, Emitter<AuthState> emit) async {
    // TODO add local auth check
    logger.d('check auth status');
    final isValid = await checkCertValidation();
    logger.d('is auth valid: $isValid');
    if (isValid) {
      if (await isSessionExpired()) {
        emit(AuthState.unAuthorized());
      }

      emit(AuthState.cloudAuthorized());
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
    if (event.isDuringSetup) {
    } else if (event.isCloud) {
      emit(AuthState.cloudAuthorized());
    } else {
      emit(AuthState.localAuthorized());
    }
  }

  void _onSetLoginType(SetLoginType event, Emitter<AuthState> emit) {
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(authenticationType: event.loginType);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else if (_state is AuthOnCreateAccountState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(authenticationType: event.loginType);
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
          authenticationType: event.password.isEmpty
              ? AuthenticationType.passwordless
              : AuthenticationType.password);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else {
      logger.d('ERROR: _onSetCloudPassword: Unexpected state type');
    }
  }

  void _onSetEnableBiometrics(
      SetEnableBiometrics event, Emitter<AuthState> emit) async {
    // Save to preference
    final pref = await SharedPreferences.getInstance();
    pref.setBool(moabPrefEnableBiometrics, event.enableBiometrics);
    // Set to state
    final _state = state;
    if (_state is AuthOnCloudLoginState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(enableBiometrics: event.enableBiometrics);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else if (_state is AuthOnCreateAccountState) {
      AccountInfo accountInfo =
          _state.accountInfo.copyWith(enableBiometrics: event.enableBiometrics);
      emit(_state.copyWith(accountInfo: accountInfo));
    } else if (_state is AuthOnLocalLoginState) {
      LocalLoginInfo localLoginInfo = _state.localLoginInfo
          .copyWith(enableBiometrics: event.enableBiometrics);
      emit(_state.copyWith(localLoginInfo: localLoginInfo));
    } else {
      logger.d('ERROR: _onSetCloudPassword: Unexpected state type');
    }
  }

  void _cloudLogin(CloudLogin event, Emitter<AuthState> emit) async {
    final pref = await SharedPreferences.getInstance();

    var isLogin = false;
    if (state is AuthOnCreateAccountState) {
      isLogin = await checkCertValidation();
    } else {
      isLogin = await cloudLogin();
    }

    if (isLogin) {
      AccountInfo? accountInfo;
      final _state = state;
      if (_state is AuthOnCloudLoginState) {
        accountInfo = _state.accountInfo;
      } else if (_state is AuthOnCreateAccountState) {
        accountInfo = _state.accountInfo;
      } else {
        throw Exception('Invalid cloud login state');
      }

      if (accountInfo.enableBiometrics) {
        bool canUseBiometrics = await Utils.canUseBiometrics();
        bool didAuthenticate = await Utils.doLocalAuthenticate();
        if (!canUseBiometrics || !didAuthenticate) {
          // Disable or cancel authentication, set enableBiometrics to false
          final pref = await SharedPreferences.getInstance();
          pref.remove(moabPrefEnableBiometrics);
          accountInfo = accountInfo.copyWith(enableBiometrics: false);
        } else {
          // Todo Cloud blocked exchange 2y certs if enrolled biometrics
          await extendCertification();
          await requestSession();
        }
      }

      await CloudEnvironmentManager().checkSmartDevice();
      emit(AuthState.cloudAuthorized());
    } else {
      // TODO
      add(Unauthorized());
    }
  }

  _onRequestSession(OnRequestSession event, Emitter<AuthState> emit) async {
    await requestSession();
    if (await isSessionExpired()) {
      add(Unauthorized());
    } else {}
  }

  void _localLogin(LocalLogin event, Emitter<AuthState> emit) async {
    // Authorized
    final pref = await SharedPreferences.getInstance();
    pref.setString(moabPrefLocalPassword, event.password);
    emit(AuthState.localAuthorized());
  }

  void _onLogout(Logout event, Emitter<AuthState> emit) {
    // Don't remove all keys on shared preferences when logging out if biometric is enabled
    SharedPreferences.getInstance().then((prefs) {
      final isEnableBiometric = prefs.getBool(moabPrefEnableBiometrics) ?? false;
      if (isEnableBiometric) {
        prefs.remove(moabPrefSessionDataKey);
      } else {
        prefs.remove(moabPrefCloudCertDataKey);
        prefs.remove(moabPrefCloudPublicKey);
        prefs.remove(moabPrefCloudPrivateKey);
      }
      emit(AuthState.unAuthorized());
    });
  }

  Future<List<RegionCode>> fetchRegionCodes() {
    return _repository.fetchRegionCodes();
  }

  Future<ChangeAuthenticationModeChallenge> changeAuthModePrepare(String accountId, String? password , String authenticationMode) async {
    return await _repository.changeAuthenticationModePrepare(accountId, password, authenticationMode);
  }

  Future<void> changeAuthMode(String accountId, String token, String? password) {
    return _repository.changeAuthenticationMode(accountId, token, password);
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    logger.d("AuthBloc:: onTransition: $transition");
  }

  bool isCloudLogin() {
    return state is AuthCloudLoginState;
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

  Future<void> loginPassword(String password) async {
    // Reset state
    add(SetLoginType(loginType: AuthenticationType.password));
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

  Future<void> createAccountPreparationUpdateMethod(
      {required CommunicationMethod method, required String token}) async {
    // CommunicationMethod method = CommunicationMethod(
    //     method: CommunicationMethodType.email.name.toUpperCase(), targetValue: otpInfo.data);
    // switch (otpInfo.method) {
    //   case CommunicationMethodType.email:
    //     break;
    //   case CommunicationMethodType.sms:
    //     // TODO throw exception if there has no phone number information
    //     assert(otpInfo.phoneNumber != null);
    //     final phoneNumber = otpInfo.phoneNumber!;
    //     method = CommunicationMethod(
    //         method: CommunicationMethodType.sms.name.toUpperCase(),
    //         targetValue: otpInfo.data,
    //         phone: phoneNumber);
    //     break;
    //   default:
    //     break;
    // }
    return await _repository.createAccountPreparationUpdateMethod(token, method);
  }

  Future<void> createVerifiedAccount() async {
    final _state = state as AuthOnCreateAccountState;
    CreateAccountVerified verified = CreateAccountVerified(
        token: _state.vToken,
        authenticationMode:
            _state.accountInfo.authenticationType.name.toUpperCase(),
        password:
            _state.accountInfo.authenticationType == AuthenticationType.password
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

  // Future<AccountInfo> fetchOtpInfo(String username) async {
  //   switch (state.runtimeType) {
  //     case AuthOnCreateAccountState:
  //       List<OtpInfo> list = [];
  //       list.add(const OtpInfo(
  //         method: CommunicationMethodType.sms,
  //         data: '',
  //       ));
  //       list.add(OtpInfo(
  //         method: CommunicationMethodType.email,
  //         data: username,
  //       ));
  //
  //       add(SetOtpInfo(otpInfo: list));
  //       AccountInfo accountInfo = (state as AuthOnCreateAccountState)
  //           .accountInfo
  //           .copyWith(otpInfo: list);
  //       return accountInfo;
  //     case AuthOnCloudLoginState:
  //       return await getMaskedCommunicationMethods(username);
  //     default:
  //       return AccountInfo(
  //           username: username, loginType: LoginType.passwordless, otpInfo: []);
  //   }
  // }

  Future<void> _handleLoginPrepare(
      String username, CloudLoginState cloudLoginState) async {
    logger.d("handle login prepare: $cloudLoginState");

    AuthenticationType loginType = AuthenticationType.passwordless;
    switch (cloudLoginState.state) {
      case keyRequire2sv:
        loginType = AuthenticationType.passwordless;
        break;
      case keyPasswordRequired:
        loginType = AuthenticationType.password;
        break;
      default:
        logger.d("error: cloud Login State = ${cloudLoginState.state}");
        break;
    }

    AccountInfo accountInfo = AccountInfo(
        username: username,
        authenticationType: loginType,
        communicationMethods: []);
    add(OnCloudLogin(
        accountInfo: accountInfo, vToken: cloudLoginState.data?.token ?? ''));
  }

  Future<AccountInfo> _handleGetMaskedCommunicationMethods(
      List<CommunicationMethod> methods) async {
    logger.d("handle get Masked Communication Methods: $methods");
    //
    // List<OtpInfo> list = [];
    // for (var data in methods) {
    //   final method = CommunicationMethodType.values
    //       .firstWhere((element) => element.name == data.method.toLowerCase());
    //   final String target = method == CommunicationMethodType.email
    //       ? (state as AuthOnCloudLoginState).accountInfo.username
    //       : data.targetValue;
    //   list.add(OtpInfo(
    //       method: method,
    //       methodId: data.id ?? '',
    //       data: target,
    //       maskedData: data.targetValue));
    // }

    AccountInfo accountInfo = (state as AuthOnCloudLoginState)
        .accountInfo
        .copyWith(communicationMethods: methods);
    return accountInfo;
  }

  Future<void> _handleLoginPassword(CloudLoginState cloudLoginState) async {
    logger.d("handle login password: $cloudLoginState");
    final AuthenticationType loginType = cloudLoginState.state == keyRequire2sv
        ? AuthenticationType.passwordless
        : AuthenticationType.password;

    add(SetLoginType(loginType: loginType));
  }

  Future<bool> _handleLogin(CloudLoginAcceptState acceptState) async {
    logger.d("handle login: $acceptState");
    await delayDownloadCertTime(acceptState.data.downloadTime);

    await _repository.downloadCloudCert(
        taskId: acceptState.data.taskId, secret: acceptState.data.certSecret);
    return checkCertValidation();
  }

  Future<void> _handleCreateAccountPreparation(
      String email, String token) async {
    logger.d("handle create Account Preparation: $token");
    List<CommunicationMethod> methods = [
      CommunicationMethod(
        method: CommunicationMethodType.sms.name.toUpperCase(),
        targetValue: '',
      ),
      CommunicationMethod(
        method: CommunicationMethodType.email.name.toUpperCase(),
        targetValue: email,
      )
    ];

    AccountInfo accountInfo = AccountInfo(
        username: email,
        authenticationType: AuthenticationType.passwordless,
        communicationMethods: methods);
    add(OnCreateAccount(accountInfo: accountInfo, vToken: token));
  }

  Future<void> _handleCreateVerifiedAccount(CloudAccountVerifyInfo info) async {
    logger.d("handle Create Verified Account: $info");
    await delayDownloadCertTime(info.certInfo.downloadTime);
    await _repository.downloadCloudCert(
        taskId: info.certInfo.taskId, secret: info.certInfo.certSecret);
  }

  Future<bool> checkCertValidation() async {
    const storage = FlutterSecureStorage();
    String? privateKey = await storage.read(key: moabPrefCloudPrivateKey);
    String? cert = await storage.read(key: moabPrefCloudCertDataKey);

    final prefs = await SharedPreferences.getInstance();
    bool isKeyExist = prefs.containsKey(moabPrefCloudPublicKey) &
        (privateKey != null) &
        (cert != null);
    if (!isKeyExist) {
      return false;
    }
    final certData = CloudDownloadCertData.fromJson(
        jsonDecode(cert ?? ''));
    final expiredDate = DateTime.parse(certData.expiration);
    if (expiredDate.millisecondsSinceEpoch -
            DateTime.now().millisecondsSinceEpoch <
        0) {
      return false;
    }
    return true;
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(moabPrefSessionDataKey)) {
      final sessionData = CloudSessionData.fromJson(
          jsonDecode(prefs.getString(moabPrefSessionDataKey)!));
      final sessionExpiredDate = DateTime.parse(sessionData.expiration);
      if (sessionExpiredDate.millisecondsSinceEpoch -
              DateTime.now().millisecondsSinceEpoch <
          0) {
        return true;
      }
    }
    return false;
  }

  Future<void> extendCertification() async {
    const storage = FlutterSecureStorage();
    String? cert = await storage.read(key: moabPrefCloudCertDataKey);
    if (cert == null) {
      logger.d('extend certification: original cert data does not exist!');
      return;
    }
    final certData = CloudDownloadCertData.fromJson(jsonDecode(cert!));
    final newCertInfo =
        await _repository.extendCertificate(certId: certData.id);
    await delayDownloadCertTime(newCertInfo.downloadTime);
    await _repository.downloadCloudCert(
        taskId: newCertInfo.taskId, secret: newCertInfo.certSecret);
    checkCertValidation();
  }

  Future<void> requestSession() async {
    const storage = FlutterSecureStorage();
    String? cert = await storage.read(key: moabPrefCloudCertDataKey);
    if (cert == null) {
      logger.d('extend certification: original cert data does not exist!');
      return;
    }
    final certData = CloudDownloadCertData.fromJson(jsonDecode(cert!));
    final session = await _repository.requestSession(certId: certData.id);
    final pref = await SharedPreferences.getInstance();
    pref.setString(moabPrefSessionDataKey, jsonEncode(session.toJson()));
  }

  Future<void> delayDownloadCertTime(int delay) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final downloadTime = delay * 1000;
    final delta = downloadTime - currentTime + 1000;
    if (delta > 0) {
      await Future.delayed(Duration(milliseconds: delta));
    }
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
  Future<bool> localLogin(String password) async {
    final result = await _routerRepository.checkAdminPassword(password);
    if (result.result == jnapResultOk) {
      add(LocalLogin(password));
      return true;
    }
    return false;
  }

  Future<AdminPasswordInfo> getAdminPasswordInfo() async {
    return await _routerRepository.getAdminPasswordHint().then((value) =>
        AdminPasswordInfo(
            hasAdminPassword: value.output.containsKey('passwordHint'),
            hint: value.output['passwordHint'] ?? ''));
  }

  Future<DummyModel> createPassword(String password, String hint) async {
    return await _routerRepository
        .createAdminPassword(password, hint)
        .then((value) => _handleCreatePassword(password, hint));
  }

  _handleCreatePassword(String password, String? hint) {
    // LocalLoginInfo info = state.localLoginInfo
    //     .copyWith(routerPassword: password, routerPasswordHint: hint);
    // emit(state.copyWith(localLoginInfo: info));
  }
}
