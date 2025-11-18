import 'dart:async';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';

class PnpIspService {
  final RouterRepository _routerRepository;

  PnpIspService(this._routerRepository);

  /// Wraps the stream-based check in a Future.
  Future<bool> verifyNewSettings(WanType settingWanType) {
    final completer = Completer<bool>();
    StreamSubscription? subscription;

    subscription = _checkNewSettingsStream(
      settingWanType: settingWanType,
      onCompleted: (bool exceedMaxRetry) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          // If exceedMaxRetry is true, it means the check failed after max retries.
          completer.complete(!exceedMaxRetry);
        }
      },
    ).listen(
      (isValid) {
        logger.i(
          '[PnP]: Troubleshooter - Check new setting configuration - ${isValid ? 'Passed' : 'Not passed'}',
        );
        if (isValid) {
          // The setting is valid, we can complete the future and stop listening.
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
        // If not valid, we just wait for the next emission or onCompleted.
      },
      onError: (e, st) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      },
      onDone: () {
        // This might be called if the stream closes before onCompleted.
        // We check if it's already completed to avoid errors.
        if (!completer.isCompleted) {
          // Assuming if it's done without an explicit success, it failed.
          completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  Stream<bool> _checkNewSettingsStream({
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

    return _routerRepository
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
}
