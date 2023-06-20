// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/core/jnap/models/device_info.dart';
import 'package:linksys_moab/core/jnap/models/wan_status.dart';
import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<JNAPSuccess> handleSideEffect(JNAPSuccess result) async {
    final sideEffects = result.sideEffects ?? [];
    if (sideEffects.isEmpty) {
      state = state.copyWith(hasSideEffect: false);
      return result;
    }
    logger.d('SideEffectManager: handleSideEffect: $result');

    state = state.copyWith(hasSideEffect: true, reason: sideEffects[0]);
    if (sideEffects.contains('WirelessInterruption')) {
      return poll(
        pollFunc: testRouterReconnected,
        timeDelayStartInSec: 10,
        retryDelayInSec: 10,
        maxPollTimeInSec: 120,
      ).then((value) => result);
    } else {
      return poll(
        pollFunc: testRouterFullyBootedUp,
        maxRetry: 5,
        timeDelayStartInSec: 5,
        retryDelayInSec: 15,
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
    logger.d('''Start Poll with config:
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
      logger.d('poll <$retry> times');
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
        .send(JNAPAction.getWANStatus)
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
    final cachedSerialNumber = pref.getString(linkstyPrefCurrentSN);

    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(JNAPAction.getDeviceInfo)
        .then((response) => RouterDeviceInfo.fromJson(response.output))
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
