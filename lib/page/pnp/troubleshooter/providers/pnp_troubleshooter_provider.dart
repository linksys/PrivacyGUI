import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';

final pnpTroubleshooterProvider =
    NotifierProvider<PnpTroubleshooterNotifier, PnpTroubleshooterState>(
        () => PnpTroubleshooterNotifier());

class PnpTroubleshooterNotifier extends Notifier<PnpTroubleshooterState> {
  @override
  PnpTroubleshooterState build() => PnpTroubleshooterState.init();

  Stream<bool> checkNewSettings({
    required WanType settingWanType,
    required Function() onCompleted,
  }) {
    int retryTimes;
    int retryDelay;
    if (settingWanType == WanType.static || settingWanType == WanType.dhcp) {
      retryTimes = 18;
      retryDelay = 5000;
    } else {
      // This case must be PPPOE
      retryTimes = 4;
      retryDelay = 15000;
    }

    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
          action: JNAPAction.getWANStatus,
          maxRetry: retryTimes,
          retryDelayInMilliSec: retryDelay,
          condition: (result) => (result is JNAPSuccess)
              ? _isNewSettingPassed(result, settingWanType)
              : false,
          onCompleted: onCompleted,
          auth: true,
        )
        .map((result) => (result is JNAPSuccess)
            ? _isNewSettingPassed(result, settingWanType)
            : false);
  }

  bool _isNewSettingPassed(JNAPSuccess jnapResult, WanType byType) {
    final status = RouterWANStatus.fromJson(jnapResult.output);
    if (byType == WanType.static || byType == WanType.dhcp) {
      return status.wanStatus == 'Connected';
    } else {
      // This case must be PPPOE
      final ip = status.wanConnection?.ipAddress;
      return (ip != null && ip != '0.0.0.0');
    }
  }

  void resetModem(bool hasReset) {
    state = state.copyWith(
      hasResetModem: hasReset,
    );
  }
}

class PnpTroubleshooterState {
  final bool hasResetModem;

  PnpTroubleshooterState({
    required this.hasResetModem,
  });

  factory PnpTroubleshooterState.init() {
    return PnpTroubleshooterState(
      hasResetModem: false,
    );
  }

  PnpTroubleshooterState copyWith({
    bool? hasResetModem,
  }) {
    return PnpTroubleshooterState(
      hasResetModem: hasResetModem ?? this.hasResetModem,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hasResetModem': hasResetModem,
    };
  }

  factory PnpTroubleshooterState.fromMap(Map<String, dynamic> map) {
    return PnpTroubleshooterState(
      hasResetModem: map['hasResetModem'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory PnpTroubleshooterState.fromJson(String source) =>
      PnpTroubleshooterState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
