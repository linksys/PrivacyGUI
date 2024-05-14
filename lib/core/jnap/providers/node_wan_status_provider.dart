import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';

enum NodeWANStatus {
  online,
  offline,
}

final nodeWanStatusProvider = StateProvider<NodeWANStatus>((ref) {
  final pollingState = ref.watch(pollingProvider);
  if (pollingState.hasError) {
    return NodeWANStatus.offline;
  }
  final wanStatusRaw = pollingState.value?.data[JNAPAction.getWANStatus];
  logger.d('[WAN] $wanStatusRaw');
  if (wanStatusRaw != null && wanStatusRaw is JNAPSuccess) {
    final wanStatus = RouterWANStatus.fromJson(wanStatusRaw.output);
    return wanStatus.wanStatus == 'Connected'
        ? NodeWANStatus.online
        : NodeWANStatus.offline;
  }
  return NodeWANStatus.offline;
});
