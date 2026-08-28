/// The one place the layout gate collects RenderFlex overflow and settles a tree
/// (#1340).
///
/// ## Why this file exists
///
/// These three helpers were the *only* thing the card sweep and the chrome sweep
/// ever shared (`test/util/overflow_probe.dart`, listed as "the only sharing" in
/// `doc/testing/overflow_gate_architecture.md` §1.1). They are moved here, beside
/// the parser #1338 extracted, so the framework layer holds one collector rather
/// than a collector that happens to live under `test/util/` because that is where
/// #1270 first put it. Nothing about their behaviour changed in the move — except
/// that [collectOverflow] now sets the surface through
/// [setLayoutSurface], which is how the card path gains the teardown reset it has
/// never had (Invariant 2, architecture doc §3.4).
///
/// ## Files do not move
///
/// `test/util/overflow_probe.dart` re-exports this library, so its ~22 importers
/// are untouched (architecture doc §3.1). That re-export is also why this file
/// may import `../util/overflow_baseline.dart` without a cycle problem: the two
/// libraries already referred to each other before the move, and Dart resolves
/// import cycles fine — what it will not tolerate is a duplicate *definition*,
/// which is why [OverflowCell] stays in the baseline library rather than being
/// copied here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/overflow_baseline.dart';
import '../util/settle.dart';

/// Re-exported, not defined here: the unit lane pumps these pages too, and a
/// behaviour test importing a gate internal is a path that breaks the moment the
/// gate is re-shaped (#1395). Gate callers still get it from this library.
export '../util/settle.dart' show settleIgnoringAnimations;
import 'incident.dart';
import 'surface.dart';

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
///
/// The surface goes through [setLayoutSurface] rather than through three inline
/// lines, which is the one behavioural change #1340 makes to this function: every
/// caller now gets the viewport put back at the end of its test. The chrome sweep
/// already arranged that for itself and is unaffected; the card sweep never did,
/// and a width leaking out of `probeCardOverflow` into a neighbouring test is a
/// measurement at a viewport nobody chose (architecture doc §3.4, Invariant 2).
Future<List<OverflowIncident>> collectOverflow(
  WidgetTester tester,
  Widget widget, {
  required Size surfaceSize,
  OverflowCell? cell,
}) {
  return runWithOverflowCollection(cell: cell, (sink) async {
    await setLayoutSurface(tester, surfaceSize);
    await tester.pumpWidget(widget);
    await settleIgnoringAnimations(tester);
    return sink;
  });
}
