import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mlo_status_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_mesh_mlo_data_service.dart';

class MockUspMeshMloDataService extends Mock implements UspMeshMloDataService {}

/// The L1 read of `Device.X_LINKSYS_Mesh.MLOStatus` (#1692): what the MLO
/// card's badge shows. Read-only, and it depends on what the WiFi tab edits,
/// so it lives outside the Advanced tab's page-entry snapshot.
void main() {
  late MockUspMeshMloDataService svc;

  setUp(() => svc = MockUspMeshMloDataService());

  ProviderContainer container({required bool mloOffered}) {
    final c = ProviderContainer(overrides: [
      uspMeshMloDataServiceProvider.overrideWithValue(svc),
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities({if (mloOffered) DeviceCapability.wifiMlo})),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('mloStatusProvider - read', () {
    test('reads the status the router reports', () async {
      when(() => svc.fetchStatus()).thenAnswer((_) async => MloStatus.inactive);

      expect(await container(mloOffered: true).read(mloStatusProvider.future),
          MloStatus.inactive);
    });

    test('a router without MLO has no status and is never asked', () async {
      expect(await container(mloOffered: false).read(mloStatusProvider.future),
          isNull);
      verifyNever(() => svc.fetchStatus());
    });

    test('a failed read is an error, not "no status"', () async {
      when(() => svc.fetchStatus())
          .thenThrow(const NetworkError(detail: 'Failed to fetch'));

      await expectLater(
          container(mloOffered: true).read(mloStatusProvider.future),
          throwsA(isA<NetworkError>()));
    });
  });

  group('mloStatusProvider - invalidate', () {
    test('reads the router again', () async {
      var status = MloStatus.inactive;
      when(() => svc.fetchStatus()).thenAnswer((_) async => status);
      final c = container(mloOffered: true);
      expect(await c.read(mloStatusProvider.future), MloStatus.inactive);

      // The WiFi tab moved both bands to WPA3 with one password.
      status = MloStatus.active;
      c.invalidate(mloStatusProvider);

      expect(await c.read(mloStatusProvider.future), MloStatus.active);
    });

    test('a failed read is not kept for the session', () async {
      var fail = true;
      when(() => svc.fetchStatus()).thenAnswer((_) async {
        if (fail) throw const NetworkError(detail: 'Failed to fetch');
        return MloStatus.active;
      });
      final c = container(mloOffered: true);
      await expectLater(
          c.read(mloStatusProvider.future), throwsA(isA<NetworkError>()));

      fail = false;
      c.invalidate(mloStatusProvider);

      expect(await c.read(mloStatusProvider.future), MloStatus.active);
    });
  });
}
