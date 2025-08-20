import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_filtered_config_provider.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_log_provider.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_log_state.dart';

final dualWANFilteredLogsProvider =
    Provider.autoDispose<DualWANLogState>((ref) {
  final config = ref.watch(dualWANLogFilterConfigProvider);
  final logs = ref.watch(dualWANLogProvider);
  // if config contains DualWANLogLevel.none, return all logs
  return DualWANLogState(
    logs: logs.logs
        .where((log) =>
            config.logTypes.contains(DualWANLogType.all) ||
            config.logTypes.contains(log.type))
        .toList(),
  );
});
