import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';

final systemStatsProvider = Provider<SystemStatsState>((ref) {
  final pollingData = ref.watch(pollingProvider).value;

  int uptimes = 0;
  String? cpuLoad;
  String? memoryLoad;

  final statsOutput = getPollingOutput(pollingData, JNAPAction.getSystemStats);
  if (statsOutput != null) {
    uptimes = statsOutput['uptimeSeconds'] as int? ?? 0;
    cpuLoad = statsOutput['CPULoad'] as String?;
    memoryLoad = statsOutput['MemoryLoad'] as String?;
  }

  return SystemStatsState(
    uptimes: uptimes,
    cpuLoad: cpuLoad,
    memoryLoad: memoryLoad,
  );
});

class SystemStatsState extends Equatable {
  final int uptimes;
  final String? cpuLoad;
  final String? memoryLoad;

  const SystemStatsState({
    this.uptimes = 0,
    this.cpuLoad,
    this.memoryLoad,
  });

  @override
  List<Object?> get props => [uptimes, cpuLoad, memoryLoad];
}
