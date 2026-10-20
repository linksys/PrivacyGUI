import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_mesh_mlo_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient usp;
  late UspMeshMloDataService svc;

  setUp(() {
    usp = MockUspClient();
    svc = UspMeshMloDataService(usp);
  });

  group('UspMeshMloDataService - fetchStatus', () {
    test('reads the status in the definition\'s one Get', () async {
      // FW 2.0.3.26101472 after the MLO + DFS Set on WPA2 bands (bench).
      when(() => usp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '1',
            'Device.X_LINKSYS_Mesh.MLOStatus': 'Inactive',
          });

      expect(await svc.fetchStatus(), MloStatus.inactive);
      verify(() => usp.get([
            'Device.X_LINKSYS_Mesh.MLOEnabled',
            'Device.X_LINKSYS_Mesh.MLOStatus',
          ])).called(1);
    });

    for (final (raw, status) in [
      ('Disabled', MloStatus.disabled),
      ('Active', MloStatus.active),
      ('Inactive', MloStatus.inactive),
    ]) {
      test('$raw reads as ${status.name}', () async {
        when(() => usp.get(any())).thenAnswer((_) async => {
              'Device.X_LINKSYS_Mesh.MLOEnabled': '0',
              'Device.X_LINKSYS_Mesh.MLOStatus': raw,
            });

        expect(await svc.fetchStatus(), status);
      });
    }

    test('a status outside the contract is not drawn as one of its three',
        () async {
      when(() => usp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '1',
            'Device.X_LINKSYS_Mesh.MLOStatus': 'Pending',
          });

      expect(await svc.fetchStatus(), MloStatus.unknown);
    });

    test('a missing leaf maps to a ServiceError, not a silent status', () {
      when(() => usp.get(any())).thenAnswer((_) async => {
            'Device.X_LINKSYS_Mesh.MLOEnabled': '0',
          });

      expect(() => svc.fetchStatus(), throwsA(isA<ServiceError>()));
    });

    test('a USP error maps to ServiceError', () {
      when(() => usp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      expect(() => svc.fetchStatus(), throwsA(isA<ConnectivityError>()));
    });
  });
}
