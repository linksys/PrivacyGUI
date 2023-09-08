import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';

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
  if (wanStatusRaw != null && wanStatusRaw is JNAPSuccess) {
    final wanStatus = RouterWANStatus.fromJson(wanStatusRaw.output);
    return wanStatus.wanStatus == 'Connected'
        ? NodeWANStatus.online
        : NodeWANStatus.offline;
  }
  return NodeWANStatus.offline;
});
