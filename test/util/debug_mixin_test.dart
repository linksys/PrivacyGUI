// DebugObserver: six quick taps on the top bar or the app's corner open the
// log export (top_bar.dart, app.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/debug_mixin.dart';

class _Corner with DebugObserver {}

void main() {
  const quick = Duration(milliseconds: 900);

  testWidgets('the sixth quick tap opens it, and only the sixth',
      (tester) async {
    final corner = _Corner();
    final opened = <bool>[];

    for (var tap = 0; tap < 7; tap++) {
      opened.add(corner.increase());
      await tester.pump(quick);
    }

    expect(opened, [false, false, false, false, false, true, false]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a pause of a second starts the count again', (tester) async {
    final corner = _Corner();

    for (var tap = 0; tap < 5; tap++) {
      corner.increase();
      await tester.pump(quick);
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(corner.increase(), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });
}
