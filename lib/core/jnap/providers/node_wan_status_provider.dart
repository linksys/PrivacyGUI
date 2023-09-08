import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';

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
  if (wanStatusRaw != null) {
    final wanStatus = RouterWANStatus.fromJson(jsonDecode(wanStatusRaw.result));
    return wanStatus.wanStatus == 'Connected'
        ? NodeWANStatus.online
        : NodeWANStatus.offline;
  }
  return NodeWANStatus.offline;
});
