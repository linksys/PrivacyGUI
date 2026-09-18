import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:test/test.dart';

/// A plain value holder, so this pins only the two things a caller gets wrong by
/// omission: what the optional fields default to, and what counts as a change.
void main() {
  group('InstantPrivacyDeviceUIModel', () {
    test('defaults to a public MAC and no address', () {
      const model = InstantPrivacyDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'iPhone',
      );

      expect(model.isPrivateMac, isFalse);
      // Empty rather than null: the add-device suggestion suppresses its trailing
      // slot on an empty address, and every fixture written before the field
      // existed leans on this default.
      expect(model.ipAddress, isEmpty);
    });

    test('two devices differing only in IP are unequal', () {
      // Equality is what decides whether the page rebuilds, and the address is
      // rendered — as the add-device suggestion's subtitle — so a renewed DHCP
      // lease has to count as a change.
      const a = InstantPrivacyDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'iPhone',
        ipAddress: '192.168.1.101',
      );
      const b = InstantPrivacyDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'iPhone',
        ipAddress: '192.168.1.137',
      );

      expect(a, isNot(equals(b)));
    });

    test('devices with the same values are equal', () {
      const a = InstantPrivacyDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'iPhone',
        isPrivateMac: true,
        ipAddress: '192.168.1.101',
      );
      const b = InstantPrivacyDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'iPhone',
        isPrivateMac: true,
        ipAddress: '192.168.1.101',
      );

      expect(a, equals(b));
    });
  });
}
