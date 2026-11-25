// The fallback of the conditional import in linksys_http_client.dart, for a
// platform with neither dart:io nor dart:html. Every real build picks the io
// or the browser client instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/http/client/get_client.dart';

void main() {
  test('a platform without io or html has no network client', () {
    expect(getClient, throwsUnsupportedError);
  });
}
