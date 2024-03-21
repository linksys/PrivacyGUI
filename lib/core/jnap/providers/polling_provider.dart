import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/bench_mark.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/core/utils/nodes.dart';

const int pollDurationInSec = 120;
const int pollFirstDelayInSec = 1;

final pollingProvider =
    AsyncNotifierProvider<PollingNotifier, CoreTransactionData>(
        () => PollingNotifier());

class CoreTransactionData extends Equatable {
  final int lastUpdate;
  final Map<JNAPAction, JNAPResult> data;

  const CoreTransactionData({
    required this.lastUpdate,
    required this.data,
  });

  @override
  List<Object> get props => [lastUpdate, data];

  CoreTransactionData copyWith({
    int? lastUpdate,
    Map<JNAPAction, JNAPResult>? data,
  }) {
    return CoreTransactionData(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      data: data ?? this.data,
    );
  }
}

class PollingNotifier extends AsyncNotifier<CoreTransactionData> {
  static Timer? _timer;
  List<MapEntry<JNAPAction, Map<String, dynamic>>> _coreTransactions = [];

  @override
  FutureOr<CoreTransactionData> build() {
    return const CoreTransactionData(lastUpdate: 0, data: {});
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

    state = AsyncValue.data(CoreTransactionData(
        lastUpdate: 0, data: Map.fromEntries(cacheDataList)));
  }

  _polling(RouterRepository repository, {bool force = false}) async {
    final benchMark = BenchMarkLogger(name: 'Polling provider');
    benchMark.start();
    state = const AsyncValue.loading();
    final fetchFuture = repository
        .transaction(
            JNAPTransactionBuilder(commands: _coreTransactions, auth: true),
            fetchRemote: force)
        .then((successWrap) => successWrap.data)
        .then((data) => CoreTransactionData(
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
            data: Map.fromEntries(data)))
        .onError((error, stackTrace) {
      logger.d('[Polling] Error: $error, $stackTrace');
      throw error ?? '';
    });

    state = await AsyncValue.guard(() => fetchFuture);

    benchMark.end();
  }

  Future forcePolling() {
    final routerRepository = ref.read(routerRepositoryProvider);
    return _polling(routerRepository, force: true);
  }

  startPolling() {
    logger.d('prepare start polling data');
    _coreTransactions = _buildCoreTransaction();
    fetchFirstLaunchedCacheData();
    final routerRepository = ref.read(routerRepositoryProvider);
    Future.delayed(const Duration(seconds: pollFirstDelayInSec), () {
      _polling(routerRepository);
    }).then((_) {
      _timer =
          Timer.periodic(const Duration(seconds: pollDurationInSec), (timer) {
        _polling(routerRepository);
      });
    });
  }

  stopPolling() {
    logger.d('stop polling data');
    if ((_timer?.isActive ?? false)) {
      _timer?.cancel();
    }
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _buildCoreTransaction() {
    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getNetworkConnections, {}),
      const MapEntry(JNAPAction.getRadioInfo, {}),
      const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
    ];
    if (isServiceSupport(JNAPService.healthCheckManager)) {
      commands.add(const MapEntry(
          JNAPAction.getHealthCheckResults, {'includeModuleResults': true}));
      commands.add(
          const MapEntry(JNAPAction.getNodesSupportedHealthCheckModules, {}));
    }
    if (isServiceSupport(JNAPService.nodesFirmwareUpdate)) {
      commands.add(
        const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}),
      );
    } else {
      commands.add(
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
      );
    }
    return commands;
  }
}
