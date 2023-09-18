import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
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

  _polling(RouterRepository repository) async {
    logger.d('Polling Provider: start polling - ${DateTime.now()}');
    state = const AsyncValue.loading();
    final fetchFuture = repository
        .transaction(JNAPTransactionBuilder.coreTransactions())
        .then((successWrap) => successWrap.data)
        .then((data) => CoreTransactionData(
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
            data: Map.fromEntries(data)));

    state = await AsyncValue.guard(() => fetchFuture);
    logger.d('Polling Provider: finish polling - ${DateTime.now()}, $state');
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
