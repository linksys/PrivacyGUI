import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/usp_system_monitor_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspSystemMonitorService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspSystemMonitorService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  void stubSystemInfo({
    int cpuUsage = 25,
    int totalMemory = 512000,
    int freeMemory = 256000,
  }) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async => {
              'Device.DeviceInfo.Manufacturer': 'Linksys',
              'Device.DeviceInfo.ModelName': 'MX5300',
              'Device.DeviceInfo.SerialNumber': 'ABC123',
              'Device.DeviceInfo.HardwareVersion': '1.0',
              'Device.DeviceInfo.SoftwareVersion': '2.0.0',
              'Device.DeviceInfo.UpTime': '86400',
              'Device.DeviceInfo.MemoryStatus.Total': totalMemory.toString(),
              'Device.DeviceInfo.MemoryStatus.Free': freeMemory.toString(),
              'Device.DeviceInfo.ProcessStatus.CPUUsage': cpuUsage.toString(),
              'Device.DeviceInfo.ActiveFirmwareImage': 'Device.Firmware.1.',
              'Device.DeviceInfo.BootFirmwareImage': 'Device.Firmware.1.',
            });
  }

  // ---------------------------------------------------------------------------
  // fetchSnapshot
  // ---------------------------------------------------------------------------

  group('UspSystemMonitorService — fetchSnapshot', () {
    test('returns SystemSnapshot with correct cpuPercent', () async {
      stubSystemInfo(cpuUsage: 45);

      final result = await svc.fetchSnapshot();

      expect(result.cpuPercent, 45);
    });

    test('clamps cpuPercent to 0-100 range', () async {
      stubSystemInfo(cpuUsage: 150);
      var result = await svc.fetchSnapshot();
      expect(result.cpuPercent, 100);

      stubSystemInfo(cpuUsage: -10);
      result = await svc.fetchSnapshot();
      expect(result.cpuPercent, 0);
    });

    test('calculates memoryPercent from total and free', () async {
      // 512000 total, 256000 free => 50% used
      stubSystemInfo(totalMemory: 512000, freeMemory: 256000);

      final result = await svc.fetchSnapshot();

      expect(result.memoryPercent, 50);
      expect(result.totalMemoryKb, 512000);
      expect(result.freeMemoryKb, 256000);
    });

    test('handles zero totalMemory gracefully', () async {
      stubSystemInfo(totalMemory: 0, freeMemory: 0);

      final result = await svc.fetchSnapshot();

      expect(result.memoryPercent, 0);
    });

    test('clamps memoryPercent to 0-100 range', () async {
      // Edge case: freeMemory > totalMemory (shouldn't happen, but handle it)
      stubSystemInfo(totalMemory: 100, freeMemory: 200);

      final result = await svc.fetchSnapshot();

      expect(result.memoryPercent, 0); // Clamped to 0
    });

    test('includes timestamp in snapshot', () async {
      stubSystemInfo();
      final before = DateTime.now();

      final result = await svc.fetchSnapshot();

      final after = DateTime.now();
      expect(result.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
          isTrue);
      expect(
          result.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // error handling (no mapping — raw exceptions propagate)
  // ---------------------------------------------------------------------------

  group('UspSystemMonitorService — error handling', () {
    test('fetchSnapshot throws raw exception (no error mapping)', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow(Exception('USP timeout'));

      // Service does NOT map errors — raw exception propagates
      expect(() => svc.fetchSnapshot(), throwsA(isA<Exception>()));
    });
  });
}
