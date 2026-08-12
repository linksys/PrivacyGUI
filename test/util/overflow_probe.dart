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

  /// Matches one `"<n> pixels on the <side>"` clause.
  ///
  /// The exponent alternative covers Flutter's own formatting: sub-pixel
  /// overflows go through `toStringAsPrecision(3)`, which yields `1.00e-7` for
  /// very small values. Without it the number parses as `1.00` — 10 million
  /// times too large, though still under any sane tolerance.
  static final _re = RegExp(
    r'([\d.]+(?:e-?\d+)?) pixels on the (\w+)',
    caseSensitive: false,
  );

  /// Marks a message this parser could not read. Deliberately not `0`: every
  /// caller filters incidents by `pixels > tolerance`, so a zero would be
  /// dropped and the unreadable overflow would disappear — the gate would read
  /// clean precisely when it has stopped understanding Flutter's output.
  /// Infinity survives every threshold and fails loudly instead.
  static const double unparseablePixels = double.infinity;

  /// Parses [errorString], reporting the **worst** side it overflowed on.
  ///
  /// One report can name several sides — Flutter emits them in the fixed order
  /// left, top, bottom, right ("0.5 pixels on the bottom and 41 pixels on the
  /// right"), so taking the *first* clause would have reported that row as
  /// +0.5px bottom and a 2px tolerance would then have dropped a 41px right
  /// overflow. [OverflowIncident] carries a single measurement, so it carries
  /// the largest one.
  ///
  /// Falls back to [unparseablePixels] and `side: 'unknown'` if no clause parses,
  /// so a change in Flutter's message shape surfaces as a failure rather than as
  /// silence.
  factory OverflowIncident.parse(String errorString, {String fullLog = ''}) {
    final firstLine = errorString.split('\n').first.trim();
    var worst = -1.0;
    var worstSide = '';
    for (final m in _re.allMatches(errorString)) {
      final pixels = double.tryParse(m.group(1)!);
      if (pixels != null && pixels > worst) {
        worst = pixels;
        worstSide = m.group(2)!.toLowerCase();
      }
    }
    return OverflowIncident(
      pixels: worst < 0 ? unparseablePixels : worst,
      side: worst < 0 ? 'unknown' : worstSide,
      message: firstLine,
      fullLog: fullLog.isNotEmpty ? fullLog : errorString,
    );
  }

  @override
  String toString() => '+${pixels}px $side';
}

/// Whether [exceptionAsString] is Flutter's own overflow report, i.e. the one
/// message [runWithOverflowCollection] is entitled to intercept.
///
/// `debug_overflow_indicator.dart` emits exactly
/// `A <RenderObject> overflowed by <n> pixels on the <side>.`, so both markers
/// must be present. A bare `contains('overflowed')` would also swallow any
/// unrelated `FlutterError` that happens to use the word — a provider throwing
/// "buffer overflowed", a hint sentence quoting the term — and swallowed errors
/// do not fail the test they occurred in. Everything that fails this test is
/// forwarded to the original handler, which is what turns it into a failure.
bool isOverflowError(String exceptionAsString) =>
    exceptionAsString.contains('overflowed by') &&
    exceptionAsString.contains('pixels on the');

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
    if (isOverflowError(asString)) {
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
