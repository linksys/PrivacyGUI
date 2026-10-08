import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';

final autoIPoEServiceProvider = Provider<AutoIPoEService>((ref) {
  return AutoIPoEService(ref.read(routerRepositoryProvider));
});

AutoIPoESettings buildEnabledAutoIPoESettings(AutoIPoESettings settings) {
  final selectedMode = settings.selectedMode == AutoIPoEMode.disabled
      ? AutoIPoEMode.auto
      : settings.selectedMode;
  return settings.copyWith(
    isEnabled: true,
    selectedMode: selectedMode,
  );
}

bool isAutoIPoEManagingIPv6({
  required String configuredWanType,
  required AutoIPoEStatus status,
}) {
  return WanType.resolve(configuredWanType) == WanType.ipoe ||
      status.blockIPv6ManualConfiguration;
}

bool shouldResetAutoIPoE({
  required WanType? originalWanType,
  AutoIPoEStatus? originalStatus,
}) {
  return originalWanType == WanType.ipoe ||
      originalStatus?.isEnabled == true ||
      originalStatus?.needsResetBeforeLeaving == true;
}

class AutoIPoEService {
  const AutoIPoEService(this.routerRepository);

  final RouterRepository routerRepository;
  static final RegExp _zeroPacketLossPattern =
      RegExp(r'(^|[\s,])0(?:\.0+)?% packet loss\b');
  static final RegExp _totalPacketLossPattern =
      RegExp(r'(^|[\s,])100(?:\.0+)?% packet loss\b');
  static final RegExp _receivedPacketsPattern =
      RegExp(r'(^|\n)\s*([1-9]\d*) packets received\b', multiLine: true);

  Map<String, dynamic> _settingsPayloadForMode(
    AutoIPoESettings settings,
  ) {
    final payload = <String, dynamic>{
      'isEnabled': settings.isEnabled,
      'selectedMode': settings.selectedMode.value,
    };

    switch (settings.selectedMode) {
      case AutoIPoEMode.disabled:
      case AutoIPoEMode.auto:
        return payload;
      case AutoIPoEMode.biglobeStaticIp:
        payload['biglobeStaticIpSettings'] =
            settings.biglobeStaticIpSettings.toMap();
        return payload;
      case AutoIPoEMode.standardIpip:
        payload['standardIpipSettings'] = settings.standardIpipSettings.toMap();
        return payload;
      case AutoIPoEMode.v6PlusStaticIp:
        payload['v6PlusStaticIpSettings'] =
            settings.v6PlusStaticIpSettings.toMap();
        return payload;
      case AutoIPoEMode.ocnVirtualConnectStaticIp:
        return payload;
      case AutoIPoEMode.transixStaticIp:
        payload['transixStaticIpSettings'] =
            settings.transixStaticIpSettings.toMap();
        return payload;
      case AutoIPoEMode.asahiNetStaticIp:
        payload['asahiNetStaticIpSettings'] =
            settings.asahiNetStaticIpSettings.toMap();
        return payload;
      case AutoIPoEMode.xpassStaticIp:
        payload['xpassStaticIpSettings'] =
            settings.xpassStaticIpSettings.toMap();
        return payload;
      case AutoIPoEMode.ocxHikariV6ixStaticIp:
        return payload;
    }
  }

  Map<String, dynamic>? _applySettingsPayload(
    AutoIPoESettings? settings,
  ) {
    if (settings == null) {
      return null;
    }

    if (settings.selectedMode == AutoIPoEMode.auto) {
      return null;
    }

    return _settingsPayloadForMode(settings);
  }

  Future<AutoIPoECapabilities> getCapabilities() {
    return routerRepository
        .send(JNAPAction.getAutoIPoECapabilities, auth: true)
        .then(
          (result) => AutoIPoECapabilities.fromMap(
            result.output['capabilities'] as Map<String, dynamic>?,
          ),
        );
  }

  Future<AutoIPoESettings> getSettings() {
    return routerRepository
        .send(
          JNAPAction.getAutoIPoESettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then(
          (result) => AutoIPoESettings.fromMap(
            result.output['settings'] as Map<String, dynamic>?,
          ),
        );
  }

  Future<AutoIPoEStatus> getStatus() {
    return routerRepository
        .send(JNAPAction.getAutoIPoEStatus, auth: true, fetchRemote: true)
        .then(
          (result) => AutoIPoEStatus.fromMap(
            result.output['status'] as Map<String, dynamic>?,
          ),
        );
  }

  Future<AutoIPoELog> getLog() {
    return routerRepository
        .send(JNAPAction.getAutoIPoELog, auth: true, fetchRemote: true)
        .then(
          (result) => AutoIPoELog.fromMap(
            result.output['log'] as Map<String, dynamic>?,
          ),
        );
  }

  bool _isPingLogSuccessful(String pingLog) {
    return pingLog.contains('bytes from') ||
        _zeroPacketLossPattern.hasMatch(pingLog) ||
        _receivedPacketsPattern.hasMatch(pingLog);
  }

  bool _isPingLogTerminalFailure(String pingLog) {
    return _totalPacketLossPattern.hasMatch(pingLog) ||
        pingLog.contains('0 packets received') ||
        pingLog.contains('Network unreachable') ||
        pingLog.contains('bad address') ||
        pingLog.contains('Name or service not known');
  }

  Future<bool> probeInternet({
    String host = '1.1.1.1',
    int pingCount = 3,
    int maxPoll = 15,
    Duration pollDelay = const Duration(seconds: 1),
    Duration? maxDuration,
    bool Function()? shouldContinue,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool shouldStop() =>
        shouldContinue?.call() == false ||
        (maxDuration != null && stopwatch.elapsed >= maxDuration);

    try {
      await routerRepository.send(
        JNAPAction.stopPing,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        retries: 0,
        timeoutMs: 3000,
      );
    } catch (_) {}

    if (shouldStop()) {
      return false;
    }

    await routerRepository.send(
      JNAPAction.startPing,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      retries: 0,
      timeoutMs: 5000,
      data: {
        'host': host,
        'packetSizeBytes': 32,
        'pingCount': pingCount,
      },
    );

    PingStatus? lastStatus;
    for (var index = 0; index < maxPoll; index++) {
      if (shouldStop()) {
        return false;
      }
      final result = await routerRepository.send(
        JNAPAction.getPingStatus,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        retries: 0,
        timeoutMs: 5000,
      );
      lastStatus = PingStatus.fromMap(result.output);
      if (_isPingLogSuccessful(lastStatus.pingLog)) {
        return true;
      }

      if (!lastStatus.isRunning &&
          _isPingLogTerminalFailure(lastStatus.pingLog)) {
        return false;
      }

      if (!lastStatus.isRunning &&
          lastStatus.pingLog.trim().isNotEmpty &&
          index >= 2) {
        return _isPingLogSuccessful(lastStatus.pingLog);
      }
      if (index < maxPoll - 1) {
        if (maxDuration == null) {
          await Future.delayed(pollDelay);
        } else {
          final remaining = maxDuration - stopwatch.elapsed;
          if (remaining <= Duration.zero) {
            return false;
          }
          await Future.delayed(remaining < pollDelay ? remaining : pollDelay);
        }
      }
    }

    return _isPingLogSuccessful(lastStatus?.pingLog ?? '');
  }

  Future<void> setSettings(AutoIPoESettings settings) {
    return routerRepository.send(
      JNAPAction.setAutoIPoESettings,
      auth: true,
      data: {'settings': _settingsPayloadForMode(settings)},
    );
  }

  Future<AutoIPoEStatus> configureAndApply(
    AutoIPoESettings settings, {
    bool resetFirst = false,
    bool pnpReflectAfterApply = false,
  }) async {
    final enabledSettings = buildEnabledAutoIPoESettings(settings);
    await setSettings(enabledSettings);
    return apply(
      resetFirst: resetFirst,
      pnpReflectAfterApply: pnpReflectAfterApply,
      settings: enabledSettings,
    );
  }

  Future<AutoIPoEStatus> apply({
    bool resetFirst = false,
    bool pnpReflectAfterApply = false,
    AutoIPoESettings? settings,
  }) {
    final applySettings = _applySettingsPayload(settings);
    return routerRepository
        .send(
          JNAPAction.applyAutoIPoE,
          auth: true,
          fetchRemote: true,
          data: {
            'resetFirst': resetFirst,
            if (pnpReflectAfterApply) 'pnpReflectAfterApply': true,
            if (applySettings != null) 'settings': applySettings,
          },
          // PnP owns the post-Apply reconciliation. Do not keep its saving page
          // inside the generic WiFi-interruption poll after Apply was accepted.
          sideEffectOverrides: pnpReflectAfterApply
              ? JNAPSideEffectOverrides(
                  timeDelayStartInSec: 0,
                  condition: () => true,
                )
              : null,
        )
        .then(
          (result) => AutoIPoEStatus.fromMap(
            result.output['status'] as Map<String, dynamic>?,
          ),
        );
  }

  Future<AutoIPoEStatus> reset() {
    return routerRepository
        .send(JNAPAction.resetAutoIPoE, auth: true, fetchRemote: true)
        .then(
          (result) => AutoIPoEStatus.fromMap(
            result.output['status'] as Map<String, dynamic>?,
          ),
        );
  }
}
