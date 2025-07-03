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
    required Function(bool exceedMaxRetry) onCompleted,
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
    final status = RouterWANStatus.fromMap(jnapResult.output);
    if (byType == WanType.static || byType == WanType.dhcp) {
      return status.wanStatus == 'Connected';
    } else {
      // This case must be PPPOE
      final ip = status.wanConnection?.ipAddress;
      return (ip != null && ip != '0.0.0.0');
    }
  }

  void setEnterRoute(String route) {
    state = state.copyWith(enterRouteName: route);
  }
}

class PnpTroubleshooterState {
  final String enterRouteName;

  PnpTroubleshooterState({
    this.enterRouteName = '',
  });

  factory PnpTroubleshooterState.init() => PnpTroubleshooterState();

  PnpTroubleshooterState copyWith({String? enterRouteName}) {
    return PnpTroubleshooterState(
      enterRouteName: enterRouteName ?? this.enterRouteName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'enterRouteName': enterRouteName};
  }

  factory PnpTroubleshooterState.fromMap(Map<String, dynamic> map) {
    return PnpTroubleshooterState(
      enterRouteName: map['enterRouteName'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PnpTroubleshooterState.fromJson(String source) =>
      PnpTroubleshooterState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
