/// Settling a page that never stops animating.
///
/// Lives here rather than in `test/layout_gate/` because both lanes need it: the
/// gate pumps pages to measure them, and unit-lane widget tests pump the same
/// pages to assert behaviour. It used to be a `test/layout_gate/collector.dart`
/// internal, and a unit test reaching across for it is how a lane split moves a
/// path out from under a file that still compiles against it (#1395).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Settles pending frames without failing on infinite/looping animations
/// (spinners, chart tweens). Mirrors the golden runner's `settleWithTimeout`.
Future<void> settleIgnoringAnimations(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );
  } on FlutterError {
    // Timed out on an infinite animation — pump one last frame and move on.
    await tester.pump();
  }
}
