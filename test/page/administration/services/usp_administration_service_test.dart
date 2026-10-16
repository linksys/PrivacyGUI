import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';

class MockUspClient extends Mock implements UspClient {}

const _upnpEnable = 'Device.UPnP.Device.Enable';
const _sipEnable = 'Device.Firewall.ConnectionTracking.SIP.Enable';

Map<String, dynamic> _setSuccess() => {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };

Map<String, dynamic> _setFailure({
  String path = 'Device.UPnP.Device.Enable',
  int errorCode = 9007,
  String errorMessage = 'Invalid parameter value',
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

void main() {
  late MockUspClient mockUsp;
  late UspAdministrationService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspAdministrationService(mockUsp);
  });

  /// Each definition's Get, answered by its own leaves: the service reads UPnP
  /// and SIP ALG with separate Gets, so a stub keyed on the whole path list
  /// would pin the order of two calls the service is free to run in parallel.
  void answerGets({String upnp = '1', String? sip = '0'}) {
    when(() => mockUsp.get(any())).thenAnswer((inv) async {
      final paths = inv.positionalArguments.first as List<String>;
      if (paths.contains(_upnpEnable)) {
        return {_upnpEnable: upnp, 'Device.UPnP.Device.UPnPIGD': upnp};
      }
      if (paths.contains(_sipEnable)) {
        return {if (sip != null) _sipEnable: sip};
      }
      return {};
    });
  }

  group('UspAdministrationService - fetch', () {
    test('reads Device.UPnP.Device.Enable as the UPnP switch', () async {
      answerGets(upnp: '1');

      final settings = await svc.fetch();

      expect(settings.upnpEnabled, isTrue);
      verify(() => mockUsp.get([
            'Device.UPnP.Device.Enable',
            'Device.UPnP.Device.UPnPIGD',
          ])).called(1);
    });

    test('reads off as off', () async {
      answerGets(upnp: '0');

      expect((await svc.fetch()).upnpEnabled, isFalse);
    });

    test('a firmware without Device.UPnP fails the fetch, not a silent off',
        () {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {});

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test(
        'reads Device.Firewall.ConnectionTracking.SIP.Enable as the SIP ALG '
        'switch', () async {
      answerGets(sip: '1');

      final settings = await svc.fetch();

      expect(settings.sipAlgEnabled, isTrue);
      verify(() => mockUsp.get([_sipEnable])).called(1);
    });

    test('SIP ALG reads off on a factory-default router', () async {
      // FWDEV#217: default 0, as on 1.0. Measured `Enable => 0` on 26101472.
      answerGets(sip: '0');

      expect((await svc.fetch()).sipAlgEnabled, isFalse);
    });

    test('a firmware without the SIP leaf fails the fetch, not a silent off',
        () {
      // The leaf is required: it ships on FLWRT 2.0, and an absent one read as
      // "off" would hide a firmware that cannot honour the switch.
      answerGets(sip: null);

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test('maps a USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      expect(() => svc.fetch(), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspAdministrationService - setUpnpEnabled', () {
    test('writes Enable alone, in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());

      await svc.setUpnpEnabled(false);

      // Never UPnPIGD: it is read-only and follows Enable.
      verify(() => mockUsp.set(
            {'Device.UPnP.Device.Enable': false},
            allowPartial: false,
          )).called(1);
    });

    test('a partial result is a partial failure, not a success', () {
      // A one-leaf Set should not come back partial, but the parser can say so
      // and the branch must not read as success if it ever does.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {
                  'data': {'Device.UPnP.Device.UPnPIGD': '1'},
                  'error': {
                    'Device.UPnP.Device.Enable': {
                      'errorCode': 9007,
                      'errorMessage': 'Invalid parameter value',
                    },
                  },
                },
              });

      expect(() => svc.setUpnpEnabled(false),
          throwsA(isA<UspPartialFailureError>()));
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setFailure());

      expect(() => svc.setUpnpEnabled(true),
          throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(() => svc.setUpnpEnabled(true), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspAdministrationService - setSipAlgEnabled', () {
    test('writes ConnectionTracking.SIP.Enable alone, in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());

      await svc.setSipAlgEnabled(true);

      // Not Device.NAT.ALG.*: that path is invalid on FLWRT (FW, #875).
      verify(() => mockUsp.set({_sipEnable: true}, allowPartial: false))
          .called(1);
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setFailure(path: _sipEnable));

      expect(() => svc.setSipAlgEnabled(true),
          throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
          () => svc.setSipAlgEnabled(false), throwsA(isA<ConnectivityError>()));
    });
  });
}
