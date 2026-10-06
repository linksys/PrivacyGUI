import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

class MockUspClient extends Mock implements UspClient {}

// WASM v0.11.0 set-result shapes consumed by UspResultParser.parseSetResult.
Map<String, dynamic> _setSuccess() => {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };

Map<String, dynamic> _setPartial({
  String path = 'Device.WiFi.Radio.2.AutoChannelEnable',
  int errorCode = 7008,
  String errorMessage = 'Invalid value',
}) =>
    {
      'success': true,
      'result': {
        'data': {'Device.WiFi.Radio.1.IEEE80211hEnabled': false},
        'error': {
          path: {'errorCode': errorCode, 'errorMessage': errorMessage},
        },
      },
    };

Map<String, dynamic> _setFailure({
  String path = 'bulk_operation',
  int errorCode = 7004,
  String errorMessage = 'Operation failed',
}) =>
    {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {'errorCode': errorCode, 'errorMessage': errorMessage},
        },
      },
    };

/// A per-path SET error whose request never got an answer.
Map<String, dynamic> _setUnanswered() => {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          'Device.WiFi.Radio.1.IEEE80211hEnabled': {
            'errorCode': 9999,
            'errorMessage': 'Transport error: Failed to fetch',
          },
        },
      },
    };

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
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());

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
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());

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

    test('forces AutoChannelEnable in the same set for given paths', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());

      await svc.setIeee80211hEnabled(
        radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
        enabled: false,
        forceAutoChannelPaths: ['Device.WiFi.Radio.2.'],
      );

      // Radio.2 (parked on a DFS channel) also gets AutoChannelEnable=true;
      // Radio.1 keeps its channel settings.
      verify(() => mockUsp.set({
            'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
            'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
            'Device.WiFi.Radio.2.AutoChannelEnable': true,
          })).called(1);
    });

    test(
        'a lost reply is "unanswered", not a failure — #1460: the DFS SET '
        'took 35.4 s and had applied', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setUnanswered());

      final outcome = await svc.setIeee80211hEnabled(
        radioPaths: ['Device.WiFi.Radio.1.'],
        enabled: false,
      );

      expect(outcome, WifiWriteOutcome.unanswered);
    });

    test('an answered SET is confirmed', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());

      expect(
        await svc.setIeee80211hEnabled(
          radioPaths: ['Device.WiFi.Radio.1.'],
          enabled: true,
        ),
        WifiWriteOutcome.confirmed,
      );
    });

    group('planIeee80211h', () {
      test(
          'proof is only the radios whose DFS value changes — an unchanged '
          'one would read back "matching" either way', () {
        final plan = svc.planIeee80211h(
          current: {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false
          },
          radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
          enabled: false,
          forceAutoChannelPaths: ['Device.WiFi.Radio.1.'],
        );

        expect(plan.params, {
          'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
          'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
          'Device.WiFi.Radio.1.AutoChannelEnable': true,
        });
        // Radio.2 was already off; the forced AutoChannelEnable rides along.
        expect(plan.proof, {'Device.WiFi.Radio.1.IEEE80211hEnabled': false});
      });

      test("the plan's send issues exactly the planned params, once", () async {
        when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());
        final plan = svc.planIeee80211h(
          current: {'Device.WiFi.Radio.1.': true},
          radioPaths: ['Device.WiFi.Radio.1.'],
          enabled: false,
          forceAutoChannelPaths: ['Device.WiFi.Radio.1.'],
        );

        expect(await plan.send(), WifiWriteOutcome.confirmed);

        verify(() => mockUsp.set(plan.params)).called(1);
      });

      test('read-back fails closed on an empty proof, and reads nothing',
          () async {
        expect(await svc.isIeee80211hApplied(const {}), isFalse);
        verifyNever(() => mockUsp.get(any()));
      });

      test('read-back is true only when every proved radio reads back',
          () async {
        when(() => mockUsp.get(any())).thenAnswer((_) async => {
              'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
              'Device.WiFi.Radio.2.IEEE80211hEnabled': true,
            });

        expect(
          await svc.isIeee80211hApplied(
              {'Device.WiFi.Radio.1.IEEE80211hEnabled': false}),
          isTrue,
        );
        expect(
          await svc.isIeee80211hApplied({
            'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
            'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
          }),
          isFalse,
        );
      });
    });

    test('empty forceAutoChannelPaths writes no AutoChannelEnable', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setSuccess());

      await svc.setIeee80211hEnabled(
        radioPaths: ['Device.WiFi.Radio.1.'],
        enabled: false,
      );

      verify(() => mockUsp.set({
            'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
          })).called(1);
    });

    test('throws UspPartialFailureError on firmware partial rejection',
        () async {
      // Firmware accepts IEEE80211hEnabled but rejects the forced
      // AutoChannelEnable write — must not be silently swallowed.
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setPartial());

      expect(
        () => svc.setIeee80211hEnabled(
          radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
          enabled: false,
          forceAutoChannelPaths: ['Device.WiFi.Radio.2.'],
        ),
        throwsA(isA<UspPartialFailureError>()),
      );
    });

    test('throws UspCompleteFailureError on complete failure', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => _setFailure());

      expect(
        () => svc.setIeee80211hEnabled(
          radioPaths: ['Device.WiFi.Radio.1.'],
          enabled: false,
        ),
        throwsA(isA<UspCompleteFailureError>()),
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
