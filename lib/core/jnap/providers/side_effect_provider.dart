// =============================================================================
// This File Does NOT Need Service Layer Extraction
// =============================================================================
//
// This file is intentionally part of the JNAP infrastructure layer, not a
// feature provider. It does NOT violate the Constitution's architecture rules
// for the following reasons:
//
// 1. Special Cross-Layer Role
//    SideEffectNotifier is an infrastructure-level component used directly by
//    RouterRepository. It handles side effects (e.g., device restart) that
//    occur during JNAP operations and is part of the Data Layer itself.
//
// 2. Circular Dependency Risk
//    Creating a SideEffectService that depends on RouterRepository while
//    RouterRepository depends on SideEffectNotifier would create a circular
//    dependency.
//
// 3. Design Rationale
//    Located in `lib/core/jnap/providers/`, this component is explicitly part
//    of the JNAP infrastructure, not a feature provider in `lib/page/`.
//    Its responsibility is to handle JNAP operation side effects, which
//    inherently belongs to the Data Layer.
//
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

class SideEffectPollConfig extends Equatable {
  final int? retryDelayInSec;
  final int? maxRetry;
  final int? maxPollTimeInSec;
  final int? timeDelayStartInSec;
  final bool Function()? condition;
  const SideEffectPollConfig({
    this.retryDelayInSec,
    this.maxRetry,
    this.maxPollTimeInSec,
    this.timeDelayStartInSec,
    this.condition,
  });

  SideEffectPollConfig copyWith({
    int? retryDelayInSec,
    int? maxRetry,
    int? maxPollTimeInSec,
    int? timeDelayStartInSec,
    bool Function()? condition,
  }) {
    return SideEffectPollConfig(
      retryDelayInSec: retryDelayInSec ?? this.retryDelayInSec,
      maxRetry: maxRetry ?? this.maxRetry,
      maxPollTimeInSec: maxPollTimeInSec ?? this.maxPollTimeInSec,
      timeDelayStartInSec: timeDelayStartInSec ?? this.timeDelayStartInSec,
      condition: condition ?? this.condition,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [condition];
}

class SideEffectState extends Equatable {
  final bool hasSideEffect;
  final String? reason;
  final int progress;

  const SideEffectState({
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

  SideEffectState copyWith({
    bool? hasSideEffect,
    String? reason,
    int? progress,
  }) {
    return SideEffectState(
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

  factory SideEffectState.fromJson(Map<String, dynamic> json) {
    return SideEffectState(
      hasSideEffect: json['hasSideEffect'],
      reason: json['reason'],
      progress: json['progress'],
    );
  }
}

final sideEffectProvider =
    NotifierProvider<SideEffectNotifier, SideEffectState>(
        () => SideEffectNotifier());

class SideEffectNotifier extends Notifier<SideEffectState> {
  @override
  SideEffectState build() => const SideEffectState(hasSideEffect: false);

  Future manualDeviceRestart({
    SideEffectPollConfig? overrides,
  }) {
    state = state.copyWith(hasSideEffect: true, reason: 'manual', progress: 0);
    return poll(
      pollFunc: testRouterReconnected,
      maxRetry: overrides?.maxRetry ?? -1,
      timeDelayStartInSec: overrides?.timeDelayStartInSec ?? 10,
      retryDelayInSec: overrides?.retryDelayInSec ?? 10,
      maxPollTimeInSec: overrides?.maxPollTimeInSec ?? 240,
      condition: overrides?.condition,
    ).whenComplete(() {
      finishSideEffect();
    });
  }

  Future<JNAPResult> handleSideEffect(
    JNAPResult result, {
    SideEffectPollConfig? config,
  }) async {
    final sideEffects = (result as SideEffectGetter).getSideEffects() ?? [];
    if (sideEffects.isEmpty) {
      state = state.copyWith(hasSideEffect: false);
      return result;
    }
    logger.d('[SideEffectManager] handleSideEffect: $result');
    ref.read(pollingProvider.notifier).stopPolling();
    state = state.copyWith(hasSideEffect: true, reason: sideEffects[0]);
    // poll() throws ServiceSideEffectError(null, lastPolledResult) on timeout.
    // catchError enriches it with originalResult for upstream consumers.
    if (sideEffects.contains('DeviceRestart')) {
      return poll(
        pollFunc: testRouterReconnected,
        maxRetry: config?.maxRetry ?? -1,
        timeDelayStartInSec: config?.timeDelayStartInSec ?? 20,
        retryDelayInSec: config?.retryDelayInSec ?? 10,
        maxPollTimeInSec: config?.maxPollTimeInSec ?? 240,
        condition: config?.condition,
      ).then((value) {
        ref.read(pollingProvider.notifier).startPolling();
        return result;
      }).catchError(
        (error) {
          if (error is ServiceSideEffectError) {
            throw ServiceSideEffectError(result, error.lastPolledResult);
          }
          throw ServiceSideEffectError(result);
        },
        test: (error) => error is ServiceSideEffectError,
      );
    } else if (sideEffects.contains('WirelessInterruption')) {
      return poll(
        pollFunc: testRouterReconnected,
        maxRetry: config?.maxRetry ?? -1,
        timeDelayStartInSec: config?.timeDelayStartInSec ?? 20,
        retryDelayInSec: config?.retryDelayInSec ?? 10,
        maxPollTimeInSec: config?.maxPollTimeInSec ?? 120,
        condition: config?.condition,
      ).then((value) {
        ref.read(pollingProvider.notifier).startPolling();
        return result;
      }).catchError(
        (error) {
          if (error is ServiceSideEffectError) {
            throw ServiceSideEffectError(result, error.lastPolledResult);
          }
          throw ServiceSideEffectError(result);
        },
        test: (error) => error is ServiceSideEffectError,
      );
    } else {
      // Unknown side effect: use testRouterFullyBootedUp (checks WAN status)
      return poll(
        pollFunc: testRouterFullyBootedUp,
        maxRetry: config?.maxRetry ?? 10,
        timeDelayStartInSec: config?.timeDelayStartInSec ?? 20,
        retryDelayInSec: config?.retryDelayInSec ?? 15,
        maxPollTimeInSec: config?.maxPollTimeInSec ?? -1,
        condition: config?.condition,
      ).then((value) {
        ref.read(pollingProvider.notifier).startPolling();
        return result;
      }).catchError(
        (error) {
          if (error is ServiceSideEffectError) {
            throw ServiceSideEffectError(result, error.lastPolledResult);
          }
          throw ServiceSideEffectError(result);
        },
        test: (error) => error is ServiceSideEffectError,
      );
    }
  }

  void finishSideEffect() {
    state = state.copyWith(
      hasSideEffect: false,
      reason: null,
      progress: 0,
    );
  }

  Future<bool> poll({
    required Future<(bool, JNAPResult?)> Function() pollFunc,
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
    var result = false;
    JNAPResult? lastPolledResult;
    while (maxRetry == -1 || retry <= maxRetry) {
      logger.d('[SideEffectManager] poll <$retry> times');
      result = await pollFunc.call().then((value) {
            lastPolledResult = value.$2;
            return value.$1;
          }).onError((error, stackTrace) => false) ||
          (condition?.call() ?? false);
      if (result) {
        return result;
      }

      // check poll exceed to the max time
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (maxPollTimeInSec != -1 &&
          currentTime > startTime + maxPollTimeInSec * 1000) {
        break;
      }
      _updateProgress(retry, maxRetry, startTime, maxPollTimeInSec);
      await Future.delayed(Duration(seconds: retryDelayInSec));
      retry++;
    }
    if (!result) {
      logger.d(('[SideEffectManager] exceed to MAX retry!'));
      throw ServiceSideEffectError(null, lastPolledResult);
    }
    return result;
  }

  Future<(bool, JNAPResult?)> testRouterFullyBootedUp() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    return _getWANStatus().then<(bool, JNAPResult?)>((status) {
      final wanConnected = status.wanStatus == 'Connected' ||
          status.wanIPv6Status == 'Connected';
      final isRouterRespondingLongEnough =
          DateTime.now().millisecondsSinceEpoch > startTime + 60 * 1000;

      return (
        wanConnected || isRouterRespondingLongEnough,
        JNAPSuccess(output: status.toMap(), result: 'ok')
      );
    }).onError((error, stackTrace) => (false, null));
  }

  Future<(bool, JNAPResult?)> testRouterReconnected() async {
    final pref = await SharedPreferences.getInstance();
    final cachedSerialNumber =
        pref.getString(pCurrentSN) ?? pref.getString(pPnpConfiguredSN);

    return _getDeviceInfo()
        .then((devceInfo) => devceInfo.serialNumber == cachedSerialNumber)
        .then((value) async =>
            (value ? await testRouterFullyBootedUp() : (false, null)))
        .onError((error, stackTrace) => (false, null));
  }

  Future<RouterWANStatus> _getWANStatus() => ref
      .read(routerRepositoryProvider)
      .send(
        JNAPAction.getWANStatus,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        timeoutMs: 3000,
        retries: 0,
      )
      .then((response) => RouterWANStatus.fromMap(response.output));

  Future<NodeDeviceInfo> _getDeviceInfo() => ref
      .read(routerRepositoryProvider)
      .send(JNAPAction.getDeviceInfo,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          timeoutMs: 3000,
          retries: 0)
      .then((response) => NodeDeviceInfo.fromJson(response.output));

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
