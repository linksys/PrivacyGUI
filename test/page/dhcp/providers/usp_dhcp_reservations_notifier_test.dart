import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

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
    test('build returns initial loading state', () async {
      when(() => mockService.fetchReservations())
          .thenAnswer((_) async => [r1, r2]);
      final container = createContainer();

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.reservations, isEmpty);
      await Future.delayed(Duration.zero);
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
          .thenThrow(const NetworkError(detail: 'timeout'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspDhcpReservationsProvider);
      expect(state.status.error, isA<NetworkError>());
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

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspDhcpReservationsProvider.notifier);
      notifier.addReservation(r2);

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(
          container.read(uspDhcpReservationsProvider).status.isSaving, isFalse);
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

    // -------------------------------------------------------------------------
    // Immediate mutations (Dashboard card / Device Detail)
    // -------------------------------------------------------------------------

    test('immediateToggle calls service and invalidates dhcpDataProvider',
        () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.immediateToggle(any(), any()))
          .thenAnswer((_) async {});

      var dhcpDataInvalidated = false;
      final container = ProviderContainer(
        overrides: [
          uspDhcpServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          dhcpDataProvider.overrideWith(() => _TestDhcpDataNotifier(
                onInvalidate: () => dhcpDataInvalidated = true,
              )),
        ],
      );
      container.listen(uspDhcpReservationsProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      await container
          .read(uspDhcpReservationsProvider.notifier)
          .immediateToggle(r1.instancePath!, false);

      verify(() => mockService.immediateToggle(r1.instancePath!, false))
          .called(1);
      expect(dhcpDataInvalidated, isTrue);
      container.dispose();
    });

    test('immediateAdd calls service and invalidates dhcpDataProvider',
        () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      when(() => mockService.immediateAdd(
            mac: any(named: 'mac'),
            ip: any(named: 'ip'),
            enable: any(named: 'enable'),
          )).thenAnswer((_) async {});

      var dhcpDataInvalidated = false;
      final container = ProviderContainer(
        overrides: [
          uspDhcpServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          dhcpDataProvider.overrideWith(() => _TestDhcpDataNotifier(
                onInvalidate: () => dhcpDataInvalidated = true,
              )),
        ],
      );
      container.listen(uspDhcpReservationsProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      await container
          .read(uspDhcpReservationsProvider.notifier)
          .immediateAdd(mac: 'AA:BB:CC:DD:EE:99', ip: '192.168.1.99');

      verify(() => mockService.immediateAdd(
            mac: 'AA:BB:CC:DD:EE:99',
            ip: '192.168.1.99',
            enable: true,
          )).called(1);
      expect(dhcpDataInvalidated, isTrue);
      container.dispose();
    });

    test('immediateDelete calls service and invalidates dhcpDataProvider',
        () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.immediateDelete(any())).thenAnswer((_) async {});

      var dhcpDataInvalidated = false;
      final container = ProviderContainer(
        overrides: [
          uspDhcpServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          dhcpDataProvider.overrideWith(() => _TestDhcpDataNotifier(
                onInvalidate: () => dhcpDataInvalidated = true,
              )),
        ],
      );
      container.listen(uspDhcpReservationsProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      await container
          .read(uspDhcpReservationsProvider.notifier)
          .immediateDelete(r1.instancePath!);

      verify(() => mockService.immediateDelete(r1.instancePath!)).called(1);
      expect(dhcpDataInvalidated, isTrue);
      container.dispose();
    });

    test('immediateToggle rethrows ServiceError', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.immediateToggle(any(), any()))
          .thenThrow(const NetworkError(detail: 'toggle failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await expectLater(
        container
            .read(uspDhcpReservationsProvider.notifier)
            .immediateToggle(r1.instancePath!, false),
        throwsA(isA<ServiceError>()),
      );
      container.dispose();
    });

    test('immediateAdd rethrows ServiceError', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      when(() => mockService.immediateAdd(
            mac: any(named: 'mac'),
            ip: any(named: 'ip'),
            enable: any(named: 'enable'),
          )).thenThrow(const NetworkError(detail: 'add failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await expectLater(
        container
            .read(uspDhcpReservationsProvider.notifier)
            .immediateAdd(mac: 'AA:BB:CC:DD:EE:99', ip: '192.168.1.99'),
        throwsA(isA<ServiceError>()),
      );
      container.dispose();
    });

    test('immediateDelete rethrows ServiceError', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => [r1]);
      when(() => mockService.immediateDelete(any()))
          .thenThrow(const NetworkError(detail: 'delete failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await expectLater(
        container
            .read(uspDhcpReservationsProvider.notifier)
            .immediateDelete(r1.instancePath!),
        throwsA(isA<ServiceError>()),
      );
      container.dispose();
    });

    // -------------------------------------------------------------------------
    // deviceOptions (autocomplete data source)
    // -------------------------------------------------------------------------

    ProviderContainer createContainerWithDevices(DevicesData devicesData) {
      final container = ProviderContainer(
        overrides: [
          uspDhcpServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          devicesDataProvider
              .overrideWith(() => _TestDevicesDataNotifier(devicesData)),
        ],
      );
      container.listen(uspDhcpReservationsProvider, (_, __) {});
      return container;
    }

    test('deviceOptions maps client devices to pure data', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      final container = createContainerWithDevices(DevicesData(
        deviceModels: [
          _device(
            mac: 'AA:BB:CC:DD:EE:01',
            ip: '192.168.1.10',
            friendlyName: 'Laptop',
            isActive: true,
          ),
        ],
      ));
      // Ensure devicesDataProvider resolves before reading.
      await container.read(devicesDataProvider.future);
      await Future.delayed(Duration.zero);

      final options =
          container.read(uspDhcpReservationsProvider.notifier).deviceOptions();

      expect(options, hasLength(1));
      expect(options[0].name, 'Laptop');
      expect(options[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(options[0].ip, '192.168.1.10');
      expect(options[0].isActive, isTrue);
      container.dispose();
    });

    test('deviceOptions name falls back to hostName then mac', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      final container = createContainerWithDevices(DevicesData(
        deviceModels: [
          _device(mac: 'AA:BB:CC:DD:EE:01', ip: '192.168.1.10', hostName: 'pc'),
          _device(mac: 'AA:BB:CC:DD:EE:02', ip: '192.168.1.11'),
        ],
      ));
      await container.read(devicesDataProvider.future);
      await Future.delayed(Duration.zero);

      final options =
          container.read(uspDhcpReservationsProvider.notifier).deviceOptions();

      expect(options[0].name, 'pc');
      expect(options[1].name, 'AA:BB:CC:DD:EE:02');
      container.dispose();
    });

    test('deviceOptions excludes mesh nodes (master/slave)', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      final container = createContainerWithDevices(DevicesData(
        deviceModels: [
          _device(
              mac: 'AA:BB:CC:DD:EE:01',
              ip: '192.168.1.10',
              deviceRole: 'client'),
          _device(
              mac: 'AA:BB:CC:DD:EE:02',
              ip: '192.168.1.1',
              deviceRole: 'master'),
          _device(
              mac: 'AA:BB:CC:DD:EE:03', ip: '192.168.1.2', deviceRole: 'slave'),
        ],
      ));
      await container.read(devicesDataProvider.future);
      await Future.delayed(Duration.zero);

      final options =
          container.read(uspDhcpReservationsProvider.notifier).deviceOptions();

      expect(options, hasLength(1));
      expect(options[0].mac, 'AA:BB:CC:DD:EE:01');
      container.dispose();
    });

    test('deviceOptions returns empty when no devices', () async {
      when(() => mockService.fetchReservations()).thenAnswer((_) async => []);
      final container = createContainerWithDevices(const DevicesData());
      await container.read(devicesDataProvider.future);
      await Future.delayed(Duration.zero);

      final options =
          container.read(uspDhcpReservationsProvider.notifier).deviceOptions();

      expect(options, isEmpty);
      container.dispose();
    });
  });
}

/// Test notifier that returns a fixed [DevicesData].
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _TestDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data;
}

DeviceUIModel _device({
  required String mac,
  required String ip,
  String hostName = '',
  String? friendlyName,
  bool isActive = true,
  String? deviceRole,
}) {
  return DeviceUIModel(
    mac: mac,
    ip: ip,
    hostName: hostName,
    isActive: isActive,
    isWifi: false,
    friendlyName: friendlyName,
    deviceRole: deviceRole,
  );
}

/// Test notifier that tracks invalidation.
class _TestDhcpDataNotifier extends DhcpDataNotifier {
  final void Function()? onInvalidate;

  _TestDhcpDataNotifier({this.onInvalidate});

  @override
  Future<DhcpData> build() async {
    ref.onDispose(() {
      // onDispose is called when invalidated
      onInvalidate?.call();
    });
    return const DhcpData(clientModels: [], reservationModels: []);
  }
}
