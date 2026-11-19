/// Collects RenderFlex overflows while a tree is pumped (#1802).
///
/// Ported from 2.x's `test/layout_gate/collector.dart`, without the
/// baseline-recording hooks.
library;

import 'package:flutter/foundation.dart';

import 'incident.dart';

/// Runs [body] with an overflow collector installed and returns its result.
///
/// An overflowing Row or Column reports through `FlutterError.onError`, which
/// the test binding turns into a test failure. While [body] runs, overflow
/// reports go into the list passed to [body] instead, and every other error
/// still goes to the original handler, so it still fails the test. The
/// original handler is restored even when [body] throws.
///
/// Load the real fonts first: with the placeholder font, text widths mean
/// nothing.
Future<T> runWithOverflowCollection<T>(
  Future<T> Function(List<OverflowIncident> sink) body,
) async {
  final incidents = <OverflowIncident>[];
  final original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final report = details.exceptionAsString();
    if (isOverflowError(report)) {
      // `toString()` carries the "error-causing widget" block with its
      // creation location; `exceptionAsString()` is the one line.
      incidents.add(OverflowIncident.parse(report, fullLog: details.toString()));
      return;
    }
    original?.call(details);
  };
  try {
    return await body(incidents);
  } finally {
    FlutterError.onError = original;
  }
}
