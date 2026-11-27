import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/views/instant_admin_view.dart';

void main() {
  group('regionIdentifierKey', () {
    // The enum's code, never the translated country name the list shows.
    test('is the region\'s code', () {
      expect(regionIdentifierKey(PowerTableCountries.twn), 'twn');
      expect(regionIdentifierKey(PowerTableCountries.eee), 'eee');
    });

    test('is kebab case and tells every region apart', () {
      final keys = PowerTableCountries.values.map(regionIdentifierKey).toList();

      expect(keys, everyElement(matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$'))));
      expect(keys.toSet(), hasLength(keys.length));
    });
  });
}
