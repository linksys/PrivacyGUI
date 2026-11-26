import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';

import '../../../mocks/test_data/system_info_test_data.dart';

void main() {
  // The dashboard orchestrator pushes this snapshot at login and on every
  // refresh, before the monitor's first poll. A snapshot without the
  // temperature blanked the Device Information card's tag until that poll
  // (#1926, found in review).
  group('SystemSnapshot.fromSystemInfo', () {
    final at = DateTime(2026, 11, 25, 9);

    test('carries the CPU temperature', () {
      final snapshot = SystemSnapshot.fromSystemInfo(
          SystemInfoTestData.create(cpuTemperatureCelsius: 50),
          timestamp: at);

      expect(snapshot.cpuTemperatureCelsius, 50);
    });

    test('keeps no reading as no reading', () {
      final snapshot = SystemSnapshot.fromSystemInfo(
          SystemInfoTestData.create(cpuTemperatureCelsius: null),
          timestamp: at);

      expect(snapshot.cpuTemperatureCelsius, isNull);
    });

    test('carries the CPU, memory and uptime it was read with', () {
      final snapshot = SystemSnapshot.fromSystemInfo(
          SystemInfoTestData.create(
            cpuUsage: 25,
            totalMemory: 512000,
            freeMemory: 256000,
            uptime: 3600,
          ),
          timestamp: at);

      expect(
          snapshot,
          SystemSnapshot(
            timestamp: at,
            cpuPercent: 25,
            memoryPercent: 50,
            totalMemoryKb: 512000,
            freeMemoryKb: 256000,
            uptimeSeconds: 3600,
          ));
    });
  });
}
