import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/invalidation_domain.dart';

void main() {
  group('InvalidationDomain', () {
    test('enum has 13 values', () {
      expect(InvalidationDomain.values.length, 13);
    });

    test('all values have unique names', () {
      final names = InvalidationDomain.values.map((v) => v.name).toSet();
      expect(names.length, 13);
    });

    test('specific values exist', () {
      final values = InvalidationDomain.values;
      expect(values, contains(InvalidationDomain.connectedDevices));
      expect(values, contains(InvalidationDomain.wifiSsids));
      expect(values, contains(InvalidationDomain.wifiRadios));
      expect(values, contains(InvalidationDomain.wifiClients));
      expect(values, contains(InvalidationDomain.wifiAccessPoints));
      expect(values, contains(InvalidationDomain.portForwarding));
      expect(values, contains(InvalidationDomain.dmz));
      expect(values, contains(InvalidationDomain.firewallRules));
      expect(values, contains(InvalidationDomain.dhcpClients));
      expect(values, contains(InvalidationDomain.dhcpReservations));
      expect(values, contains(InvalidationDomain.staticRouting));
      expect(values, contains(InvalidationDomain.ethernetInterfaces));
      expect(values, contains(InvalidationDomain.wanStatus));
    });
  });
}
