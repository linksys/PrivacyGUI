import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspWifiAdvancedService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspWifiAdvancedService(mockUsp);
  });

  group('UspWifiAdvancedService - fetchIeee80211h', () {
    test('parses per-radio IEEE80211hEnabled from USP response', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
            'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
          });

      final result = await svc.fetchIeee80211h();

      expect(result, {
        'Device.WiFi.Radio.1.': true,
        'Device.WiFi.Radio.2.': false,
      });
      verify(() => mockUsp.get(['Device.WiFi.Radio.*.IEEE80211hEnabled']))
          .called(1);
    });

    test('handles string true/false values', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.IEEE80211hEnabled': 'true',
            'Device.WiFi.Radio.2.IEEE80211hEnabled': '1',
            'Device.WiFi.Radio.3.IEEE80211hEnabled': 'false',
          });

      final result = await svc.fetchIeee80211h();

      expect(result['Device.WiFi.Radio.1.'], isTrue);
      expect(result['Device.WiFi.Radio.2.'], isTrue);
      expect(result['Device.WiFi.Radio.3.'], isFalse);
    });

    test('returns empty map when no radios report IEEE80211h', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {});

      final result = await svc.fetchIeee80211h();

      expect(result, isEmpty);
    });

    test('ignores unrelated keys in response', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
            'Device.WiFi.Radio.1.Channel': 36,
            'Device.WiFi.SSID.1.SSID': 'TestNet',
          });

      final result = await svc.fetchIeee80211h();

      expect(result, hasLength(1));
      expect(result['Device.WiFi.Radio.1.'], isTrue);
    });
  });

  group('UspWifiAdvancedService - setIeee80211hEnabled', () {
    test('sets IEEE80211hEnabled on all provided radio paths', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {});

      await svc.setIeee80211hEnabled(
        radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
        enabled: true,
      );

      verify(() => mockUsp.set({
            'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
            'Device.WiFi.Radio.2.IEEE80211hEnabled': true,
          })).called(1);
    });

    test('does nothing when radioPaths is empty', () async {
      await svc.setIeee80211hEnabled(radioPaths: [], enabled: true);

      verifyNever(() => mockUsp.set(any()));
    });

    test('sends false for all radios when disabling', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {});

      await svc.setIeee80211hEnabled(
        radioPaths: ['Device.WiFi.Radio.1.'],
        enabled: false,
      );

      verify(() => mockUsp.set({
            'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
          })).called(1);
    });

    test('throws NetworkError when USP set throws transport error', () async {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Transport error: Request timeout');

      expect(
        () => svc.setIeee80211hEnabled(
          radioPaths: ['Device.WiFi.Radio.1.'],
          enabled: true,
        ),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('UspWifiAdvancedService - error handling', () {
    test('fetchIeee80211h maps USP protocol error to ServiceError', () {
      when(() => mockUsp.get(any())).thenThrow(
        'Get failed: Protocol error: Decoding error: '
        'Path (Device.WiFi.Radio) does not exist (code: 7026)',
      );

      expect(
        () => svc.fetchIeee80211h(),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });

    test('fetchIeee80211h maps USP auth error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Authentication error: Session expired');

      expect(
        () => svc.fetchIeee80211h(),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });

    test('fetchIeee80211h maps non-USP error to UnexpectedError', () {
      when(() => mockUsp.get(any())).thenThrow('some random error');

      expect(
        () => svc.fetchIeee80211h(),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('setIeee80211hEnabled maps USP transport error to ServiceError', () {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
        () => svc.setIeee80211hEnabled(
          radioPaths: ['Device.WiFi.Radio.1.'],
          enabled: true,
        ),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });
}
