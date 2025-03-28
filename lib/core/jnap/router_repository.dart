import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/cache/utility.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/bluetooth/bluetooth.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/bt_base_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_queue.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/utils.dart';
import 'providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'providers/ip_getter/web_get_local_ip.dart';

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

const defaultAdminPassword = 'admin';

final routerRepositoryProvider = Provider((ref) {
  return RouterRepository(ref);
});

class RouterRepository {
  RouterRepository(this.ref);
  final Ref ref;
  bool _btSetupMode = false;

  // To expose interface
  JNAPCommandExecutor get executor {
    if (_btSetupMode) {
      return BluetoothManager();
    } else {
      return LinksysHttpClient();
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
    bool fetchRemote = false,
    CacheLevel? cacheLevel,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    cacheLevel ??= isMatchedJNAPNoCachePolicy(action)
        ? CacheLevel.noCache
        : CacheLevel.localCached;
    final command = await createCommand(
      action.actionValue,
      data: data,
      extraHeaders: extraHeaders,
      needAuth: auth,
      type: type,
      fetchRemote: fetchRemote,
      cacheLevel: cacheLevel,
      timeoutMs: timeoutMs,
      retries: retries,
    );
    final sideEffectManager = ref.read(sideEffectProvider.notifier);
    return CommandQueue()
        .enqueue(command)
        .then((record) => sideEffectManager.handleSideEffect(record,
            overrides: sideEffectOverrides))
        .then((record) {
      sideEffectManager.finishSideEffect();
      return record as JNAPSuccess;
    });
  }

  Future<JNAPTransactionSuccessWrap> transaction(
    JNAPTransactionBuilder builder, {
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    cacheLevel =
        builder.commands.any((entry) => isMatchedJNAPNoCachePolicy(entry.key))
            ? CacheLevel.noCache
            : CacheLevel.localCached;
    final payload = builder.commands
        .map((entry) => {
              'action': builder.overrides[entry.key] ?? entry.key.actionValue,
              'request': entry.value
            })
        .toList();
    final sideEffectManager = ref.read(sideEffectProvider.notifier);

    final command = await createTransaction(
      payload,
      actions: builder.commands.map((e) => e.key).toList(),
      needAuth: builder.auth,
      fetchRemote: fetchRemote,
      cacheLevel: cacheLevel,
      timeoutMs: timeoutMs,
      retries: retries,
    );

    return CommandQueue().enqueue(command).then((
      record,
    ) {
      logger.d(
          '[sideEffectManager] check side effects: $record, ${record.runtimeType}');
      return sideEffectManager.handleSideEffect(record,
          overrides: sideEffectOverrides);
    }).then((record) {
      sideEffectManager.finishSideEffect();
      return record;
    }).then((result) => result as JNAPTransactionSuccessWrap);
  }

  Future<TransactionHttpCommand> createTransaction(
    List<Map<String, dynamic>> payload, {
    bool needAuth = false,
    required List<JNAPAction> actions,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
    CommandType? type,
  }) async {
    // final loginType = getLoginType();
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
        url: url,
        executor: executor
          ..timeoutMs = timeoutMs
          ..retries = retries,
        actions: actions,
        payload: payload,
        extraHeader: header,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel,
      );
    } else {
      throw Exception();
    }
  }

  Future<BaseCommand<JNAPResult, JNAPCommandSpec>> createCommand(
    String action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool needAuth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
  }) async {
    if (isEnableBTSetup) {
      return _createBTCommand(action,
          data: data,
          needAuth: needAuth,
          fetchRemote: fetchRemote,
          cacheLevel: cacheLevel);
    } else {
      return _createHttpCommand(
        action,
        data: data,
        extraHeaders: extraHeaders,
        needAuth: needAuth,
        type: type,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel,
        timeoutMs: timeoutMs,
        retries: retries,
      );
    }
  }

  ///
  /// Scheduling polling a SINGLE JNAP without caching
  ///
  Stream<JNAPResult> scheduledCommand({
    required JNAPAction action,
    int retryDelayInMilliSec = 5000,
    int maxRetry = 10,
    int firstDelayInMilliSec = 3000,
    Map<String, dynamic> data = const {},
    bool Function(JNAPResult)? condition,
    Function(bool exceedMaxRetry)? onCompleted,
    int? requestTimeoutOverride,
    bool auth = false,
  }) async* {
    int retry = 0;
    bool exceedMaxRetry = true;
    while (++retry <= maxRetry || maxRetry == -1) {
      logger.d('SCHEDULED COMMAND: publish command {$action}: $retry times');
      if (retry <= 1) {
        await Future.delayed(Duration(milliseconds: firstDelayInMilliSec));
      }
      late JNAPResult result;
      try {
        result = await send(
          action,
          data: data,
          auth: auth,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          retries: 0,
          timeoutMs: requestTimeoutOverride ?? 10000,
        );
      } on JNAPError catch (e) {
        // JNAP error
        logger.d('SCHEDULED COMMAND: error catched $e, from command {$action}');
        result = e;
      } on TimeoutException catch (e) {
        // Timeout exception
        result = JNAPError(result: e.runtimeType.toString());
      } catch (e) {
        // Unknown Exception
        result = JNAPError(
          result: 'UNKNOWN',
          error: e.runtimeType.toString(),
        );
      }
      yield result;

      if (condition?.call(result) ?? false) {
        logger.d(
            'SCHEDULED COMMAND: command {$action}: $retry times: satisfy condition, STOP!');
        exceedMaxRetry = false;
        break;
      }
      await Future.delayed(Duration(milliseconds: retryDelayInMilliSec));
    }
    onCompleted?.call(exceedMaxRetry);
  }

  String _buildCommandUrl({
    required RouterType routerType,
    required CommandType? type,
  }) {
    String url;
    var localIP = getLocalIP();
    localIP = localIP.startsWith('http') ? localIP : 'https://$localIP/';
    if (kIsWeb) {
      type = checkForce() ?? type;
    }
    final newRouterType = () {
      if (type == CommandType.local) {
        return RouterType.behindManaged;
      } else if (type == CommandType.remote &&
          routerType != RouterType.behind) {
        return RouterType.others;
      } else {
        return routerType;
      }
    }();
    switch (newRouterType) {
      case RouterType.others:
        url = isCloudLogin()
            ? cloudEnvironmentConfig[kCloudJNAP]
            : '${localIP}JNAP/';
        break;
      case RouterType.behind:
        url = isCloudLogin() ? '${localIP}cloud/JNAP/' : '${localIP}JNAP/';
        break;
      case RouterType.behindManaged:
        url = '${localIP}JNAP/';
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
      type = checkForce() ?? type;
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

        /// Local:
        /// X-JNAP-AUTHxxx : Basic base64
        ///
        /// Remote
        /// Authorization: TOKEN
        /// NetworkId: {NetworkId}
        ///

        final authKey =
            cloudLogin ? HttpHeaders.authorizationHeader : kJNAPAuthorization;
        final authValue = cloudLogin
            ? 'LinksysUserAuth session_token=$cloudToken'
            : 'Basic ${Utils.stringBase64Encode('admin:${loginType == LoginType.none ? defaultAdminPassword : await getLocalPassword()}')}';
        header = {
          authKey: authValue,
          if (cloudLogin) kJNAPNetworkId: _getNetworkId(),
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
            : 'Basic ${Utils.stringBase64Encode('admin:${loginType == LoginType.none ? defaultAdminPassword : await getLocalPassword()}')}';
        header = {
          authKey: (needAuth | isCloudLogin()) ? authValue : '',
        };
        break;
    }
    header.removeWhere((key, value) => value.isEmpty);
    return header;
  }

  BaseCommand<JNAPResult, BTJNAPSpec> _createBTCommand(
    String action, {
    Map<String, dynamic> data = const {},
    bool needAuth = false,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
  }) {
    return JNAPBTCommand(
        executor: executor,
        action: action,
        data: data,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel);
  }

  Future<BaseCommand<JNAPResult, HttpJNAPSpec>> _createHttpCommand(
    String action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool needAuth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int retries = 1,
    int timeoutMs = 10000,
  }) async {
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
          executor: executor
            ..timeoutMs = timeoutMs
            ..retries = retries,
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
  String getLocalIP() {
    return getLocalIp(ref);
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

  CommandType? checkForce() {
    final force = BuildConfig.forceCommandType;
    switch (force) {
      case ForceCommand.remote:
        return CommandType.remote;
      case ForceCommand.local:
        return CommandType.local;
      default:
        return null;
    }
  }

  Future<String> getLocalPassword() async {
    final password = ref.read(authProvider).value?.localPassword ??
        await const FlutterSecureStorage().read(key: pLocalPassword) ??
        '';
    return password;
  }

  RouterType getRouterType() =>
      ref.read(connectivityProvider).connectivityInfo.routerType;

  LoginType getLoginType() =>
      ref.read(authProvider).value?.loginType ?? LoginType.none;

  bool isLoggedIn() =>
      (ref.read(authProvider).value?.loginType ?? LoginType.none) !=
      LoginType.none;

  bool isCloudLogin() =>
      ref.read(authProvider).value?.loginType == LoginType.remote;
}
