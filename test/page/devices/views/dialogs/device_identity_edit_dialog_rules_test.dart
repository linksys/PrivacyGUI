import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/devices/views/dialogs/device_identity_edit_dialog.dart';

// The firmware keeps a user device name to at most 64 bytes and refuses a
// longer one with fault 9007 (devidentd, FWDEV#207), so the dialog stops it
// first (#1691).
void main() {
  group('isDeviceNameTooLong (#1691)', () {
    test('an empty name is allowed: it clears back to the detected name', () {
      expect(isDeviceNameTooLong(''), isFalse);
    });

    test('64 ASCII characters fit, 65 do not', () {
      expect(isDeviceNameTooLong('a' * 64), isFalse);
      expect(isDeviceNameTooLong('a' * 65), isTrue);
    });

    test('the limit is bytes: a CJK character counts three', () {
      // 21 × 3 = 63 bytes, 22 × 3 = 66 bytes.
      expect(isDeviceNameTooLong('客' * 21), isFalse);
      expect(isDeviceNameTooLong('客' * 22), isTrue);
    });
  });
}
