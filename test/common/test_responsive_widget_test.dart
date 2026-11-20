import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen.dart';
import 'test_responsive_widget.dart';

// The two tests run in this order. A screen size one test sets must not
// reach the next: a layout-gate case left 1280x420 behind, and a later tap
// in the same file landed off the screen (#1802).
void main() {
  Future<Size> screenOf(WidgetTester tester) async {
    late Size size;
    await tester.pumpWidget(Builder(builder: (context) {
      size = MediaQuery.sizeOf(context);
      return const SizedBox();
    }));
    return size;
  }

  testWidgets('setScreenSize sets the screen for its test', (tester) async {
    await tester.setScreenSize(const ScreenSize('300x200', 300, 200, 1));

    expect(await screenOf(tester), const Size(300, 200));
  });

  testWidgets('the next test starts on the default screen', (tester) async {
    expect(await screenOf(tester), const Size(800, 600));
  });
}
