// The language list the language picker and the app's start-up locale read.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/languages.dart';

void main() {
  test('finds a language by its tag', () {
    expect(getLanguageData('fr-CA'),
        {'value': 'fr-CA', 'name': 'Français - Canada'});
    expect(getLanguageData('ar'),
        {'value': 'ar', 'dir': 'rtl', 'name': 'العربية'});
  });

  // app.dart starts in the system language, or in this one when the app has
  // no strings for it.
  test('falls back to US English for a language it does not have', () {
    expect(getLanguageData('xx'),
        {'value': 'en', 'default': true, 'name': 'English - United States'});
  });
}
