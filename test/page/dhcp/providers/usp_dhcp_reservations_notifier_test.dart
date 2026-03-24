import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';

class MockUspDhcpService extends Mock implements UspDhcpService {}

void main() {
  late MockUspDhcpService mockService;

  final r1 = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    enable: true,
  );
  final r2 = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    enable: false,
  );

  setUpAll(() {
    registerFallbackValue(<DhcpReservationUIModel>[]);
  });

  setUp(() {
    mockService = MockUspDhcpService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspDhcpServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspDhcpReservationsProvider, (_, __) {});
    return container;
  }

  group('UspDhcpReservationsNotifier', () {
    test('build returns initial loading state', () {
      when(() => mockService.fetchReservations())
          .thenAnswer((_) async => [r1, r2]);
      final container = createContainer();

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.reservations, isEmpty);
      container.dispose();
    });

    test('fetch success populates reservations', () async {
      when(() => mockService.fetchReservations())
          .thenAnswer((_) async => [r1, r2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.settings.current.reservations, hasLength(2));
      expect(state.settings.current.reservations[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(state.settings.current.reservations[1].enable, isFalse);
      container.dispose();
    });

    test('fetch error sets error status', () async {
      when(() => mockService.fetchReservations())
          .thenThrow(Exception('timeout'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.status.errorMessage, contains('timeout'));
      expect(state.settings.current.reservations, isEmpty);
      container.dispose();
    });

    test('performSave calls saveBatch with original and current', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 1, updated: 0, deleted: 0));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      // Add a reservation so state is dirty.
      notifier.addReservation(r2);
      await notifier.save();

      verify(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      container.dispose();
    });

    test('addReservation appends to list', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      notifier.addReservation(r2);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.settings.current.reservations, hasLength(2));
      expect(state.settings.current.reservations[1].mac, r2.mac);
      container.dispose();
    });

    test('editReservation replaces by value match', () async {
      when(() => mockService.fetchReservations())
          .thenAnswer((_) async => [r1, r2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      final updated = r1.copyWith(ip: '192.168.1.200');
      notifier.editReservation(r1, updated);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.settings.current.reservations[0].ip, '192.168.1.200');
      expect(state.settings.current.reservations, hasLength(2));
      container.dispose();
    });

    test('toggleReservation flips enable flag', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      notifier.toggleReservation(r1, false);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.settings.current.reservations[0].enable, isFalse);
      container.dispose();
    });

    test('deleteReservation removes from list', () async {
      when(() => mockService.fetchReservations())
          .thenAnswer((_) async => [r1, r2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      notifier.deleteReservation(r1);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.settings.current.reservations, hasLength(1));
      expect(state.settings.current.reservations[0].mac, r2.mac);
      container.dispose();
    });

    test('isDirty after add, clean after revert', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.addReservation(r2);
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      expect(
          container
              .read(uspDhcpReservationsProvider)
              .settings
              .current
              .reservations,
          hasLength(1));
      container.dispose();
    });
  });
}
