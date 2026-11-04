import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';

class MockUspDhcpService extends Mock implements UspDhcpService {}

/// A save FW refuses re-reads what the router holds (linksys/PrivacyGUI#1698):
/// obuspa commits the rest of a refused Set (linksys/FWDEV#211).
void main() {
  late MockUspDhcpService svc;

  final saved = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.4.StaticAddress.5.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.10',
    enable: true,
  );
  const refused = InvalidInputError(
    field: DhcpReservationRefusalNames.invalidIp,
    code: 7012,
    detail: DhcpReservationRefusalNames.invalidIp,
  );

  setUpAll(() => registerFallbackValue(<DhcpReservationUIModel>[]));

  setUp(() => svc = MockUspDhcpService());

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      uspDhcpServiceProvider.overrideWithValue(svc),
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
    ]);
    c.listen(uspDhcpReservationsProvider, (_, __) {});
    return c;
  }

  void refuseSave() => when(() => svc.saveBatch(
        original: any(named: 'original'),
        current: any(named: 'current'),
      )).thenThrow(refused);

  test('a refused save shows the router\'s rows, and still throws FW\'s error',
      () async {
    // What the router holds after the refused Set: the name landed, the IP
    // did not.
    final onRouter = saved.copyWith(name: 'tv');
    var reads = 0;
    when(() => svc.fetchReservations())
        .thenAnswer((_) async => reads++ == 0 ? [saved] : [onRouter]);
    refuseSave();

    final c = container();
    await Future.delayed(Duration.zero);
    final n = c.read(uspDhcpReservationsProvider.notifier);
    n.editReservation(saved, saved.copyWith(ip: '10.0.0.5', name: 'tv'));

    await expectLater(
      n.save(),
      throwsA(isA<InvalidInputError>().having(
          (e) => e.field, 'field', DhcpReservationRefusalNames.invalidIp)),
    );

    final s = c.read(uspDhcpReservationsProvider).settings;
    expect(s.original.reservations, [onRouter]);
    expect(s.current.reservations, [onRouter]);
    verify(() => svc.fetchReservations()).called(2);
    c.dispose();
  });

  test('a refused save that wrote nothing keeps the user\'s edit', () async {
    when(() => svc.fetchReservations()).thenAnswer((_) async => [saved]);
    refuseSave();

    final c = container();
    await Future.delayed(Duration.zero);
    final n = c.read(uspDhcpReservationsProvider.notifier);
    final edited = saved.copyWith(ip: '10.0.0.5');
    n.editReservation(saved, edited);

    await expectLater(n.save(), throwsA(isA<InvalidInputError>()));

    expect(c.read(uspDhcpReservationsProvider).settings.current.reservations,
        [edited]);
    c.dispose();
  });

  test('immediateAdd passes the name to the service', () async {
    when(() => svc.fetchReservations()).thenAnswer((_) async => []);
    when(() => svc.immediateAdd(
          mac: any(named: 'mac'),
          ip: any(named: 'ip'),
          enable: any(named: 'enable'),
          name: any(named: 'name'),
        )).thenAnswer((_) async {});

    final c = container();
    await Future.delayed(Duration.zero);
    await c.read(uspDhcpReservationsProvider.notifier).immediateAdd(
        mac: 'AA:BB:CC:DD:EE:99', ip: '192.168.1.99', name: 'printer');

    verify(() => svc.immediateAdd(
          mac: 'AA:BB:CC:DD:EE:99',
          ip: '192.168.1.99',
          enable: true,
          name: 'printer',
        )).called(1);
    c.dispose();
  });
}
