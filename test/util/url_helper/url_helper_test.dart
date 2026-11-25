// The fallback of the conditional import in the pages that open a link, for a
// platform with neither dart:io nor dart:html. Every real build picks
// url_helper_mobile.dart or url_helper_web.dart instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';

void main() {
  test('a platform without io or html cannot open a link', () {
    expect(() => openUrl('https://www.fast.com'), throwsUnimplementedError);
  });
}
