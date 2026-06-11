import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';

class MockUspClient extends Mock implements UspClient {}

class _AlwaysAuthenticatedNotifier extends AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.authenticated;
}

class _NotAuthenticatedNotifier extends AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.loggedOut;
}

void main() {
  late MockUspClient mockUsp;

  Map<String, dynamic> makeTrafficResponse({
    int wanSent = 1000,
    int wanRecv = 2000,
    int lanSent = 500,
    int lanRecv = 1500,
  }) {
    return {
      'Device.IP.Interface.2.Stats.BytesSent': '$wanSent',
      'Device.IP.Interface.2.Stats.BytesReceived': '$wanRecv',
      'Device.IP.Interface.2.Stats.PacketsSent': '100',
      'Device.IP.Interface.2.Stats.PacketsReceived': '200',
      'Device.IP.Interface.2.Stats.ErrorsSent': '0',
      'Device.IP.Interface.2.Stats.ErrorsReceived': '0',
      'Device.IP.Interface.2.Stats.DiscardPacketsSent': '0',
      'Device.IP.Interface.2.Stats.DiscardPacketsReceived': '0',
      'Device.IP.Interface.1.Stats.BytesSent': '$lanSent',
      'Device.IP.Interface.1.Stats.BytesReceived': '$lanRecv',
      'Device.IP.Interface.1.Stats.PacketsSent': '50',
      'Device.IP.Interface.1.Stats.PacketsReceived': '150',
      'Device.IP.Interface.1.Stats.ErrorsSent': '0',
      'Device.IP.Interface.1.Stats.ErrorsReceived': '0',
      'Device.IP.Interface.1.Stats.DiscardPacketsSent': '0',
      'Device.IP.Interface.1.Stats.DiscardPacketsReceived': '0',
    };
  }

  setUp(() {
    mockUsp = MockUspClient();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        appConnectionStateProvider.overrideWith(() {
          return _AlwaysAuthenticatedNotifier();
        }),
      ],
    );
  }

  /// Create container and wait for build microtask + initial fetch.
  Future<ProviderContainer> createAndWait() async {
    when(() => mockUsp.get(any()))
        .thenAnswer((_) async => makeTrafficResponse());
    final container = createContainer();
    // Trigger provider creation so build() runs and schedules microtask.
    container.read(uspTrafficAnalysisProvider);
    // Wait for microtask (setRefreshInterval) + async fetch to complete.
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    return container;
  }

  group('UspTrafficAnalysisNotifier', () {
    test('build starts with 10s default interval', () async {
      final container = await createAndWait();

      final state = container.read(uspTrafficAnalysisProvider);
      expect(state.refreshInterval, const Duration(seconds: 10));
      container.dispose();
    });

    test('setRefreshInterval(null) stops timer', () async {
      final container = await createAndWait();

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null);

      final state = container.read(uspTrafficAnalysisProvider);
      expect(state.refreshInterval, isNull);
      container.dispose();
    });

    test('first fetch sets baseline only, no history', () async {
      final container = await createAndWait();

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null); // Stop auto-timer.

      // createAndWait() already triggered the first fetch (baseline set).
      final state = container.read(uspTrafficAnalysisProvider);
      expect(state.lastBaselines, isNotNull);
      expect(state.lastTimestamp, isNotNull);
      expect(state.history, isEmpty);
      expect(state.isFetching, isFalse);
      container.dispose();
    });

    test('second fetch computes rates and appends to history', () async {
      final container = await createAndWait();
      // createAndWait already did the first fetch (baseline set).

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null);

      // Ensure non-zero elapsed time between baseline and next fetch.
      await Future.delayed(Duration(milliseconds: 2));

      // Next fetch with higher counters → delta produces positive rates.
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          makeTrafficResponse(
              wanSent: 2000, wanRecv: 4000, lanSent: 1000, lanRecv: 3000));
      await notifier.fetchNow();

      final state = container.read(uspTrafficAnalysisProvider);
      // After 2 fetches, there should be at least 1 snapshot in history.
      expect(state.history, isNotEmpty);

      final latest = state.latest;
      expect(latest, isNotNull);

      // WAN interface should have positive rates (delta = 1000 bytes).
      final wan = latest!.interfaces[TrafficInterface.wan];
      expect(wan, isNotNull);
      expect(wan!.uploadBytesPerSec, greaterThan(0));
      expect(wan.downloadBytesPerSec, greaterThan(0));
      container.dispose();
    });

    test('counter wraparound produces zero rates', () async {
      final container = await createAndWait();

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null);

      // Ensure non-zero elapsed time.
      await Future.delayed(Duration(milliseconds: 2));

      // Second fetch with LOWER counters (simulating counter reset/wraparound).
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          makeTrafficResponse(
              wanSent: 500, wanRecv: 1000, lanSent: 200, lanRecv: 700));
      await notifier.fetchNow();

      final state = container.read(uspTrafficAnalysisProvider);
      expect(state.history, isNotEmpty);

      final wan = state.latest!.interfaces[TrafficInterface.wan]!;
      // Negative delta → clamped to 0.
      expect(wan.uploadBytesPerSec, 0);
      expect(wan.downloadBytesPerSec, 0);
      container.dispose();
    });

    test('fetchNow returns early when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          appConnectionStateProvider.overrideWith(() {
            return _AlwaysAuthenticatedNotifier();
          }),
        ],
      );
      // Trigger build + wait for microtask.
      container.read(uspTrafficAnalysisProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      await notifier.fetchNow();

      verifyNever(() => mockUsp.get(any()));
      container.dispose();
    });

    test('fetchNow returns early when not authenticated', () async {
      // Use _NotAuthenticatedNotifier to simulate logged out state
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(mockUsp),
          appConnectionStateProvider.overrideWith(() {
            return _NotAuthenticatedNotifier();
          }),
        ],
      );
      // Trigger build + wait for microtask.
      container.read(uspTrafficAnalysisProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      // Clear interactions from build phase
      clearInteractions(mockUsp);

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null);
      await notifier.fetchNow();

      verifyNever(() => mockUsp.get(any()));
      container.dispose();
    });

    test('fetch error sets isFetching false', () async {
      when(() => mockUsp.get(any())).thenThrow(Exception('network error'));
      final container = createContainer();
      // Trigger build + wait for microtask (will error during fetch).
      container.read(uspTrafficAnalysisProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspTrafficAnalysisProvider.notifier);
      notifier.setRefreshInterval(null);
      await notifier.fetchNow();

      final state = container.read(uspTrafficAnalysisProvider);
      expect(state.isFetching, isFalse);
      container.dispose();
    });
  });
}
