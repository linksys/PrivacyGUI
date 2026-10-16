import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mlo_status_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

class _MockService extends Mock implements UspWifiAdvancedService {}

/// The L1 read of `Device.X_LINKSYS_Mesh.MLOStatus` (#1692): what the MLO
/// card's badge shows. Read-only, and it depends on what the WiFi tab edits,
/// so it lives outside the Advanced tab's page-entry snapshot.
void main() {
  late _MockService svc;

  setUp(() => svc = _MockService());

  ProviderContainer container({required bool mloOffered}) {
    final c = ProviderContainer(overrides: [
      uspWifiAdvancedServiceProvider.overrideWithValue(svc),
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities({if (mloOffered) DeviceCapability.wifiMlo})),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('reads the status the router reports', () async {
    when(() => svc.fetchMlo())
        .thenAnswer((_) async => (enabled: true, status: MloStatus.inactive));

    expect(await container(mloOffered: true).read(mloStatusProvider.future),
        MloStatus.inactive);
  });

  test('a router without MLO has no status and is never asked', () async {
    expect(await container(mloOffered: false).read(mloStatusProvider.future),
        isNull);
    verifyNever(() => svc.fetchMlo());
  });

  test('invalidating it reads the router again', () async {
    var status = MloStatus.inactive;
    when(() => svc.fetchMlo())
        .thenAnswer((_) async => (enabled: true, status: status));
    final c = container(mloOffered: true);
    expect(await c.read(mloStatusProvider.future), MloStatus.inactive);

    // The WiFi tab moved both bands to WPA3 with one password.
    status = MloStatus.active;
    c.invalidate(mloStatusProvider);

    expect(await c.read(mloStatusProvider.future), MloStatus.active);
  });

  test('a failed read is an error, not "no status"', () async {
    when(() => svc.fetchMlo())
        .thenThrow(const NetworkError(detail: 'Failed to fetch'));

    await expectLater(
        container(mloOffered: true).read(mloStatusProvider.future),
        throwsA(isA<NetworkError>()));
  });
}
