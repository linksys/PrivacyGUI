import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
  set paused(bool value) {
    _paused = value;
    if (_paused) {
      _timer?.cancel();
    } else {
      checkAndStartPolling();
    }
  }

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
    final commands = _coreTransactions;
    final checkCacheDataList = commands
        .where((command) => cache.keys.contains(command.key.actionValue));
    // Have not done any polling yet
    if (checkCacheDataList.length != commands.length) return;

    final cacheDataList = checkCacheDataList
        .where((command) => cache[command.key.actionValue]['data'] != null)
        .map((command) => MapEntry(command.key,
            JNAPSuccess.fromJson(cache[command.key.actionValue]['data'])))
        .toList();
    final previousSnapshot = state.value;
    state = AsyncValue.data(CoreTransactionData(
        lastUpdate: 0,
        isReady: previousSnapshot?.isReady ?? false,
        data: Map.fromEntries(cacheDataList)));
  }

  Future _polling(RouterRepository repository, {bool force = false}) async {
    final benchMark = BenchMarkLogger(name: 'Polling provider');
    benchMark.start();
    final previousSnapshot = state.value;
    state = const AsyncValue.loading();
    final fetchFuture = repository
        .transaction(
          JNAPTransactionBuilder(commands: _coreTransactions, auth: true),
          fetchRemote: force,
        )
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

    await ref.read(instantPrivacyProvider.notifier).fetch(statusOnly: true);
  }

  Future forcePolling() {
    final routerRepository = ref.read(routerRepositoryProvider);

    return _polling(routerRepository, force: true)
        .then((_) => _setTimePeriod(routerRepository));
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
    final routerRepository = ref.read(routerRepositoryProvider);
    checkSmartMode().then((mode) {
      _coreTransactions = _buildCoreTransaction(mode: mode);
      fetchFirstLaunchedCacheData();
    }).then(
      (value) =>
          Future.delayed(const Duration(seconds: pollFirstDelayInSec), () {
        _polling(routerRepository);
      }).then(
        (_) {
          _setTimePeriod(routerRepository);
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

  _setTimePeriod(RouterRepository routerRepository) {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: BuildConfig.refreshTimeInterval), (timer) {
      _polling(routerRepository);
    });
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _buildCoreTransaction(
      {String? mode}) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();

    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getNetworkConnections, {}),
      const MapEntry(JNAPAction.getRadioInfo, {}),
      if (isSupportGuestWiFi)
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      if ((mode ?? 'Unconfigured') == 'Master')
        const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
      const MapEntry(JNAPAction.getEthernetPortConnections, {}),
      const MapEntry(JNAPAction.getSystemStats, {}),
      const MapEntry(JNAPAction.getPowerTableSettings, {}),
      const MapEntry(JNAPAction.getLocalTime, {}),
      const MapEntry(JNAPAction.getDeviceInfo, {}),
    ];
    if (serviceHelper.isSupportSetup()) {
      commands.add(
        const MapEntry(JNAPAction.getInternetConnectionStatus, {}),
      );
    }
    if (serviceHelper.isSupportHealthCheck()) {
      commands.add(const MapEntry(JNAPAction.getHealthCheckResults, {
        'includeModuleResults': true,
        "lastNumberOfResults": 5,
      }));
      commands
          .add(const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}));
    }
    if (serviceHelper.isSupportNodeFirmwareUpdate()) {
      commands.add(
        const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}),
      );
    } else {
      commands.add(
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
      );
    }
    if (serviceHelper.isSupportProduct()) {
      commands.add(const MapEntry(JNAPAction.getSoftSKUSettings, {}));
    }

    // For additional features
    if (serviceHelper.isSupportLedMode()) {
      commands.add(const MapEntry(JNAPAction.getLedNightModeSetting, {}));
    }
    commands.add(const MapEntry(JNAPAction.getMACFilterSettings, {}));

    return commands;
  }

  Future<String> checkSmartMode() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    return await routerRepository
        .send(
          JNAPAction.getDeviceMode,
          fetchRemote: true,
        )
        .then((value) => value.output['mode'] ?? 'Unconfigured');
  }
}
