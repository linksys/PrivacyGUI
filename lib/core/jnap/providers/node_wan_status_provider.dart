import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';

enum InternetStatus {
  online,
  offline,
}

final internetStatusProvider = StateProvider<InternetStatus>((ref) {
  final pollingState = ref.watch(pollingProvider);
  if (pollingState.hasError) {
    logger.e('[State]:[Internet]: Failed to get the Internet status');
    return InternetStatus.offline;
  }

  var isConnected = false;
  final pollingData = pollingState.value?.data;
  // Read the Internet Connection Status result first
  var outputData =
      (pollingData?[JNAPAction.getInternetConnectionStatus] as JNAPSuccess?)
          ?.output;
  if (outputData != null) {
    final connectionStatus = outputData['connectionStatus'];
    isConnected = connectionStatus == 'InternetConnected';
  } else {
    // For non-node models, read the WAN Status result
    outputData =
        (pollingData?[JNAPAction.getWANStatus] as JNAPSuccess?)?.output;
    if (outputData != null) {
      final wanStatus = RouterWANStatus.fromMap(outputData);
      isConnected = wanStatus.wanStatus == 'Connected';
    }
  }
  logger.i('[State]:[Internet]: Is Internet connected = $isConnected');
  return isConnected ? InternetStatus.online : InternetStatus.offline;
});
