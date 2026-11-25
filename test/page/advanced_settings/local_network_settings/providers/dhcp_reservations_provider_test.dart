import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';

const _nas = DHCPReservation(
  macAddress: 'AA:BB:CC:DD:EE:01',
  ipAddress: '192.168.1.120',
  description: 'NAS',
);

const _tv = DHCPReservation(
  macAddress: 'AA:BB:CC:DD:EE:02',
  ipAddress: '192.168.1.121',
  description: 'TV',
);

const _laptop = DeviceListItem(
  name: "Bob's Laptop",
  macAddress: 'AA:BB:CC:DD:EE:03',
  ipv4Address: '192.168.1.130',
);

void main() {
  late ProviderContainer container;
  late DHCPReservationsNotifier notifier;

  DHCPReservationState page() => container.read(dhcpReservationProvider);

  setUp(() {
    container = ProviderContainer();
    // The provider disposes itself once nothing listens, as the page's watch
    // does.
    container.listen(dhcpReservationProvider, (_, __) {});
    notifier = container.read(dhcpReservationProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('starts with nothing listed', () {
    expect(
        page(),
        const DHCPReservationState(
            reservations: [], additionalReservations: [], devices: []));
  });

  group('setReservations', () {
    test('lists each reservation the router holds as reserved', () {
      final shown = notifier.setReservations(const [_nas, _tv]);

      expect(shown, page());
      expect(page().reservations, const [
        ReservedListItem(reserved: true, data: _nas),
        ReservedListItem(reserved: true, data: _tv),
      ]);
    });

    test('keeps a reservation the user unchecked unchecked when re-listed', () {
      notifier
        ..setReservations(const [_nas, _tv])
        ..updateReservations(const ReservedListItem(reserved: true, data: _tv));

      notifier.setReservations(const [_nas, _tv]);

      expect(page().reservations.map((item) => item.reserved), [true, false]);
    });
  });

  group('updateDevices', () {
    test('offers each device by its MAC, address and name, unreserved', () {
      notifier.updateDevices(const [_laptop]);

      expect(page().devices, const [
        ReservedListItem(
          reserved: false,
          data: DHCPReservation(
            macAddress: 'AA:BB:CC:DD:EE:03',
            ipAddress: '192.168.1.130',
            description: "Bob's Laptop",
          ),
        ),
      ]);
      expect(page().additionalReservations, isEmpty);
    });

    test('offers nothing when no list is given', () {
      notifier
        ..updateDevices(const [_laptop])
        ..updateDevices();

      expect(page().devices, isEmpty);
    });
  });

  group('isConflict', () {
    setUp(() => notifier.setReservations(const [_nas]));

    test('flags a device whose MAC or address is reserved already', () {
      expect(
          notifier.isConflict(ReservedListItem(
              reserved: false,
              data: _tv.copyWith(macAddress: _nas.macAddress))),
          isTrue);
      expect(
          notifier.isConflict(ReservedListItem(
              reserved: false, data: _tv.copyWith(ipAddress: _nas.ipAddress))),
          isTrue);
    });

    test('lets a device with its own MAC and address through', () {
      expect(
          notifier
              .isConflict(const ReservedListItem(reserved: false, data: _tv)),
          isFalse);
    });

    test('does not count a reservation the user unchecked', () {
      notifier.updateReservations(
          const ReservedListItem(reserved: true, data: _nas));

      expect(
          notifier.isConflict(ReservedListItem(
              reserved: false,
              data: _tv.copyWith(macAddress: _nas.macAddress))),
          isFalse);
    });
  });

  group('updateReservationItem', () {
    setUp(() => notifier.setReservations(const [_nas, _tv]));

    test('edits a reservation in place', () {
      notifier.updateReservationItem(
        const ReservedListItem(reserved: true, data: _tv),
        'Den TV',
        '192.168.1.122',
        'AA:BB:CC:DD:EE:22',
      );

      expect(
          page().reservations.last,
          const ReservedListItem(
            reserved: true,
            data: DHCPReservation(
              macAddress: 'AA:BB:CC:DD:EE:22',
              ipAddress: '192.168.1.122',
              description: 'Den TV',
            ),
          ));
      expect(page().reservations.first.data, _nas);
    });

    test('keeps what the edit leaves out', () {
      notifier.updateReservationItem(
          const ReservedListItem(reserved: true, data: _tv),
          'Den TV',
          null,
          null);

      expect(
          page().reservations.last.data, _tv.copyWith(description: 'Den TV'));
    });

    test('ignores an item that is not listed', () {
      final before = page();

      notifier.updateReservationItem(
          const ReservedListItem(
              reserved: true,
              data: DHCPReservation(
                macAddress: 'AA:BB:CC:DD:EE:99',
                ipAddress: '192.168.1.199',
                description: 'Gone',
              )),
          'X',
          null,
          null);

      expect(page(), before);
    });
  });

  group('updateReservations', () {
    setUp(() => notifier.setReservations(const [_nas]));

    test('unchecks a listed reservation, and checks it again', () {
      notifier.updateReservations(
          const ReservedListItem(reserved: true, data: _nas));
      expect(page().reservations.single.reserved, isFalse);

      notifier.updateReservations(
          const ReservedListItem(reserved: false, data: _nas));
      expect(page().reservations.single.reserved, isTrue);
    });

    test('drops a listed reservation whose device is on the device list', () {
      notifier.updateDevices(const [
        DeviceListItem(
            name: 'NAS',
            macAddress: 'AA:BB:CC:DD:EE:01',
            ipv4Address: '192.168.1.120'),
      ]);

      notifier.updateReservations(
          const ReservedListItem(reserved: true, data: _nas));

      expect(page().reservations, isEmpty);
    });

    test('reserves a device from the device list, named for a host name', () {
      notifier.updateDevices(const [_laptop]);

      notifier.updateReservations(page().devices.single);

      expect(
          page().reservations.last,
          const ReservedListItem(
            reserved: true,
            data: DHCPReservation(
              macAddress: 'AA:BB:CC:DD:EE:03',
              ipAddress: '192.168.1.130',
              // A host name holds letters, digits and hyphens only.
              description: 'BobsLaptop',
            ),
          ));
    });

    test('reserves a device added by hand as new, whatever its check says', () {
      notifier.updateDevices(const [_laptop]);
      // Checked already: without isNew the add would flip it to unreserved.
      final added = page().devices.single.copyWith(reserved: true);

      notifier.updateReservations(added, true);

      expect(page().reservations, hasLength(2));
      expect(page().reservations.last.data.macAddress, 'AA:BB:CC:DD:EE:03');
      expect(page().reservations.last.reserved, isTrue);
    });

    test('adds a reservation the user typed in', () {
      notifier.updateReservations(
          const ReservedListItem(reserved: true, data: _tv), true);

      expect(page().reservations, const [
        ReservedListItem(reserved: true, data: _nas),
        ReservedListItem(reserved: true, data: _tv),
      ]);
    });
  });
}
