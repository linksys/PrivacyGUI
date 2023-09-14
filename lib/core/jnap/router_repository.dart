import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/provider/auth/_auth.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/core/bluetooth/bluetooth.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/command/bt_base_command.dart';
import 'package:linksys_app/core/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/http_base_command.dart';
import 'package:linksys_app/core/jnap/jnap_command_queue.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/spec/jnap_spec.dart';
import 'package:linksys_app/core/jnap/providers/side_effect_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final bool needAuth;
  Map<String, dynamic> data;
}

final routerRepositoryProvider = Provider((ref) {
  return RouterRepository(ref);
});

class RouterRepository {
  RouterRepository(this.ref);
  final Ref ref;
  bool _btSetupMode = false;
  final LinksysHttpClient _client = LinksysHttpClient();

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

  Future<JNAPSuccess> send(JNAPAction action,
      {Map<String, dynamic> data = const {},
      Map<String, String> extraHeaders = const {},
      bool auth = false,
      CommandType? type,
      bool fetchRemote = false,
      CacheLevel cacheLevel = CacheLevel.localCached}) async {
    final prefs = await SharedPreferences.getInstance();
    final sn = prefs.get(pCurrentSN) as String?;
    final command = await createCommand(action.actionValue,
        data: data,
        extraHeaders: extraHeaders,
        needAuth: auth,
        type: type,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel);
    final sideEffectManager = ref.read(sideEffectProvider.notifier);
    final linksysCacheManager = ref.read(linksysCacheManagerProvider);
    return CommandQueue()
        .enqueue(command)
        .then((record) => handleJNAPResult(record))
        .then((record) => sideEffectManager.handleSideEffect(record))
        .then((record) {
      _handleCacheProcess(
          record, action.actionValue, linksysCacheManager, sn, cacheLevel);
      sideEffectManager.finishSideEffect();
      return record.$1;
    });
  }

  Future<JNAPTransactionSuccessWrap> transaction(
      JNAPTransactionBuilder builder) async {
    final payload = builder.commands.entries
        .map((entry) =>
            {'action': entry.key.actionValue, 'request': entry.value})
        .toList();
    final prefs = await SharedPreferences.getInstance();
    final sn = prefs.get(pCurrentSN) as String?;
    final linksysCacheManager = ref.read(linksysCacheManagerProvider);
    final command = await createTransaction(payload, needAuth: builder.auth);

    return CommandQueue()
        .enqueue(command)
        .then((record) => handleJNAPResult(record))
        .then((record) {
      return (
        JNAPTransactionSuccessWrap.convert(
          actions: List.from(builder.commands.keys),
          transactionSuccess: record.$1 as JNAPTransactionSuccess,
        ),
        record.$2
      );
    }).then((record) {
      _handleTransactionCacheProcess(record, linksysCacheManager, sn);
      return record.$1;
    });
  }

  Future<TransactionHttpCommand> createTransaction(
      List<Map<String, dynamic>> payload,
      {bool needAuth = false,
      CommandType? type}) async {
    final loginType = getLoginType();
    final routerType = getRouterType();
    // final communicateType = type ??
    //     (loginType == LoginType.local ? CommandType.local : CommandType.remote);
    final communicateType = type;
    logger.d('create transaction');
    String url = _buildCommandUrl(
      routerType: routerType,
      type: communicateType,
    );
    Map<String, String> header = await _buildCommandHeader(
      needAuth: needAuth,
      routerType: routerType,
      type: communicateType,
    );

    if (url.isNotEmpty) {
      return TransactionHttpCommand(
          url: url, executor: executor, payload: payload, extraHeader: header);
    } else {
      throw Exception();
    }
  }

  Future<BaseCommand<JNAPResult, JNAPCommandSpec>> createCommand(String action,
      {Map<String, dynamic> data = const {},
      Map<String, String> extraHeaders = const {},
      bool needAuth = false,
      CommandType? type,
      bool fetchRemote = false,
      CacheLevel cacheLevel = CacheLevel.localCached}) async {
    if (isEnableBTSetup) {
      return _createBTCommand(action,
          data: data, needAuth: needAuth, fetchRemote: fetchRemote, cacheLevel: cacheLevel);
    } else {
      return _createHttpCommand(action,
          data: data,
          extraHeaders: extraHeaders,
          needAuth: needAuth,
          type: type,
          fetchRemote: fetchRemote,
          cacheLevel: cacheLevel);
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
      final command = await createCommand(action.actionValue, data: data);
      logger.d('publish command {$action: $retry times');
      // TODO #ERRORHANDLING handle other errors - timeout error, etc...
      yield await CommandQueue()
          .enqueue(command)
          .then((record) => handleJNAPResult(record))
          .then((record) => record.$1);
      if (condition?.call() ?? false) {
        break;
      }
      await Future.delayed(Duration(seconds: retryDelayInSec));
    }
  }

  (JNAPResult result, DataSource ds) handleJNAPResult(
      (JNAPResult result, DataSource ds) record) {
    if (record.$1 is JNAPSuccess || record.$1 is JNAPTransactionSuccess) {
      return record;
    }
    throw (record.$1 as JNAPError);
  }

  (JNAPResult result, DataSource ds) _handleCacheProcess(
      (JNAPResult result, DataSource ds) record,
      String action,
      LinksysCacheManager linksysCacheManager,
      String? serialNumber,
      CacheLevel cacheLevel) {
    if (record.$2 == DataSource.fromRemote) {
      if (cacheLevel == CacheLevel.localCached) {
        final dataResult = {
          "target": action,
          "cachedAt": DateTime.now().millisecondsSinceEpoch,
        };
        dataResult["data"] = record.$1.toJson();
        linksysCacheManager.data[action] = dataResult;
        if (serialNumber != null) {
          linksysCacheManager.saveCache(serialNumber);
        }
      }
    }
    return record;
  }

  (JNAPTransactionSuccessWrap result, DataSource ds)
      _handleTransactionCacheProcess(
    (JNAPTransactionSuccessWrap result, DataSource ds) record,
    LinksysCacheManager linksysCacheManager,
    String? serialNumber,
  ) {
    if (record.$2 == DataSource.fromRemote) {
      record.$1.data.forEach((key, value) {
        final dataResult = {
          "target": key.actionValue,
          "cachedAt": DateTime.now().millisecondsSinceEpoch,
        };
        dataResult["data"] = (value as JNAPSuccess).toJson();
        linksysCacheManager.data[key.actionValue] = dataResult;
      });
      if (serialNumber != null) {
        linksysCacheManager.saveCache(serialNumber);
      }
    }
    return record;
  }

  String _buildCommandUrl({
    required RouterType routerType,
    required CommandType? type,
  }) {
    String url;
    final localIP = _getLocalIP();
    if (kIsWeb) {
      type = CommandType.remote;
    }
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
        url = isCloudLogin()
            ? cloudEnvironmentConfig[kCloudJNAP]
            : 'https://$localIP/JNAP/';
        break;
      case RouterType.behind:
        url = isCloudLogin()
            ? 'https://$localIP/cloud/JNAP/'
            : 'https://$localIP/JNAP/';
        break;
      case RouterType.behindManaged:
        url = 'https://$localIP/JNAP/';
        break;
    }
    return url;
  }

  Future<Map<String, String>> _buildCommandHeader({
    bool needAuth = false,
    required RouterType routerType,
    required CommandType? type,
  }) async {
    final cloudToken = await getCloudToken();
    final cloudLogin = isCloudLogin();
    final loginType = getLoginType();
    if (kIsWeb) {
      type = CommandType.remote;
    }
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
              'LinksysUserAuth session_token=$cloudToken',
          kJNAPNetworkId: _getNetworkId(),
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
              'LinksysUserAuth session_token=$cloudToken',
          kJNAPNetworkId: _getNetworkId(),
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
        final authKey = cloudLogin ? kJNAPSession : kJNAPAuthorization;
        final authValue = cloudLogin
            ? await getCloudToken()
            : 'Basic ${Utils.stringBase64Encode('admin:${loginType == LoginType.none ? 'admin' : getLocalPassword()}')}';
        header = {
          authKey: (needAuth | isCloudLogin()) ? authValue : '',
        };
        break;
    }
    header.removeWhere((key, value) => value.isEmpty);
    return header;
  }

  BaseCommand<JNAPResult, BTJNAPSpec> _createBTCommand(String action,
      {Map<String, dynamic> data = const {},
      bool needAuth = false,
      bool fetchRemote = false,
      CacheLevel cacheLevel = CacheLevel.localCached}) {
    return JNAPBTCommand(
        executor: executor,
        action: action,
        data: data,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel);
  }

  Future<BaseCommand<JNAPResult, HttpJNAPSpec>> _createHttpCommand(
      String action,
      {Map<String, dynamic> data = const {},
      Map<String, String> extraHeaders = const {},
      bool needAuth = false,
      CommandType? type,
      bool fetchRemote = false,
      CacheLevel cacheLevel = CacheLevel.localCached}) async {
    final routerType = getRouterType();
    // final communicateType =
    //     type ?? (!isCloudLogin() ? CommandType.local : CommandType.remote);
    final communicateType = type;
    String url = _buildCommandUrl(
      routerType: routerType,
      type: communicateType,
    );
    Map<String, String> header = await _buildCommandHeader(
      needAuth: needAuth,
      routerType: routerType,
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
          fetchRemote: fetchRemote,
          cacheLevel: cacheLevel);
    } else {
      throw Exception();
    }
  }
}

extension RouterRepositoryUtil on RouterRepository {
  String _getLocalIP() {
    return ref.read(connectivityProvider).connectivityInfo.gatewayIp ?? '';
  }

  String _getNetworkId() {
    return ref.read(selectedNetworkIdProvider) ?? 'NetworkIdError';
  }

  Future<String> getCloudToken() async {
    return (await const FlutterSecureStorage().read(key: pSessionToken).then(
                (value) => value != null
                    ? SessionToken.fromJson(jsonDecode(value))
                    : null))
            ?.accessToken ??
        '';
  }

  Future<String> getLocalPassword() async {
    return await const FlutterSecureStorage().read(key: pLocalPassword) ?? '';
  }

  RouterType getRouterType() =>
      ref.read(connectivityProvider).connectivityInfo.routerType;

  LoginType getLoginType() =>
      ref.read(authProvider).value?.loginType ?? LoginType.none;

  bool isLogin() =>
      (ref.read(authProvider).value?.loginType ?? LoginType.none) !=
      LoginType.none;

  bool isCloudLogin() =>
      ref.read(authProvider).value?.loginType == LoginType.remote;
}
