/// The one place the layout gate sets and resets the test viewport (#1340).
///
/// ## Why this file exists
///
/// Every sweep in the #1183 gate family pumps a tree at a chosen width, and
/// doing that under `flutter test` takes three properties, not one. Before this
/// file those three lines were hand-copied **seven times** in
/// `test/page/shell/page_chrome_overflow_test.dart`, **twice** in
/// `test/util/dashboard/dashboard_card_probe.dart`, and once more inside
/// `collectOverflow`, which both frameworks call — ten copies of the same dance.
///
/// Only the chrome half ever undid it, through a private `_resetSurfaceAfter`
/// teardown. The card path reset nothing, so a width set by one test was still
/// installed when the next one pumped, and **a test that measures the wrong
/// viewport does not say so**: it reports a clean layout at a width nobody chose.
/// That is the failure this file exists to make impossible, and it is Invariant 2
/// of `doc/testing/overflow_gate_architecture.md` §3.4 — "the surface is set and
/// reset in one place". The reset half is why it is an invariant rather than a
/// convenience.
///
/// ## Why three properties and not one
///
/// Measured against Flutter 3.44, in `flutter_test/lib/src/binding.dart` and
/// `window.dart`:
///
/// * **`tester.binding.setSurfaceSize(size)`** is what the widget tree is laid
///   out in. `createViewConfigurationFor` (`binding.dart:1468`) turns a non-null
///   surface size into the root render view's `logicalConstraints`, which is what
///   `MediaQuery.sizeOf` reports and what every breakpoint in the app branches
///   on. Nothing in the SDK resets it between tests — its own doc comment
///   (`binding.dart:1423`) tells the caller to `addTearDown` the reset by hand,
///   which is the whole reason this file registers one.
/// * **`tester.view.physicalSize`** is the `FlutterView`'s own size, seen by
///   anything reading `View.of(context)` rather than `MediaQuery`. It is not
///   reset between tests either: `TestFlutterView` does have a `reset()`, and no
///   binding hook calls it — `TestWidgetsFlutterBinding.reset()` resets the
///   restoration manager, the gesture binding and the text input, and nothing
///   about the view.
/// * **`tester.view.devicePixelRatio = 1.0`** makes logical and physical pixels
///   the same number. The default under `flutter test` is not 1.0, and
///   `createViewConfigurationFor` derives `physicalConstraints` as
///   `logicalConstraints * devicePixelRatio` — so leaving it alone means the
///   physical box is a multiple of the logical one, while the widths the sweeps
///   enumerate and the `kOverflowTolerancePx` they filter on are both logical.
///
/// Setting only the first would satisfy the sweeps' own assertions today. All
/// three are set because the suites do not agree on which one they read, and
/// because all three are what the ten copies did: a primitive that quietly
/// narrowed the surface is exactly the "faster, quieter, blinder gate" the epic
/// exists to prevent (architecture doc §9.3).
///
/// ## Files do not move
///
/// `test/util/overflow_probe.dart` re-exports this library, so its ~22 importers
/// are untouched and `setLayoutSurface` is reachable from the path every suite
/// already imports (architecture doc §3.1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets the test viewport to [size] and guarantees it is put back afterwards.
///
/// Named for the call site rather than for the mechanism: at all ten call sites
/// `await setLayoutSurface(tester, Size(width, sweepHeight));` reads as the one
/// thing the sweep means, where the three lines it replaces read as three
/// unrelated pokes at the binding. "Layout surface" rather than "viewport"
/// because it is the surface the layout gate measures in, and because
/// `tester.view` is already called a view.
///
/// The restore is not a separate call the caller can forget. There is no
/// `restoreSurfaceAfterTest` companion, deliberately: every one of the nine
/// chrome tests that used to call `_resetSurfaceAfter` also sets a surface, so a
/// standalone reset would have had no caller, and an uncalled primitive is a
/// second way to do this — which is what Invariant 2 forbids.
///
/// Awaited because `setSurfaceSize` flushes microtasks and fires
/// `handleMetricsChanged`; the tree is only laid out at [size] once it returns.
Future<void> setLayoutSurface(WidgetTester tester, Size size) async {
  _restoreSurfaceAfterTest(tester);
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

/// The tester whose test already has a pending restore, or null when none has.
///
/// See [_restoreSurfaceAfterTest] for why this cannot leak between tests.
WidgetTester? _restoreRegisteredFor;

/// Registers the restore once per test, however many times [setLayoutSurface] is
/// called.
///
/// ## Why the deduplication is needed at all
///
/// The sweeps set the surface many times inside **one** `testWidgets`: the chrome
/// header sweep pumps 3 modes × 26 locales per width in a single test, so a naive
/// `addTearDown` per call would pile up 78 async teardowns, each awaited
/// separately by `Invoker.runTearDowns`, to do work that is idempotent after the
/// first. That is 77 needless awaits per test across the whole family, and it
/// makes the teardown list say something false about how many things this file
/// owns.
///
/// ## Why it cannot leak into the next test
///
/// Two independent reasons, because a stale skip here would silently reintroduce
/// exactly the leak this file exists to prevent:
///
/// 1. **The teardown clears the marker itself.** It is the last thing to touch
///    it, and it runs before the next test body starts, so the next test's first
///    `setLayoutSurface` always finds it null.
/// 2. **The marker is the owning tester, not a bool.** `testWidgets` builds one
///    `WidgetTester` per declaration (`widget_tester.dart:164`), so a different
///    test is a different instance and re-registers even if reason 1 somehow did
///    not hold — a teardown that never ran because the process was torn down
///    mid-test, say. Compared with [identical] so a `==` override could not make
///    two testers look like one.
///
/// The pair is what makes "registers once" safe to assert on: within a test the
/// second call is a no-op, and across tests the first call always registers.
void _restoreSurfaceAfterTest(WidgetTester tester) {
  if (identical(_restoreRegisteredFor, tester)) return;
  _restoreRegisteredFor = tester;
  addTearDown(() async {
    _restoreRegisteredFor = null;
    // Same order the three separate teardowns this replaced ran in. They were
    // registered as setSurfaceSize / physicalSize / devicePixelRatio and
    // teardowns run last-registered-first, so the ratio went back first and the
    // surface size last. The end state does not depend on the order — each of
    // the three fires its own metrics-changed — but preserving it keeps this a
    // pure relocation of `page_chrome_overflow_test.dart`'s `_resetSurfaceAfter`
    // rather than a rewrite of it.
    //
    // One thing did move: *when* the restore is registered. `_resetSurfaceAfter`
    // was called at the top of the test body; this registers on the first
    // `setLayoutSurface`, which in the ported suites is a line or two later.
    // Nothing observes the difference today — none of the adopting suites
    // register another `addTearDown`, and the chrome baseline is measured inside
    // the test body, so no teardown order can move a cell. A suite that does
    // register one, and cares whether it runs inside or outside the restored
    // viewport, is the case to check by hand rather than to assume.
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
    await tester.binding.setSurfaceSize(null);
  });
}
