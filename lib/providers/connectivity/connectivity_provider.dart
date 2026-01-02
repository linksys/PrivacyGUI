import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/providers/connectivity/services/connectivity_service.dart';

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
    final benchMark = BenchMarkLogger(name: 'connectivity::forceUpdate');
    benchMark.start();
    await updateConnectivity(await connectivity.checkConnectivity());
    benchMark.end();
    return state;
  }

  Future<ConnectivityState> _internetCheckCallback(bool hasConnection,
      ConnectivityInfo connectivityInfo, AvailabilityInfo? cloudInfo) async {
    logger.d('_internetCheckCallback: $hasConnection, $connectivityInfo');

    var routerType = RouterType.others;
    if (!kIsWeb) {
      routerType = await _testRouterType(connectivityInfo.gatewayIp);
    }
    logger.d('_internetCheckCallback: $routerType');
    return state.copyWith(
        connectivityInfo: connectivityInfo.copyWith(routerType: routerType),
        hasInternet: hasConnection,
        cloudAvailabilityInfo: cloudInfo);
  }

  /// Tests router type by delegating to ConnectivityService.
  ///
  /// This method delegates to [ConnectivityService.testRouterType] which
  /// handles all JNAP communication internally.
  Future<RouterType> _testRouterType(String? newIp) async {
    final connectivityService = ref.read(connectivityServiceProvider);
    return connectivityService.testRouterType(newIp);
  }

  /// Checks if router is configured by delegating to ConnectivityService.
  ///
  /// This method delegates to [ConnectivityService.fetchRouterConfiguredData]
  /// which handles all JNAP communication and error mapping internally.
  ///
  /// Throws: [ServiceError] on JNAP failure (propagated from service)
  Future<RouterConfiguredData> isRouterConfigured() async {
    final connectivityService = ref.read(connectivityServiceProvider);
    return connectivityService.fetchRouterConfiguredData();
  }
}
