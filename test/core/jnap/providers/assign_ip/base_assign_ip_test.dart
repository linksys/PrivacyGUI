// Outside a browser (the mobile build, and these tests) there is no page to
// move to a new address, so each of these refuses instead of doing nothing.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/assign_ip/base_assign_ip.dart';

void main() {
  test('cannot send the browser to the router\'s new address', () {
    expect(() => assignWebLocation('https://192.168.2.1/'),
        throwsUnsupportedError);
  });

  test('cannot change the browser\'s host', () {
    expect(() => updateWebHost('192.168.2.1'), throwsUnsupportedError);
  });

  test('cannot reload the page', () {
    expect(reload, throwsUnsupportedError);
  });
}
