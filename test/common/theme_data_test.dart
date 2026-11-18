import 'package:flutter_test/flutter_test.dart';

import 'theme_data.dart';

void main() {
  // loadTestFonts loads once per process (#1802). A later test must still get
  // past it: a Future kept from the first test's fake-async zone never resumes
  // in another test, which hung every screenshot suite at its second test.
  testWidgets('the first test loads the fonts', (tester) async {
    await loadTestFonts();
  });

  testWidgets(
    'a later test is not held up by the first one',
    (tester) async {
      await loadTestFonts();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
