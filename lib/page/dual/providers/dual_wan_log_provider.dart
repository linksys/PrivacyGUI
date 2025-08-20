import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dual/models/log.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_log_state.dart';

var mockLogs = [
  DualWANLog(
    level: DualWANLogLevel.warning,
    message: 'Primary WAN connection lost, switching to Secondary WAN',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 32, 15).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'Secondary WAN connection established successfully',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 32, 16).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Speed test completed - Primary WAN: 900Mbps, Secondary WAN: 100Mbps',
    source: 'Speed Test Service',
    timestamp: DateTime(2024, 1, 15, 14, 32, 47).millisecondsSinceEpoch,
    type: DualWANLogType.speed,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Primary WAN connection restored, maintaining existing sessions on Secondary WAN',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 33, 18).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'WAN uptime report - Primary: 99.8%, Secondary: 98.5%',
    source: 'Uptime Monitor',
    timestamp: DateTime(2024, 1, 15, 14, 34, 19).millisecondsSinceEpoch,
    type: DualWANLogType.uptime,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message:
        'Throughput monitoring - Primary WAN: 45.2 Mbps avg, Secondary WAN: 23.1 Mbps avg',
    source: 'Throughput Monitor',
    timestamp: DateTime(2024, 1, 15, 14, 35, 20).millisecondsSinceEpoch,
    type: DualWANLogType.throughput,
  ),
  DualWANLog(
    level: DualWANLogLevel.error,
    message: 'Failed to establish connection on Secondary WAN - DNS resolution timeout',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 36, 19).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
  DualWANLog(
    level: DualWANLogLevel.info,
    message: 'Secondary WAN connection retry successful',
    source: 'Dual-WAN Manager',
    timestamp: DateTime(2024, 1, 15, 14, 36, 20).millisecondsSinceEpoch,
    type: DualWANLogType.failover,
  ),
];

final dualWANLogProvider =
    NotifierProvider<DualWANLogNotifier, DualWANLogState>(
        () => DualWANLogNotifier());

class DualWANLogNotifier extends Notifier<DualWANLogState> {
  @override
  DualWANLogState build() {
    return const DualWANLogState(logs: []);
  }

  Future<DualWANLogState> fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    state = DualWANLogState(logs: mockLogs);
    return state;
  }
}
