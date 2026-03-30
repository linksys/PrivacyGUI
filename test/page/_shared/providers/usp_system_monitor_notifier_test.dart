import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  final systemInfoResponse = <String, dynamic>{
    'Device.DeviceInfo.Manufacturer': 'Linksys',
    'Device.DeviceInfo.ModelName': 'M60TB',
    'Device.DeviceInfo.SerialNumber': 'ABC123',
    'Device.DeviceInfo.HardwareVersion': '1.0',
    'Device.DeviceInfo.SoftwareVersion': '1.0.16',
    'Device.DeviceInfo.UpTime': '3600',
    'Device.DeviceInfo.MemoryStatus.Total': '1000000',
    'Device.DeviceInfo.MemoryStatus.Free': '400000',
    'Device.DeviceInfo.ProcessStatus.CPUUsage': '35',
  };

  setUp(() {
    mockUsp = MockUspService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUsp.get(any())).thenAnswer((_) async => systemInfoResponse);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
      ],
    );
  }

  /// Create container and wait for build microtask + initial fetch.
  Future<ProviderContainer> createAndWait() async {
    final container = createContainer();
    // Trigger provider creation so build() runs and schedules microtask.
    container.read(uspSystemMonitorProvider);
    // Wait for microtask (setRefreshInterval) + async fetch to complete.
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    return container;
  }

  group('UspSystemMonitorNotifier', () {
    test('build auto-starts with 30s default interval', () async {
      final container = await createAndWait();

      final state = container.read(uspSystemMonitorProvider);
      expect(state.refreshInterval, const Duration(seconds: 30));
      container.dispose();
    });

    test('pushSnapshot appends to history', () async {
      final container = await createAndWait();

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null); // Stop auto-timer.
      final snapshot = SystemSnapshot(
        timestamp: DateTime(2026, 1, 1),
        cpuPercent: 50,
        memoryPercent: 60,
        totalMemoryKb: 1000,
        freeMemoryKb: 400,
      );
      notifier.pushSnapshot(snapshot);

      final state = container.read(uspSystemMonitorProvider);
      expect(state.history.last.cpuPercent, 50);
      container.dispose();
    });

    test('pushSnapshot respects maxHistory ring buffer', () async {
      final container = await createAndWait();

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null); // Stop auto-timer.
      // Push more than maxHistory snapshots.
      for (int i = 0; i < SystemMonitorState.maxHistory + 5; i++) {
        notifier.pushSnapshot(SystemSnapshot(
          timestamp: DateTime(2026, 1, 1, 0, i),
          cpuPercent: i,
          memoryPercent: i,
          totalMemoryKb: 1000,
          freeMemoryKb: 500,
        ));
      }

      final state = container.read(uspSystemMonitorProvider);
      expect(state.history.length, SystemMonitorState.maxHistory);
      // Oldest should have been dropped; the first should be index 5.
      expect(state.history.first.cpuPercent, 5);
      container.dispose();
    });

    test('setRefreshInterval(null) stops timer', () async {
      final container = await createAndWait();

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null);

      final state = container.read(uspSystemMonitorProvider);
      expect(state.refreshInterval, isNull);
      container.dispose();
    });

    test('fetchNow returns early when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
        ],
      );
      // Trigger build + wait for microtask.
      container.read(uspSystemMonitorProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      await notifier.fetchNow();

      verifyNever(() => mockUsp.get(any()));
      container.dispose();
    });

    test('fetchNow returns early when not authenticated', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      final container = await createAndWait();
      // Clear interactions from other providers triggered during setup
      clearInteractions(mockUsp);

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null);
      await notifier.fetchNow();

      verifyNever(() => mockUsp.get(any()));
      container.dispose();
    });

    test('fetchNow computes CPU and memory percentages', () async {
      final container = await createAndWait();

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null);
      await notifier.fetchNow();

      final state = container.read(uspSystemMonitorProvider);
      final latest = state.latest;
      expect(latest, isNotNull);
      expect(latest!.cpuPercent, 35);
      // Memory: (1000000 - 400000) / 1000000 * 100 = 60
      expect(latest.memoryPercent, 60);
      expect(latest.totalMemoryKb, 1000000);
      expect(latest.freeMemoryKb, 400000);
      container.dispose();
    });

    test('fetchNow handles error gracefully', () async {
      when(() => mockUsp.get(any())).thenThrow(Exception('fetch error'));
      final container = await createAndWait();

      final notifier = container.read(uspSystemMonitorProvider.notifier);
      notifier.setRefreshInterval(null);
      await notifier.fetchNow();

      final state = container.read(uspSystemMonitorProvider);
      expect(state.isFetching, isFalse);
      container.dispose();
    });
  });
}
