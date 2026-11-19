import 'package:flutter_test/flutter_test.dart';

import 'theme_data.dart';

void main() {
  // loadTestFonts loads once per process (#1802). A later test must still get
  // past it: a Future kept from the first test's fake-async zone never resumes
  // in another test, which hung every screenshot suite at its second test.
  testWidgets('the first test loads the fonts', (tester) async {
    await loadTestFonts();

    expect(fontLoadCount, 1);
  });

  testWidgets(
    'a later test is not held up by the first one, and loads nothing again',
    (tester) async {
      await loadTestFonts();

      // Loading again on every test is the leak that killed a 2,300-test run.
      expect(fontLoadCount, 1);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
