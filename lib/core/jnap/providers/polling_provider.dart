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

  @override
  FutureOr<CoreTransactionData> build() {
    return const CoreTransactionData(lastUpdate: 0, data: {});
  }

  fetchFirstLaunchedCacheData() {
    final cache = ref.read(linksysCacheManagerProvider).data;
    final commands = JNAPTransactionBuilder.coreTransactions().commands;
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

  _polling(RouterRepository repository) async {
    final benchMark = BenchMarkLogger(name: 'Polling provider');
    benchMark.start();
    state = const AsyncValue.loading();
    final fetchFuture = repository
        .transaction(JNAPTransactionBuilder.coreTransactions())
        .then((successWrap) => successWrap.data)
        .then((data) => CoreTransactionData(
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
            data: Map.fromEntries(data)));

    state = await AsyncValue.guard(() => fetchFuture);
    logger.d('state: $state');
    benchMark.end();
  }

  startPolling() {
    logger.d('prepare start polling data');
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
}
