// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JNAPSideEffect extends Equatable {
  final bool hasSideEffect;
  final String? reason;

  const JNAPSideEffect({
    required this.hasSideEffect,
    this.reason,
  });

  @override
  List<Object?> get props => [
        hasSideEffect,
        reason,
      ];

  JNAPSideEffect copyWith({
    bool? hasSideEffect,
    String? reason,
  }) {
    return JNAPSideEffect(
      hasSideEffect: hasSideEffect ?? this.hasSideEffect,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasSideEffect': hasSideEffect,
      'reason': reason,
    };
  }

  factory JNAPSideEffect.fromJson(Map<String, dynamic> json) {
    return JNAPSideEffect(
      hasSideEffect: json['hasSideEffect'],
      reason: json['reason'],
    );
  }
}

class SideEffectNotifier extends Notifier<JNAPSideEffect> {
  @override
  JNAPSideEffect build() => const JNAPSideEffect(hasSideEffect: false);

  Future<JNAPSuccess> handleSideEffect(JNAPSuccess result) async {
    logger.d('SideEffectManager: handleSideEffect: $result');
    final sideEffects = result.sideEffects ?? [];
    if (sideEffects.isEmpty) {
      state = state.copyWith(hasSideEffect: false);
      return result;
    }
    state = state.copyWith(hasSideEffect: true, reason: sideEffects[0]);
    if (sideEffects.contains('WirelessInterruption')) {
      return poll(pollFunc: testRouterReconnected).then((value) => result);
    } else {
      return poll(pollFunc: testRouterFullyBootedUp).then((value) => result);
    }
  }

  finishSideEffect() {
    state = state.copyWith(hasSideEffect: false, reason: null);
  }

  Future<bool> poll({
    required Future<bool> Function() pollFunc,
    int retryDelayInSec = 5,
    int maxRetry = 10,
    int maxPollTimeInSec = 60,
    int timeDelayStartInSec = 3,
    bool Function()? condition,
  }) async {
    int retry = 0;
    if (timeDelayStartInSec > 0) {
      await Future.delayed(Duration(seconds: timeDelayStartInSec));
    }
    final startTime = DateTime.now().millisecondsSinceEpoch;
    while (++retry <= maxRetry) {
      logger.d('poll <$retry> times');
      // TODO #ERRORHANDLING handle other errors - timeout error, etc...
      final result = await pollFunc.call();
      if (result) {
        return result;
      }
      if (condition?.call() ?? false) {
        break;
      }
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime > startTime + 60 * 1000) {
        break;
      }
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
}

final sideEffectProvider = NotifierProvider<SideEffectNotifier, JNAPSideEffect>(
    () => SideEffectNotifier());
