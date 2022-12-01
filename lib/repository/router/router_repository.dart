import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/jnap/command/http_base_command.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';

class CommandWrap {
  CommandWrap({
    required this.action,
    required this.needAuth,
    this.data = const {},
  });

  final String action;
  final bool needAuth;
  Map<String, dynamic> data;
}

class RouterRepository with StateStreamListener {
  RouterRepository() {
    CloudEnvironmentManager().register(this);
  }

  final MoabHttpClient _client = MoabHttpClient();

  // To expose interface
  JNAPCommandExecutor? get executor => _client;

  String _localPassword = '';
  String _cloudToken = '';

  String _localIp = '';
  String? _groupId;
  String? _networkId;

  LoginFrom _loginType = LoginFrom.none;
  RouterType _routerType = RouterType.others;

  bool _btSetupMode = false;
  set enableBTSetup(bool isEnable) => _btSetupMode = isEnable;
  bool get isEnableBTSetup => _btSetupMode;

  // JNAPTransaction createTransaction(List<Map<String, dynamic>> payload) {
  //   logger.d('create transaction');
  //   throw Exception();
  // }

  JNAPHttpCommand<JNAPResult> createCommand(String action,
      {Map<String, dynamic> data = const {}, bool needAuth = false}) {
    String url;
    Map<String, String> header = {};
    switch (_routerType) {
      case RouterType.others:

        /// MUST Remote
        /// Authorization: TOKEN
        /// NetworkId: {NetworkId}
        url = _loginType == LoginFrom.remote
            ? cloudEnvironmentConfig[kCloudJNAP]
            : 'https://$_localIp/JNAP/';
        header = {
          HttpHeaders.authorizationHeader: 'LinksysUserAuth session_token = $_cloudToken',
          kJNAPNetworkId: _networkId ?? '',
        };
        break;
      case RouterType.behind:

        /// MUST Remote
        /// Authorization: TOKEN
        /// NetworkId: {NetworkId}
        ///
        url = _loginType == LoginFrom.remote
            ? 'https://$_localIp/cloud/JNAP/'
            : 'https://$_localIp/JNAP/';
        header = {
          HttpHeaders.authorizationHeader: _cloudToken,
          kJNAPNetworkId: _networkId ?? '',
        };
        break;
      case RouterType.behindManaged:

        /// Local:
        /// X-JNAP-AUTHxxx : Basic base64
        ///
        /// Remote:
        /// X-JNAP-Session : Token
        ///
        final authKey =
            _loginType == LoginFrom.remote ? kJNAPSession : kJNAPAuthorization;
        final authValue = _loginType == LoginFrom.remote
            ? _cloudToken
            : 'Basic ${Utils.stringBase64Encode('admin:${_loginType == LoginFrom.none ? 'admin' : _localPassword}')}';
        url = 'https://$_localIp/JNAP/';
        header = {
          authKey:
              (needAuth | (_loginType == LoginFrom.remote)) ? authValue : '',
        };
        break;
    }
    header.removeWhere((key, value) => value.isEmpty);
    if (url.isNotEmpty) {
      return JNAPHttpCommand(
        url: url,
        action: action,
        data: data,
        extraHeader: header,
      );
    } else {
      throw Exception();
    }
  }

  Stream<JNAPResult> scheduledCommand({
    required JNAPAction action,
    int retryDelayInSec = 5,
    int maxRetry = 10,
    Map<String, dynamic> data = const {},
    bool Function()? condition,
  }) async* {
    int retry = 0;
    while (++retry <= maxRetry && !(condition?.call() ?? false)) {
      final command = createCommand(action.actionValue, data: data);
      logger.d('publish command {$action: $retry times');
      // TODO #ERRORHANDLING handle other errors - timeout error, etc...
      yield await command
          .publish(executor!)
          .then((value) => handleJNAPResult(value));
      await Future.delayed(Duration(seconds: retryDelayInSec));
    }
  }

  JNAPSuccess handleJNAPResult(JNAPResult result) {
    if (result is JNAPSuccess) {
      return result;
    } else {
      throw (result as JNAPError);
    }
  }

  Future<Map<String, JNAPSuccess>> batchCommands(
      List<CommandWrap> commands) async {
    Map<String, JNAPSuccess> _map = {};
    for (CommandWrap e in commands) {
      _map[e.action] =
          await createCommand(e.action, needAuth: e.needAuth, data: e.data)
              .publish(executor!)
              .then(
                (value) => handleJNAPResult(value),
              );
    }
    return _map;
  }

  @override
  consume(event) {
    if (event is ConnectivityState) {
      _handleConnectivityChanged(event);
    } else if (event is AuthState) {
      _handleAuthChanged(event);
    } else if (event is NetworkState) {
      _handleNetworkChanged(event);
    }
  }

  _handleNetworkChanged(NetworkState state) async {
    _networkId = state.selected?.id ?? '';
  }

  _handleConnectivityChanged(ConnectivityState state) async {
    logger.d('Router repository:: handleConnectivityChanged: $state');
    _localIp = state.connectivityInfo.gatewayIp ?? '';
    _routerType = state.connectivityInfo.routerType;
  }

  _handleAuthChanged(AuthState state) async {
    logger.d(
        'Router repository:: _handleAuthChanged: $state, ${state.runtimeType}');
    if (state is AuthLocalLoginState) {
      _localPassword = await const FlutterSecureStorage()
              .read(key: linksysPrefLocalPassword) ??
          '';
      _loginType = LoginFrom.local;
    } else if (state is AuthCloudLoginState) {
      _cloudToken =
          await const FlutterSecureStorage().read(key: linksysPrefCloudToken) ??
              '';
      _loginType = LoginFrom.remote;
    } else {
      _loginType = LoginFrom.none;
    }
  }
}
