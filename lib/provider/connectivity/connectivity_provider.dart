import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/connectivity/connectivity_info.dart';
import 'package:linksys_app/provider/connectivity/connectivity_state.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'availability_info.dart';
import 'mixin.dart';

class RouterConfiguredData {
  const RouterConfiguredData({
    required this.isDefaultPassword,
    required this.isSetByUser,
  });

  final bool isDefaultPassword;
  final bool isSetByUser;
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityState>(
        () => ConnectivityNotifier());

class ConnectivityNotifier extends Notifier<ConnectivityState>
    with ConnectivityListener, AvailabilityChecker {
  ConnectivityNotifier() {
    callback = _internetCheckCallback;
  }

  @override
  ConnectivityState build() => const ConnectivityState(
      hasInternet: false, connectivityInfo: ConnectivityInfo());

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    state = state.copyWith(connectivityInfo: info);
    if (info.type != ConnectivityResult.none) {
      // await scheduleCheck(immediate: true);
      final newState = await check(info);
      state = newState;
    }
  }

  Future<ConnectivityState> forceUpdate() async {
    await updateConnectivity(await connectivity.checkConnectivity());
    return state;
  }

  Future<ConnectivityState> _internetCheckCallback(bool hasConnection,
      ConnectivityInfo connectivityInfo, AvailabilityInfo? cloudInfo) async {
    logger.d('_internetCheckCallback: $hasConnection, $connectivityInfo');

    var routerType = RouterType.others;
    if (hasConnection) {
      routerType = await _testRouterType(connectivityInfo.gatewayIp);
    }
    logger.d('_internetCheckCallback: $routerType');
    return state.copyWith(
        connectivityInfo: connectivityInfo.copyWith(routerType: routerType),
        hasInternet: hasConnection,
        cloudAvailabilityInfo: cloudInfo);
  }

  Future<RouterType> _testRouterType(String? newIp) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final testJNAP = await routerRepository
        .send(JNAPAction.isAdminPasswordDefault, type: CommandType.local)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    if (!testJNAP) {
      return RouterType.others;
    }

    final routerSN = await routerRepository
        .send(JNAPAction.getDeviceInfo, type: CommandType.local)
        .then<String>(
            (value) => RouterDeviceInfo.fromJson(value.output).serialNumber)
        .onError((error, stackTrace) => '');
    final prefs = await SharedPreferences.getInstance();
    final currentSN = prefs.get(linkstyPrefCurrentSN);
    if (routerSN.isNotEmpty && routerSN == currentSN) {
      return RouterType.behindManaged;
    }
    return RouterType.behind;
  }

  Future<RouterConfiguredData> isRouterConfigured() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final results = await routerRepository.fetchIsConfigured();

    bool isDefaultPassword = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.isAdminPasswordDefault, results)
        ?.output['isAdminPasswordDefault'];
    bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.isAdminPasswordDefault, results)
        ?.output['isAdminPasswordSetByUser'];
    return RouterConfiguredData(
        isDefaultPassword: isDefaultPassword, isSetByUser: isSetByUser);
  }
}
