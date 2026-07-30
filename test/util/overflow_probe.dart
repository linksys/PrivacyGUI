import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A single RenderFlex overflow captured during a pump.
///
/// Parsed from Flutter's overflow error string, e.g.
/// "A RenderFlex overflowed by 41 pixels on the right."
class OverflowIncident {
  /// How many logical pixels the child exceeded its parent by.
  final double pixels;

  /// Direction of the overflow: 'right', 'bottom', 'left', 'top', or 'unknown'.
  final String side;

  /// The raw Flutter error string (first line), kept for diagnostics.
  final String message;

  /// Full Flutter details string (includes line numbers, stack, and cause).
  final String fullLog;

  const OverflowIncident({
    required this.pixels,
    required this.side,
    required this.message,
    this.fullLog = '',
  });

  static final _re = RegExp(
    r'overflowed by ([\d.]+) pixels on the (\w+)',
    caseSensitive: false,
  );

  /// Parses [errorString]; falls back to `pixels: 0, side: 'unknown'` if the
  /// message shape ever changes so we still record that *something* overflowed.
  factory OverflowIncident.parse(String errorString, {String fullLog = ''}) {
    final firstLine = errorString.split('\n').first.trim();
    final m = _re.firstMatch(errorString);
    return OverflowIncident(
      pixels: m == null ? 0 : double.tryParse(m.group(1)!) ?? 0,
      side: m == null ? 'unknown' : m.group(2)!.toLowerCase(),
      message: firstLine,
      fullLog: fullLog.isNotEmpty ? fullLog : errorString,
    );
  }

  @override
  String toString() => '+${pixels}px $side';
}

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
/// Requires real fonts to be loaded first (see `loadAppFonts()`), otherwise the
/// Ahem placeholder font makes text-width measurements meaningless.
Future<T> runWithOverflowCollection<T>(
  Future<T> Function(List<OverflowIncident> sink) body,
) async {
  final incidents = <OverflowIncident>[];
  final original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final asString = details.exceptionAsString();
    if (asString.contains('overflowed')) {
      incidents.add(
        OverflowIncident.parse(asString, fullLog: details.toString()),
      );
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

/// Convenience wrapper: pumps [widget] once at [surfaceSize] and returns every
/// RenderFlex overflow that occurred — an empty list means it laid out cleanly.
///
/// For multi-pump scenarios (tab sweeps, interactions) use
/// [runWithOverflowCollection] directly so the handler spans every pump.
Future<List<OverflowIncident>> collectOverflow(
  WidgetTester tester,
  Widget widget, {
  required Size surfaceSize,
}) {
  return runWithOverflowCollection((sink) async {
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
