import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/data/services/polling_service.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';

const int pollFirstDelayInSec = 1;

final pollingProvider =
    AsyncNotifierProvider<PollingNotifier, CoreTransactionData>(
        () => PollingNotifier());

class CoreTransactionData extends Equatable {
  final int lastUpdate;
  final bool isReady;
  final Map<JNAPAction, JNAPResult> data;

  const CoreTransactionData({
    required this.lastUpdate,
    required this.isReady,
    required this.data,
  });

  @override
  List<Object> get props => [lastUpdate, isReady, data];

  CoreTransactionData copyWith({
    int? lastUpdate,
    bool? isReady,
    Map<JNAPAction, JNAPResult>? data,
  }) {
    return CoreTransactionData(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isReady: isReady ?? this.isReady,
      data: data ?? this.data,
    );
  }
}

class PollingNotifier extends AsyncNotifier<CoreTransactionData> {
  static Timer? _timer;
  bool _paused = false;

  /// Service for polling operations
  PollingService get _service => ref.read(pollingServiceProvider);

  set paused(bool value) {
    _paused = value;
    if (_paused) {
      _timer?.cancel();
    } else {
      checkAndStartPolling();
    }
  }

  bool get paused => _paused;

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _coreTransactions = [];

  @override
  FutureOr<CoreTransactionData> build() {
    return const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
  }

  init() {
    state = AsyncValue.data(
        const CoreTransactionData(lastUpdate: 0, isReady: false, data: {}));
  }

  fetchFirstLaunchedCacheData() {
    final cache = ref.read(linksysCacheManagerProvider).data;

    // Delegate cache parsing to Service
    final cacheDataMap = _service.parseCacheData(
      cache: cache,
      commands: _coreTransactions,
    );

    // Cache incomplete - skip
    if (cacheDataMap == null) return;

    // Delegate Fernet key update to Service
    _service.updateFernetKeyFromResult(cacheDataMap);

    final previousSnapshot = state.value;
    state = AsyncValue.data(CoreTransactionData(
        lastUpdate: 0,
        isReady: previousSnapshot?.isReady ?? false,
        data: cacheDataMap));
  }

  Future _polling({bool force = false}) async {
    final benchMark = BenchMarkLogger(name: 'Polling provider');
    benchMark.start();
    final previousSnapshot = state.value;
    state = const AsyncValue.loading();
    final fetchFuture = _service
        .executeTransaction(_coreTransactions, force: force)
        .then((successWrap) => successWrap.data)
        .then((data) => CoreTransactionData(
              lastUpdate: DateTime.now().millisecondsSinceEpoch,
              isReady: previousSnapshot?.isReady ?? false,
              data: Map.fromEntries(data),
            ))
        .onError((error, stackTrace) {
      logger.e('Polling error: $error, $stackTrace');
      logger.f('[Auth]: Force to log out because of failed polling');
      ref.read(authProvider.notifier).logout();

      throw error ?? '';
    });

    state = await AsyncValue.guard(
      () => fetchFuture.then(
        (result) async {
          // Delegate Fernet key update to Service
          _service.updateFernetKeyFromResult(result.data);

          await _additionalPolling();
          return result.copyWith(isReady: true);
        },
      ).onError((e, stackTrace) {
        logger.e('Polling error: $e, $stackTrace');
        throw e ?? '';
      }),
    );

    benchMark.end();
  }

  Future _additionalPolling() async {
    if (serviceHelper.isSupportLedMode()) {
      await ref.read(nodeLightSettingsProvider.notifier).fetch();
    }
    if (serviceHelper.isSupportVPN()) {
      await ref.read(vpnProvider.notifier).fetch(false, true);
    }

    if (serviceHelper.isSupportHealthCheck()) {
      await ref.read(healthCheckProvider.notifier).loadData();
    }

    await ref
        .read(instantPrivacyProvider.notifier)
        .fetch(updateStatusOnly: true);
  }

  Future forcePolling() {
    return _polling(force: true).then((_) => _setTimePeriod());
  }

  void checkAndStartPolling([bool force = false]) {
    final loginType = ref.read(authProvider).value?.loginType;
    if (loginType == LoginType.none) {
      return;
    }
    if (!force && (_timer?.isActive ?? false)) {
      return;
    } else {
      _paused = false;
      stopPolling();
      startPolling();
    }
  }

  startPolling() {
    if (_paused) {
      return;
    }
    logger.d('prepare start polling data');
    _service.checkDeviceMode().then((mode) {
      _coreTransactions = _service.buildCoreTransactions(mode: mode);
      fetchFirstLaunchedCacheData();
    }).then(
      (value) =>
          Future.delayed(const Duration(seconds: pollFirstDelayInSec), () {
        _polling();
      }).then(
        (_) {
          _setTimePeriod();
        },
      ),
    );
  }

  stopPolling() {
    logger.d('stop polling data');
    if ((_timer?.isActive ?? false)) {
      _timer?.cancel();
    }
  }

  _setTimePeriod() {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: BuildConfig.refreshTimeInterval), (timer) {
      _polling();
    });
  }
}
