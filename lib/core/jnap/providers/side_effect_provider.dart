// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

class JNAPSideEffectOverrides extends Equatable {
  final int? retryDelayInSec;
  final int? maxRetry;
  final int? maxPollTimeInSec;
  final int? timeDelayStartInSec;
  final bool Function()? condition;
  const JNAPSideEffectOverrides({
    this.retryDelayInSec,
    this.maxRetry,
    this.maxPollTimeInSec,
    this.timeDelayStartInSec,
    this.condition,
  });

  JNAPSideEffectOverrides copyWith({
    bool Function()? condition,
  }) {
    return JNAPSideEffectOverrides(
      condition: condition ?? this.condition,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [condition];
}

class JNAPSideEffect extends Equatable {
  final bool hasSideEffect;
  final String? reason;
  final int progress;

  const JNAPSideEffect({
    required this.hasSideEffect,
    this.reason,
    this.progress = 0,
  });

  @override
  List<Object?> get props => [
        hasSideEffect,
        reason,
        progress,
      ];

  JNAPSideEffect copyWith({
    bool? hasSideEffect,
    String? reason,
    int? progress,
  }) {
    return JNAPSideEffect(
      hasSideEffect: hasSideEffect ?? this.hasSideEffect,
      reason: reason ?? this.reason,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasSideEffect': hasSideEffect,
      'reason': reason,
      'progress': progress,
    };
  }

  factory JNAPSideEffect.fromJson(Map<String, dynamic> json) {
    return JNAPSideEffect(
      hasSideEffect: json['hasSideEffect'],
      reason: json['reason'],
      progress: json['progress'],
    );
  }
}

class SideEffectNotifier extends Notifier<JNAPSideEffect> {
  @override
  JNAPSideEffect build() => const JNAPSideEffect(hasSideEffect: false);

  // TODO check again
  Future handleDeviceRestart() async {
    poll(
      pollFunc: testRouterReconnected,
      timeDelayStartInSec: 40,
      retryDelayInSec: 10,
      maxPollTimeInSec: 240,
    );
  }

  Future<JNAPResult> handleSideEffect(
    JNAPResult result, {
    JNAPSideEffectOverrides? overrides,
  }) async {
    final sideEffects = (result as SideEffectGetter).getSideEffects() ?? [];
    if (sideEffects.isEmpty) {
      state = state.copyWith(hasSideEffect: false);
      return result;
    }
    logger.d('[SideEffectManager] handleSideEffect: $result');

    state = state.copyWith(hasSideEffect: true, reason: sideEffects[0]);
    if (sideEffects.contains('WirelessInterruption')) {
      return poll(
        pollFunc: testRouterReconnected,
        maxRetry: overrides?.maxRetry ?? -1,
        timeDelayStartInSec: overrides?.timeDelayStartInSec ?? 10,
        retryDelayInSec: overrides?.retryDelayInSec ?? 10,
        maxPollTimeInSec: overrides?.maxPollTimeInSec ?? 120,
        condition: overrides?.condition,
      ).then((value) => result);
    } else {
      return poll(
        pollFunc: testRouterFullyBootedUp,
        maxRetry: overrides?.maxRetry ?? 5,
        timeDelayStartInSec: overrides?.timeDelayStartInSec ?? 5,
        retryDelayInSec: overrides?.retryDelayInSec ?? 15,
        maxPollTimeInSec: overrides?.maxPollTimeInSec ?? -1,
        condition: overrides?.condition,
      ).then((value) => result);
    }
  }

  finishSideEffect() {
    state = state.copyWith(hasSideEffect: false, reason: null);
  }

  Future<bool> poll({
    required Future<bool> Function() pollFunc,
    int retryDelayInSec = 5,
    int maxRetry = -1,
    int maxPollTimeInSec = -1,
    int timeDelayStartInSec = 3,
    bool Function()? condition,
  }) async {
    // Log poll config
    logger.d('''[SideEffectManager] Start Poll with config:
        retry delay: $retryDelayInSec,
        max retry: $maxRetry,
        max poll time: $maxPollTimeInSec,
        start time delay: $timeDelayStartInSec,
        ''');
    int retry = 0;
    if (timeDelayStartInSec > 0) {
      await Future.delayed(Duration(seconds: timeDelayStartInSec));
    }
    final startTime = DateTime.now().millisecondsSinceEpoch;
    while (maxRetry == -1 || ++retry <= maxRetry) {
      logger.d('[SideEffectManager] poll <$retry> times');
      final result =
          await pollFunc.call().onError((error, stackTrace) => false);
      if (result) {
        return result;
      }
      if (condition?.call() ?? false) {
        break;
      }
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (maxPollTimeInSec != -1 &&
          currentTime > startTime + maxPollTimeInSec * 1000) {
        break;
      }
      _updateProgress(retry, maxRetry, startTime, maxPollTimeInSec);
      await Future.delayed(Duration(seconds: retryDelayInSec));
    }
    return false;
  }

  Future<bool> testRouterFullyBootedUp() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
          JNAPAction.getWANStatus,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          timeoutMs: 3000,
          retries: 0,
        )
        .then((response) => RouterWANStatus.fromJson(response.output))
        .then((status) {
      final wanConnected = status.wanStatus == 'Connected' ||
          status.wanIPv6Status == 'Connected';
      final isRouterRespondingLongEnough =
          DateTime.now().millisecondsSinceEpoch > startTime + 60 * 1000;

      return wanConnected || isRouterRespondingLongEnough;
    }).onError((error, stackTrace) => false);
  }

  Future<bool> testRouterReconnected() async {
    final pref = await SharedPreferences.getInstance();
    final cachedSerialNumber =
        pref.getString(pCurrentSN) ?? pref.getString(pPnpConfiguredSN);

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(JNAPAction.getDeviceInfo,
            fetchRemote: true, cacheLevel: CacheLevel.noCache, timeoutMs: 3000)
        .then((response) => NodeDeviceInfo.fromJson(response.output))
        .then((devceInfo) => devceInfo.serialNumber == cachedSerialNumber)
        .then(
            (value) async => (value ? await testRouterFullyBootedUp() : false))
        .onError((error, stackTrace) => false);
  }

  _updateProgress(
    int currentRetry,
    int maxRetry,
    int startTime,
    int maxPollTime,
  ) {
    if (maxPollTime != -1) {
      final diff = DateTime.now().millisecondsSinceEpoch - startTime;
      state = state.copyWith(
          progress: ((diff / (maxPollTime * 1000)) * 100).toInt());
    } else {
      final diff = maxRetry - currentRetry;
      state = state.copyWith(progress: ((diff / maxRetry) * 100).toInt());
    }
  }
}

final sideEffectProvider = NotifierProvider<SideEffectNotifier, JNAPSideEffect>(
    () => SideEffectNotifier());
