import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/network/bluetooth/bluetooth.dart';
import 'package:linksys_moab/network/http/linksys_http_client.dart';
import 'package:linksys_moab/network/jnap/command/base_command.dart';
import 'package:linksys_moab/network/jnap/command/bt_base_command.dart';
import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/command/http_base_command.dart';
import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/network/jnap/spec/jnap_spec.dart';
import 'package:linksys_moab/repository/router/side_effect_manager.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';

import '../model/cloud_session_model.dart';

enum CommandType {
  remote,
  local,
}

class CommandWrap {
  CommandWrap({
    required this.action,
    required this.needAuth,
    this.data = const {},
  });

  final String action;
  Map<String, dynamic> data;
  final bool needAuth;
}

final routerRepositoryProvider = Provider((ref) => RouterRepository(ref));

class RouterRepository with StateStreamListener {
  RouterRepository(this.ref) {
    CloudEnvironmentManager().register(this);
  }
  final Ref ref;
  bool _btSetupMode = false;
  final LinksysHttpClient _client = LinksysHttpClient();
  String _cloudToken = '';
  String _localIp = '';
  String _localPassword = '';
  LoginFrom _loginType = LoginFrom.none;
  String? _networkId;
  RouterType _routerType = RouterType.others;

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

  // To expose interface
  JNAPCommandExecutor get executor {
    if (_btSetupMode) {
      return BluetoothManager();
    } else {
      return _client;
    }
  }

  set enableBTSetup(bool isEnable) => _btSetupMode = isEnable;

  bool get isEnableBTSetup => _btSetupMode;

  Future<JNAPSuccess> send(
    JNAPAction action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool auth = false,
    CommandType? type,
  }) async {
    final command = createCommand(action.actionValue,
        data: data, extraHeaders: extraHeaders, needAuth: auth, type: type);
    final sideEffectManager =
        ref.read(sideEffectProvider.notifier);
    return CommandQueue()
        .enqueue(command)
        .then((value) => handleJNAPResult(value))
        .then((value) => sideEffectManager.handleSideEffect(value))
        .then((value) {
      sideEffectManager.finishSideEffect();
      return value;
    });
  }

  TransactionHttpCommand createTransaction(List<Map<String, dynamic>> payload,
      {bool needAuth = false, CommandType? type}) {
    final communicateType = type ??
        (_loginType == LoginFrom.local
            ? CommandType.local
            : CommandType.remote);
    logger.d('create transaction');
    String url = _buildCommandUrl(
      routerType: _routerType,
      type: communicateType,
    );
    Map<String, String> header = _buildCommandHeader(
      needAuth: needAuth,
      routerType: _routerType,
      type: communicateType,
    );

    if (url.isNotEmpty) {
      return TransactionHttpCommand(
          url: url, executor: executor, payload: payload, extraHeader: header);
    } else {
      throw Exception();
    }
  }

  BaseCommand<JNAPResult, JNAPCommandSpec> createCommand(
    String action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool needAuth = false,
    CommandType? type,
  }) {
    if (isEnableBTSetup) {
      return _createBTCommand(
        action,
        data: data,
        needAuth: needAuth,
      );
    } else {
      return _createHttpCommand(
        action,
        data: data,
        extraHeaders: extraHeaders,
        needAuth: needAuth,
        type: type,
      );
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
    while (++retry <= maxRetry) {
      final command = createCommand(action.actionValue, data: data);
      logger.d('publish command {$action: $retry times');
      // TODO #ERRORHANDLING handle other errors - timeout error, etc...
      yield await CommandQueue()
          .enqueue(command)
          .then((value) => handleJNAPResult(value));
      if (condition?.call() ?? false) {
        break;
      }
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

  @Deprecated('No more use w/ HTTP')
  Future<Map<String, JNAPSuccess>> batchCommands(
      List<CommandWrap> commands) async {
    Map<String, JNAPSuccess> _map = {};
    for (CommandWrap e in commands) {
      _map[e.action] =
          await createCommand(e.action, needAuth: e.needAuth, data: e.data)
              .publish()
              .then(
                (value) => handleJNAPResult(value),
              );
    }
    return _map;
  }

  String _buildCommandUrl({
    required RouterType routerType,
    required CommandType? type,
  }) {
    String url;
    final newRouterType = () {
      if (type == CommandType.local) {
        return RouterType.behindManaged;
      } else if (type == CommandType.remote) {
        return RouterType.others;
      } else {
        return routerType;
      }
    }();
    switch (newRouterType) {
      case RouterType.others:
        url = _loginType == LoginFrom.remote
            ? cloudEnvironmentConfig[kCloudJNAP]
            : 'https://$_localIp/JNAP/';
        break;
      case RouterType.behind:
        url = _loginType == LoginFrom.remote
            ? 'https://$_localIp/cloud/JNAP/'
            : 'https://$_localIp/JNAP/';
        break;
      case RouterType.behindManaged:
        url = 'https://$_localIp/JNAP/';
        break;
    }
    return url;
  }

  Map<String, String> _buildCommandHeader({
    bool needAuth = false,
    required RouterType routerType,
    required CommandType? type,
  }) {
    Map<String, String> header = {};
    final newRouterType = () {
      if (type == CommandType.local) {
        return RouterType.behindManaged;
      } else if (type == CommandType.remote) {
        return RouterType.others;
      } else {
        return routerType;
      }
    }();
    switch (newRouterType) {
      case RouterType.others:

        /// MUST Remote
        /// Authorization: TOKEN
        /// NetworkId: {NetworkId}
        header = {
          HttpHeaders.authorizationHeader:
              'LinksysUserAuth session_token=$_cloudToken',
          kJNAPNetworkId: _networkId ?? '',
          kHeaderClientTypeId: kClientTypeId,
        };
        break;
      case RouterType.behind:

        /// MUST Remote
        /// Authorization: TOKEN
        /// NetworkId: {NetworkId}
        ///
        header = {
          HttpHeaders.authorizationHeader:
              'LinksysUserAuth session_token=$_cloudToken',
          kJNAPNetworkId: _networkId ?? '',
          kHeaderClientTypeId: kClientTypeId,
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
        header = {
          authKey:
              (needAuth | (_loginType == LoginFrom.remote)) ? authValue : '',
        };
        break;
    }
    header.removeWhere((key, value) => value.isEmpty);
    return header;
  }

  BaseCommand<JNAPResult, BTJNAPSpec> _createBTCommand(String action,
      {Map<String, dynamic> data = const {}, bool needAuth = false}) {
    return JNAPBTCommand(executor: executor, action: action, data: data);
  }

  BaseCommand<JNAPResult, HttpJNAPSpec> _createHttpCommand(
    String action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool needAuth = false,
    CommandType? type,
  }) {
    final communicateType = type ??
        (_loginType == LoginFrom.local
            ? CommandType.local
            : CommandType.remote);
    String url = _buildCommandUrl(
      routerType: _routerType,
      type: communicateType,
    );
    Map<String, String> header = _buildCommandHeader(
      needAuth: needAuth,
      routerType: _routerType,
      type: communicateType,
    );
    header.addEntries(extraHeaders.entries);

    if (url.isNotEmpty) {
      return JNAPHttpCommand(
        url: url,
        executor: executor,
        action: action,
        data: data,
        extraHeader: header,
      );
    } else {
      throw Exception();
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
      _cloudToken = (await const FlutterSecureStorage()
                  .read(key: pSessionToken)
                  .then((value) => value != null
                      ? SessionToken.fromJson(jsonDecode(value))
                      : null))
              ?.accessToken ??
          '';
      _loginType = LoginFrom.remote;
    } else {
      _loginType = LoginFrom.none;
    }
  }
}
