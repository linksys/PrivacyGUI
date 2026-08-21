import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../layout_gate/incident.dart';
import 'overflow_baseline.dart';

/// The parser, the tolerance and the predicate moved to `test/layout_gate/`
/// (#1338) and are re-exported from here so this file's 20 importers are
/// untouched — [OverflowIncident], [kOverflowTolerancePx] and [isOverflowError]
/// all still resolve through `import '.../overflow_probe.dart'`.
///
/// Relocating a test utility with that many callers would mean touching ~70
/// files for no behavioural gain, so the new framework layer is additive and the
/// old paths re-export from it (`doc/testing/overflow_gate_architecture.md`
/// §3.1). The collection helpers below stay here until #1340 moves them to
/// `test/layout_gate/collector.dart` behind the same re-export.
export '../layout_gate/incident.dart';

/// Runs [body] with a RenderFlex-overflow collector installed, returning
/// [body]'s result.
///
/// HOW IT WORKS
///   A Row/Column that can't fit its children reports a FlutterError via
///   `FlutterError.onError` (in debug builds; tests are debug). Normally the
///   test binding turns that into a test failure. While [body] runs we install
///   a handler that *collects* overflow errors into the list passed to [body]
///   and forwards everything else to the original handler — so genuine errors
///   still fail the test, while overflow becomes structured data. The original
///   handler is always restored, even if [body] throws.
///
///   [body] receives the live `sink` list, so it may pump the tree multiple
///   times (e.g. sweeping tab indices) and accumulate incidents across all of
///   them under a single installed handler.
///
/// [cell] names the coordinate being measured, for the sweep baselines (#1337).
/// Passing it is what puts this measurement in the dataset the port tickets diff
/// against; leaving it null keeps a pump that is not a sweep coordinate out. See
/// [emitOverflowBaselineRecord].
///
/// Requires real fonts to be loaded first (see `loadAppFonts()`), otherwise the
/// Ahem placeholder font makes text-width measurements meaningless.
Future<T> runWithOverflowCollection<T>(
  Future<T> Function(List<OverflowIncident> sink) body, {
  OverflowCell? cell,
}) async {
  final incidents = <OverflowIncident>[];
  final original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final asString = details.exceptionAsString();
    if (isOverflowError(asString)) {
      // `details.toString()` is what supplies the incident's file:line (#1338),
      // and it already did — no richer string is needed. Measured against
      // Flutter 3.44: `exceptionAsString()` is the one line and nothing else,
      // while `FlutterErrorDetails.toString()` renders
      // `toDiagnosticsNode().toStringDeep(minLevel: info)` and so carries the
      // `The relevant error-causing widget was` block with its
      // `Widget:file:///…:line:col` creation location. It omits only the
      // `creator:` chain, which is below `info` — and which the parser
      // deliberately does not read anyway.
      incidents.add(
        OverflowIncident.parse(asString, fullLog: details.toString()),
      );
      return;
    }
    original?.call(details);
  };
  // Set only on the normal return path, so anything that stops [body] — a failed
  // `pumpWidget`, a timed-out settle, a provider that threw — leaves it false.
  var completed = false;
  try {
    final result = await body(incidents);
    completed = true;
    return result;
  } finally {
    FlutterError.onError = original;
    // Emitted even when [body] threw, but flagged. Dropping the record would make
    // the cell read as lost coverage and send the porter after the wrong thing;
    // emitting it unflagged would be worse, because a tree that never finished
    // building collected no incidents and would render as measured-and-clean.
    emitOverflowBaselineRecord(cell, incidents, threw: !completed);
  }
}

/// Convenience wrapper: pumps [widget] once at [surfaceSize] and returns every
/// RenderFlex overflow that occurred — an empty list means it laid out cleanly.
///
/// For multi-pump scenarios (tab sweeps, interactions) use
/// [runWithOverflowCollection] directly so the handler spans every pump.
///
/// [cell] is forwarded to [runWithOverflowCollection] — see there.
Future<List<OverflowIncident>> collectOverflow(
  WidgetTester tester,
  Widget widget, {
  required Size surfaceSize,
  OverflowCell? cell,
}) {
  return runWithOverflowCollection(cell: cell, (sink) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(widget);
    await settleIgnoringAnimations(tester);
    return sink;
  });
}

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
