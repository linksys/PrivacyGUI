import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/services/usp_traffic_analysis_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspTrafficAnalysisService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspTrafficAnalysisService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  void stubTrafficStats({
    int wanBytesSent = 1000000,
    int wanBytesReceived = 2000000,
    int wanPacketsSent = 1000,
    int wanPacketsReceived = 2000,
    int wanErrorsSent = 0,
    int wanErrorsReceived = 0,
    int wanDiscardsSent = 0,
    int wanDiscardsReceived = 0,
    int lanBytesSent = 500000,
    int lanBytesReceived = 1000000,
    int lanPacketsSent = 500,
    int lanPacketsReceived = 1000,
    int lanErrorsSent = 1,
    int lanErrorsReceived = 2,
    int lanDiscardsSent = 3,
    int lanDiscardsReceived = 4,
  }) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async => {
              // WAN = Interface.5, LAN = Interface.3, resolved by Alias
              'Device.IP.Interface.3.Alias': 'lan',
              'Device.IP.Interface.5.Alias': 'wan',
              'Device.IP.Interface.5.Stats.BytesSent': wanBytesSent.toString(),
              'Device.IP.Interface.5.Stats.BytesReceived':
                  wanBytesReceived.toString(),
              'Device.IP.Interface.5.Stats.PacketsSent':
                  wanPacketsSent.toString(),
              'Device.IP.Interface.5.Stats.PacketsReceived':
                  wanPacketsReceived.toString(),
              'Device.IP.Interface.5.Stats.ErrorsSent':
                  wanErrorsSent.toString(),
              'Device.IP.Interface.5.Stats.ErrorsReceived':
                  wanErrorsReceived.toString(),
              'Device.IP.Interface.5.Stats.DiscardPacketsSent':
                  wanDiscardsSent.toString(),
              'Device.IP.Interface.5.Stats.DiscardPacketsReceived':
                  wanDiscardsReceived.toString(),
              'Device.IP.Interface.3.Stats.BytesSent': lanBytesSent.toString(),
              'Device.IP.Interface.3.Stats.BytesReceived':
                  lanBytesReceived.toString(),
              'Device.IP.Interface.3.Stats.PacketsSent':
                  lanPacketsSent.toString(),
              'Device.IP.Interface.3.Stats.PacketsReceived':
                  lanPacketsReceived.toString(),
              'Device.IP.Interface.3.Stats.ErrorsSent':
                  lanErrorsSent.toString(),
              'Device.IP.Interface.3.Stats.ErrorsReceived':
                  lanErrorsReceived.toString(),
              'Device.IP.Interface.3.Stats.DiscardPacketsSent':
                  lanDiscardsSent.toString(),
              'Device.IP.Interface.3.Stats.DiscardPacketsReceived':
                  lanDiscardsReceived.toString(),
            });
  }

  // ---------------------------------------------------------------------------
  // fetchBaselines
  // ---------------------------------------------------------------------------

  group('UspTrafficAnalysisService — fetchBaselines', () {
    test('returns baselines for WAN and LAN interfaces', () async {
      stubTrafficStats();

      final result = await svc.fetchBaselines();

      expect(result.keys,
          containsAll([TrafficInterface.wan, TrafficInterface.lan]));
    });

    test('WAN baseline contains correct byte counts', () async {
      stubTrafficStats(
        wanBytesSent: 1234567,
        wanBytesReceived: 7654321,
      );

      final result = await svc.fetchBaselines();
      final wan = result[TrafficInterface.wan]!;

      expect(wan.bytesSent, 1234567);
      expect(wan.bytesReceived, 7654321);
    });

    test('WAN baseline contains correct packet counts', () async {
      stubTrafficStats(
        wanPacketsSent: 1000,
        wanPacketsReceived: 2000,
      );

      final result = await svc.fetchBaselines();
      final wan = result[TrafficInterface.wan]!;

      expect(wan.packetsSent, 1000);
      expect(wan.packetsReceived, 2000);
    });

    test('WAN baseline contains error and discard counts', () async {
      stubTrafficStats(
        wanErrorsSent: 5,
        wanErrorsReceived: 10,
        wanDiscardsSent: 15,
        wanDiscardsReceived: 20,
      );

      final result = await svc.fetchBaselines();
      final wan = result[TrafficInterface.wan]!;

      expect(wan.errorsSent, 5);
      expect(wan.errorsReceived, 10);
      expect(wan.discardsSent, 15);
      expect(wan.discardsReceived, 20);
    });

    test('LAN baseline contains correct byte counts', () async {
      stubTrafficStats(
        lanBytesSent: 111111,
        lanBytesReceived: 222222,
      );

      final result = await svc.fetchBaselines();
      final lan = result[TrafficInterface.lan]!;

      expect(lan.bytesSent, 111111);
      expect(lan.bytesReceived, 222222);
    });

    test('LAN baseline contains error and discard counts', () async {
      stubTrafficStats(
        lanErrorsSent: 1,
        lanErrorsReceived: 2,
        lanDiscardsSent: 3,
        lanDiscardsReceived: 4,
      );

      final result = await svc.fetchBaselines();
      final lan = result[TrafficInterface.lan]!;

      expect(lan.errorsSent, 1);
      expect(lan.errorsReceived, 2);
      expect(lan.discardsSent, 3);
      expect(lan.discardsReceived, 4);
    });
  });

  // ---------------------------------------------------------------------------
  // error handling (no mapping — raw exceptions propagate)
  // ---------------------------------------------------------------------------

  group('UspTrafficAnalysisService — error handling', () {
    test('fetchBaselines throws raw exception (no error mapping)', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow(Exception('USP timeout'));

      // Service does NOT map errors — raw exception propagates
      expect(() => svc.fetchBaselines(), throwsA(isA<Exception>()));
    });
  });
}
