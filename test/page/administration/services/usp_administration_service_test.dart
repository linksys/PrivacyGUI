import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';

class MockUspClient extends Mock implements UspClient {}

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

  group('UspAdministrationService - fetch', () {
    test('reads Device.UPnP.Device.Enable as the UPnP switch', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.UPnP.Device.Enable': '1',
            'Device.UPnP.Device.UPnPIGD': '1',
          });

      final settings = await svc.fetch();

      expect(settings.upnpEnabled, isTrue);
      verify(() => mockUsp.get([
            'Device.UPnP.Device.Enable',
            'Device.UPnP.Device.UPnPIGD',
          ])).called(1);
    });

    test('reads off as off', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.UPnP.Device.Enable': '0',
            'Device.UPnP.Device.UPnPIGD': '0',
          });

      expect((await svc.fetch()).upnpEnabled, isFalse);
    });

    test('a firmware without Device.UPnP fails the fetch, not a silent off',
        () {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {});

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
}
