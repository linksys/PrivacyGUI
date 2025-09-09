import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_filtered_config_state.dart';

final dualWANLogFilterConfigProvider = NotifierProvider.autoDispose<
    DualWANLogFilterConfigNotifier,
    DualWANLogFilterConfigState>(() => DualWANLogFilterConfigNotifier());

class DualWANLogFilterConfigNotifier
    extends AutoDisposeNotifier<DualWANLogFilterConfigState> {
  @override
  DualWANLogFilterConfigState build() {
    return const DualWANLogFilterConfigState(
      logLevels: [DualWANLogLevel.none],
      logTypes: [DualWANLogType.all],
    );
  }

  void setLogLevel(List<DualWANLogLevel> logLevels) {
    state = state.copyWith(logLevels: logLevels);
  }

  void setLogType(List<DualWANLogType> logTypes) {
    state = state.copyWith(logTypes: logTypes);
  }
}
