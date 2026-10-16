import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
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

  // -------------------------------------------------------------------------
  // The tab's one Set (#1692)
  // -------------------------------------------------------------------------

  group('UspWifiAdvancedService - planSave', () {
    const off = WifiAdvancedSettings(ieee80211hByRadio: {
      'Device.WiFi.Radio.1.': false,
      'Device.WiFi.Radio.2.': false,
    });

    test('steering, MLO and DFS go out in one Set, only what changed', () {
      final plan = svc.planSave(
        original: off,
        current: off.copyWith(
          clientSteering: true,
          mloEnabled: true,
          ieee80211hByRadio: {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          },
        ),
      );

      // The bench's one Set (2026-10-15) plus a steering leaf.
      expect(plan.params, {
        'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': true,
        'Device.X_LINKSYS_Mesh.MLOEnabled': true,
        'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
        'Device.WiFi.Radio.2.IEEE80211hEnabled': true,
      });
      expect(plan.proof, plan.params,
          reason: 'every value here is a change the router reads back');
    });

    test('an unchanged tab plans nothing', () {
      expect(svc.planSave(original: off, current: off).params, isEmpty);
    });

    test('a steering-only save writes the steering leaf alone', () {
      final plan = svc.planSave(
          original: off, current: off.copyWith(nodeSteering: true));

      expect(plan.params, {'Device.X_LINKSYS_Mesh.NodeSteeringEnabled': true});
    });

    test('DFS: every radio written, only the changed ones are proof', () {
      const mixed = WifiAdvancedSettings(ieee80211hByRadio: {
        'Device.WiFi.Radio.1.': true,
        'Device.WiFi.Radio.2.': false,
      });
      final plan = svc.planSave(
        original: mixed,
        current: mixed.copyWith(ieee80211hByRadio: {
          'Device.WiFi.Radio.1.': false,
          'Device.WiFi.Radio.2.': false,
        }),
        forceAutoChannelPaths: ['Device.WiFi.Radio.1.'],
      );

      expect(plan.params, {
        'Device.WiFi.Radio.1.IEEE80211hEnabled': false,
        'Device.WiFi.Radio.2.IEEE80211hEnabled': false,
        'Device.WiFi.Radio.1.AutoChannelEnable': true,
      });
      // Radio.2 was already off, and the forced AutoChannelEnable rides along
      // in the same Set: neither tells a landed write from the old state.
      expect(plan.proof, {'Device.WiFi.Radio.1.IEEE80211hEnabled': false});
    });

    test('the plan sends its params once, with allowPartial', () async {
      // One Set across dm-reflector and wifidmd: an atomic one is refused
      // with 7005; allowPartial was accepted and applied all of it (bench).
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());
      final plan =
          svc.planSave(original: off, current: off.copyWith(mloEnabled: true));

      expect(await plan.send(), WifiWriteOutcome.confirmed);

      verify(() => mockUsp.set(
            {'Device.X_LINKSYS_Mesh.MLOEnabled': true},
            allowPartial: true,
          )).called(1);
    });

    test('a lost reply is "unanswered", for the caller to read back', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setUnanswered());
      final plan = svc.planSave(
          original: off,
          current: off.copyWith(ieee80211hByRadio: {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          }));

      expect(await plan.send(), WifiWriteOutcome.unanswered);
    });

    test('a part refused inside the Set throws, not "saved"', () {
      // MLOEnabled on a child node: fault 9001 (dm-reflector's setter).
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setPartial(
                path: 'Device.X_LINKSYS_Mesh.MLOEnabled',
                errorCode: 9001,
                errorMessage: 'Request denied',
              ));
      final plan = svc.planSave(
          original: off,
          current: off.copyWith(
            mloEnabled: true,
            ieee80211hByRadio: {
              'Device.WiFi.Radio.1.': true,
              'Device.WiFi.Radio.2.': true,
            },
          ));

      expect(plan.send, throwsA(isA<UspPartialFailureError>()));
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setFailure(
                path: 'Device.X_LINKSYS_Mesh.NodeSteeringEnabled',
                errorCode: 9007,
                errorMessage: 'Invalid parameter value',
              ));
      final plan = svc.planSave(
          original: off, current: off.copyWith(nodeSteering: true));

      expect(plan.send, throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');
      final plan = svc.planSave(
          original: off, current: off.copyWith(clientSteering: true));

      expect(plan.send, throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspWifiAdvancedService - isApplied', () {
    test('fails closed on an empty proof, and reads nothing', () async {
      expect(await svc.isApplied(const {}), isFalse);
      verifyNever(() => mockUsp.get(any()));
    });

    test('reads every proved leaf in one Get and compares it', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '1',
            'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': '0',
            'Device.WiFi.Radio.1.IEEE80211hEnabled': '1',
          });
      const proof = {
        'Device.X_LINKSYS_Mesh.MLOEnabled': true,
        'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': false,
        'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
      };

      expect(await svc.isApplied(proof), isTrue);
      verify(() => mockUsp.get(proof.keys.toList())).called(1);
    });

    test('one part reading the old value is "not applied"', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '0',
            'Device.WiFi.Radio.1.IEEE80211hEnabled': '1',
          });

      expect(
        await svc.isApplied({
          'Device.X_LINKSYS_Mesh.MLOEnabled': true,
          'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
        }),
        isFalse,
      );
    });

    test(
        'a leaf missing from the read-back is a failed read, not "not '
        'applied" — the router answers with no rows while it reloads',
        () async {
      // Bench round 3, 2026-10-07: WiFi GETs came back `{}` mid-reload.
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '1',
          });

      expect(
        svc.isApplied({
          'Device.X_LINKSYS_Mesh.MLOEnabled': true,
          'Device.WiFi.Radio.1.IEEE80211hEnabled': true,
        }),
        throwsA(isA<ServiceError>()),
      );
    });

    test('a failed Get maps to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Failed to fetch');

      expect(
        svc.isApplied({'Device.X_LINKSYS_Mesh.MLOEnabled': true}),
        throwsA(isA<ServiceError>()),
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
  });

  // -------------------------------------------------------------------------
  // Mesh steering (#1661)
  // -------------------------------------------------------------------------

  group('UspWifiAdvancedService - fetchSteering', () {
    test('reads both Device.X_LINKSYS_Mesh leaves in one Get', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': '1',
            'Device.X_LINKSYS_Mesh.NodeSteeringEnabled': '0',
          });

      final result = await svc.fetchSteering();

      expect(result.clientSteering, isTrue);
      expect(result.nodeSteering, isFalse);
      verify(() => mockUsp.get([
            'Device.X_LINKSYS_Mesh.ClientSteeringEnabled',
            'Device.X_LINKSYS_Mesh.NodeSteeringEnabled',
          ])).called(1);
    });

    test('a missing leaf maps to a ServiceError, not a silent false', () {
      // The codegen class requires both leaves, so a firmware without the
      // object fails the fetch (9998) instead of drawing two OFF switches.
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': '1',
          });

      expect(() => svc.fetchSteering(), throwsA(isA<ServiceError>()));
    });

    test('maps a USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      expect(() => svc.fetchSteering(), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspWifiAdvancedService - fetchMloEnabled (#1692)', () {
    test('reads the switch in the definition\'s one Get', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '1',
            'Device.X_LINKSYS_Mesh.MLOStatus': 'Inactive',
          });

      expect(await svc.fetchMloEnabled(), isTrue);
      verify(() => mockUsp.get([
            'Device.X_LINKSYS_Mesh.MLOEnabled',
            'Device.X_LINKSYS_Mesh.MLOStatus',
          ])).called(1);
    });

    test('a missing leaf maps to a ServiceError, not a silent off', () {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '0',
          });

      expect(() => svc.fetchMloEnabled(), throwsA(isA<ServiceError>()));
    });
  });
}
