// The Map and String helpers in core/utils/extension.dart that the app calls:
// icon lookup by path, display capitalization, semantics identifiers, the
// client's JSON check and firmware version comparison.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/extension.dart';

void main() {
  group('getValueByPath', () {
    // icon_rules.dart reads a device's model number this way.
    const device = {
      'model': {'modelNumber': 'MX4200', 'deviceType': 'Infrastructure'},
      'friendlyName': 'Linksys00042',
    };

    test('reads a nested value by its dotted path', () {
      expect(device.getValueByPath<String>('model.modelNumber'), 'MX4200');
    });

    test('reads a top-level value by its key', () {
      expect(device.getValueByPath<String>('friendlyName'), 'Linksys00042');
    });

    test('is null for a key the map does not have', () {
      expect(device.getValueByPath<String?>('model.hardwareVersion'), isNull);
    });
  });

  group('capitalize', () {
    test('upper-cases the first letter only', () {
      expect('mx4200'.capitalize(), 'Mx4200');
      expect('dHCP'.capitalize(), 'DHCP');
    });

    test('leaves an empty string alone', () {
      expect(''.capitalize(), '');
    });
  });

  test('capitalizeWords upper-cases the first letter of every word', () {
    expect('local network settings'.capitalizeWords(),
        'Local Network Settings');
  });

  group('kebab', () {
    // The menus build their semantics identifiers with it, which UI
    // automation finds pages by, so an identifier stays as it is.
    test('turns a title into lower-case words joined by hyphens', () {
      expect('InstantAdmin'.kebab(), 'instant-admin');
      expect('Instant Admin'.kebab(), 'instant-admin');
    });

    test('keeps a hyphen in the title, next to the one it adds', () {
      expect('Wi-Fi Settings'.kebab(), 'wi--fi-settings');
    });
  });

  group('isJsonFormat', () {
    test('accepts a JSON body', () {
      expect('{"errors":[{"error":{"code":"X"}}]}'.isJsonFormat(), isTrue);
      expect('[]'.isJsonFormat(), isTrue);
    });

    test('rejects HTML and an empty body', () {
      expect('<html>Bad Gateway</html>'.isJsonFormat(), isFalse);
      expect(''.isJsonFormat(), isFalse);
    });
  });

  group('compareToVersion', () {
    test('compares each part as a number, not as text', () {
      expect('1.2.10'.compareToVersion('1.2.9'), greaterThan(0));
      expect('1.0.4.216421'.compareToVersion('1.0.10.1'), lessThan(0));
      expect('2.0'.compareToVersion('10.0'), lessThan(0));
    });

    test('finds equal versions equal', () {
      expect('1.2.5.26111117'.compareToVersion('1.2.5.26111117'), 0);
    });
  });
}
