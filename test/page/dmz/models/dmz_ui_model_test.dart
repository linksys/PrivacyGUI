import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';

void main() {
  const byIp = DmzUIModel(
    isEnabled: true,
    destIp: '192.168.1.50',
    sourceType: DmzSourceType.any,
    sourcePrefix: '',
  );

  group('DmzUIModel — the DMZ host type (#1775)', () {
    test('a model given no type is by IP, with no MAC', () {
      expect(byIp.destinationType, DmzDestinationType.ip);
      expect(byIp.destMac, '');
      expect(
          const DmzUIModel.disabled().destinationType, DmzDestinationType.ip);
      expect(const DmzUIModel.disabled().destMac, '');
    });

    test('copyWith switches the type and keeps both addresses', () {
      final byMac = byIp.copyWith(
          destinationType: DmzDestinationType.mac,
          destMac: 'aa:bb:cc:dd:ee:ff');

      expect(byMac.destinationType, DmzDestinationType.mac);
      expect(byMac.destMac, 'aa:bb:cc:dd:ee:ff');
      // Kept, so switching back restores what was typed.
      expect(byMac.destIp, '192.168.1.50');
      expect(byMac.copyWith(destinationType: DmzDestinationType.ip).destIp,
          '192.168.1.50');
    });

    test('the type and the MAC count for equality, so a switch is an edit', () {
      expect(
          byIp.copyWith(destinationType: DmzDestinationType.mac), isNot(byIp));
      expect(byIp.copyWith(destMac: 'aa:bb:cc:dd:ee:ff'), isNot(byIp));
      expect(byIp.copyWith(), byIp);
    });

    test('both are in the diagnostic props', () {
      expect(byIp.namedProps['destinationType'], 'ip');
      expect(byIp.namedProps['destMac'], '');
    });
  });
}
