import 'dart:io';

/// The one parser of Flutter's RenderFlex overflow report (#1338).
///
/// ## Why this file exists
///
/// The #1183 gate family grew two independent parsers of the same string, and
/// each had what the other lacked: `test/util/overflow_probe.dart` took the
/// **worst** side, applied the shared 2.0px tolerance and failed loudly on a
/// string it could not read; `test/golden_test/golden_framework/overflow_diagnostics.dart`
/// took the first side, applied no tolerance, was failure-tolerant — and was the
/// only one of the two that resolved the incident's **`file:line`**. This file is
/// the merge: the loud-failure behaviour, the worst side, the tolerance, and the
/// source location.
///
/// `file:line` is not decoration. It is the correct ratchet key — a
/// coordinate-keyed allowlist invalidates wholesale whenever a layout is
/// rearranged, whereas a source-location key survives it — and it is the join
/// column that makes golden CI's advisory findings and the local gate's verdicts
/// one comparable dataset, which is what turns the graduation rule from
/// something a person has to watch into something a diff computes. See
/// `doc/testing/overflow_gate_architecture.md` §3.5 and §8.
///
/// ## The duplication below is deliberate
///
/// The path-normalisation logic here is a copy of `overflow_diagnostics.dart`'s,
/// carried verbatim rather than shared, and the names are distinct
/// ([normalizeOverflowSourcePath] versus `normalizeSourcePath`) so that both
/// libraries can be imported into one file while the overlap lasts —
/// `test/util/overflow_baseline.dart` does exactly that today. **#1339 retires
/// the copy in `overflow_diagnostics.dart` and points `golden_runner.dart` here**;
/// this ticket deliberately leaves that file untouched so the swap is one
/// reviewable change with its own verification against CI artifacts. Keeping the
/// logic byte-identical for now is what lets #1339 attribute every remaining
/// difference in `overflow_warnings.json` to first-side → worst-side and to
/// nothing else.
///
/// ## Files do not move
///
/// `test/util/overflow_probe.dart` re-exports everything here, so its 20
/// importers are untouched. Relocating a test utility with that many callers
/// would mean touching ~70 files for no behavioural gain, so the new layer is
/// additive (architecture doc §3.1).

/// The overflow every probe in this suite ignores.
///
/// Small tolerance for sub-pixel shaping differences between the mac (local) and
/// ubuntu (CI) font rasterizers. The project bundles fixed font files so the two
/// load the same glyphs, but borderline cases (~1px) can still flip; anything
/// meaningfully clipped is many pixels over.
///
/// Shared (#1270) because the #1183 gate and its five satellite suites all
/// filtered on a bare `2.0`. A satellite that drifted to a looser value would
/// report a coordinate the gate still fails on — and a tighter one would fail on
/// CI only. [OverflowIncident.unparseablePixels] is deliberately above every
/// tolerance, so raising this can never silence an unreadable report.
const double kOverflowTolerancePx = 2.0;

/// A single RenderFlex overflow captured during a pump.
///
/// Parsed from Flutter's overflow error string, e.g.
/// "A RenderFlex overflowed by 41 pixels on the right.", plus — when the deep
/// diagnostics dump is available — the [widget] that caused it and its
/// [file]/[line] creation location.
class OverflowIncident {
  /// How many logical pixels the child exceeded its parent by.
  final double pixels;

  /// Direction of the overflow: 'right', 'bottom', 'left', 'top', or 'unknown'.
  final String side;

  /// The raw Flutter error string (first line), kept for diagnostics.
  final String message;

  /// Full Flutter details string (includes line numbers, stack, and cause).
  final String fullLog;

  /// Normalised, repo-relative source file of the widget that overflowed.
  ///
  /// Null when [fullLog] carried no resolvable creation location — which is not
  /// an error condition, only a less useful incident. See [site].
  final String? file;

  /// 1-based line in [file] where the overflowing widget was created.
  final int? line;

  /// Name of the widget Flutter blamed, e.g. `Row`.
  ///
  /// Carried rather than dropped for two reasons: it comes free out of the same
  /// match as [file] and [line], and it is already a column in #1337's baseline
  /// dataset (`site`, `widget`), which is fed from this incident. Without it
  /// #1339 could not delete `parseOverflowSource` outright — it would have to
  /// keep the second parser alive for one field.
  final String? widget;

  const OverflowIncident({
    required this.pixels,
    required this.side,
    required this.message,
    this.fullLog = '',
    this.file,
    this.line,
    this.widget,
  });

  /// The join key: `file:line`, or null when the location did not resolve.
  ///
  /// This is what the ratchet keys on and what joins the gate's verdicts to
  /// golden CI's advisory findings (#1341, #1346). A null here is a diagnostic
  /// that cannot participate in that join, never a reason to fail.
  String? get site => file == null ? null : '$file:$line';

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
  ///
  /// [file], [line] and [widget] are read from [fullLog] (or from [errorString]
  /// when no separate log is supplied), because the one-line message carries no
  /// location — only the diagnostics dump does. Verified empirically against
  /// Flutter 3.44: `FlutterErrorDetails.toString()` renders
  /// `toDiagnosticsNode().toStringDeep(minLevel: info)` and so *does* carry the
  /// `The relevant error-causing widget was` block and its
  /// `Widget:file:///…:line:col` creation location, while
  /// `exceptionAsString()` carries the one line and nothing else. The collector
  /// already passes the former as `fullLog`, so no richer string is needed.
  ///
  /// [runDirectory] is the directory the test process runs in, which under
  /// `flutter test` is the app root. Injected so the location parsing stays a
  /// pure function of its inputs and is testable without a real checkout;
  /// defaulted to [Directory.current] because 22 existing call sites must keep
  /// compiling and none of them knows or cares.
  ///
  /// The two extractions are independent, and deliberately so: an unreadable
  /// pixel count still yields a usable location, and an unresolvable location
  /// still yields a usable measurement.
  factory OverflowIncident.parse(
    String errorString, {
    String fullLog = '',
    String? runDirectory,
  }) {
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
    final log = fullLog.isNotEmpty ? fullLog : errorString;
    final location = _parseSourceLocation(log, runDirectory: runDirectory);
    return OverflowIncident(
      pixels: worst < 0 ? unparseablePixels : worst,
      side: worst < 0 ? 'unknown' : worstSide,
      message: firstLine,
      fullLog: log,
      file: location?.file,
      line: location?.line,
      widget: location?.widget,
    );
  }

  @override
  String toString() => '+${pixels}px $side${site == null ? '' : ' at $site'}';
}

/// Whether [exceptionAsString] is Flutter's own overflow report, i.e. the one
/// message `runWithOverflowCollection` is entitled to intercept.
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

/// Rewrites an absolute source path into a stable, machine-independent form.
///
/// The reported path is absolute, so it embeds whichever directory the run
/// happened in. Two shapes need collapsing:
///
/// * Files in this repo — strip [runDirectory]. The checkout is *not* reliably
///   named `PrivacyGUI`: golden-ci clones the app into `app/` under its own
///   workspace, so matching on the directory name would leak the full CI path.
/// * Files in a package — Flutter's inspector treats anything outside
///   `packages/flutter/` as user code, so a widget built inside a git
///   dependency (e.g. `ui_kit_library`) reports a pub-cache path carrying the
///   resolved commit SHA, which differs per machine and per dependency bump.
///   Collapse it to `<package>/<path>`, which also makes it obvious at a glance
///   that the culprit is not in this repo.
///
/// The result is forward-slash and repo-relative, and therefore byte-stable
/// across machines — which is the whole point of a join key. Forward slashes
/// need no conversion: the input came out of a `file://` URI, whose path
/// component is `/`-separated by definition.
///
/// An unrecognized path is returned unchanged — better a long path than none.
///
/// Named apart from `overflow_diagnostics.dart`'s `normalizeSourcePath` on
/// purpose: the two libraries coexist until #1339, and a shared name would make
/// importing both an ambiguity error.
String normalizeOverflowSourcePath(
  String absolutePath, {
  required String runDirectory,
}) {
  // The reported path came out of a `file://` URI, so anything outside the
  // unreserved set arrives percent-encoded: a space in the developer's home
  // directory reaches here as `%20`. Compared raw against the run directory it
  // never matches, and the whole absolute path — account name included — would
  // land in the JSON and the HTML report.
  final path = _decodePathOrSelf(absolutePath);

  final root = runDirectory.endsWith('/') ? runDirectory : '$runDirectory/';
  if (path.startsWith(root)) {
    return path.substring(root.length);
  }

  const cacheMarkers = ['/.pub-cache/git/', '/.pub-cache/hosted/'];
  for (final marker in cacheMarkers) {
    final index = path.indexOf(marker);
    if (index == -1) continue;
    var tail = path.substring(index + marker.length);
    // The hosted layout inserts a registry segment (pub.dev/) before the
    // package directory; the git layout does not.
    if (marker.endsWith('hosted/')) {
      final slash = tail.indexOf('/');
      if (slash == -1) continue;
      tail = tail.substring(slash + 1);
    }
    final slash = tail.indexOf('/');
    if (slash == -1) continue;
    // Drop the version or commit suffix: "privacyGUI-UI-kit-628f62f..." and
    // "some_pkg-1.2.3" both become the bare package name.
    final versioned = tail.substring(0, slash);
    final dash = versioned.lastIndexOf('-');
    final name = dash == -1 ? versioned : versioned.substring(0, dash);
    return '$name/${tail.substring(slash + 1)}';
  }

  return path;
}

/// Percent-decodes [path], falling back to the original on invalid encoding.
///
/// A literal `%` in a directory name is not valid encoding and makes
/// [Uri.decodeFull] throw. This runs inside `FlutterError.onError`, where an
/// escaping throw would turn a diagnostic into a test failure — so an
/// undecodable path is passed through untouched instead.
String _decodePathOrSelf(String path) {
  if (!path.contains('%')) return path;
  try {
    return Uri.decodeFull(path);
  } on ArgumentError {
    return path;
  }
}

/// Matches the creation location Flutter appends after a widget name, e.g.
/// `Row:file:///abs/path/to/lib/page/foo/bar.dart:47:12`.
final RegExp _locationPattern = RegExp(
  r'([A-Za-z_]\w*):file://([^\s:]+):(\d+):(\d+)',
);

/// The heading of the block naming the widget that caused the error.
const String _widgetBlockMarker = 'The relevant error-causing widget was';

/// The widget, file and line resolved out of one diagnostics dump.
class _SourceLocation {
  const _SourceLocation(this.widget, this.file, this.line);

  final String widget;
  final String file;
  final int line;
}

/// Parses the offending widget's name and source location out of a diagnostics
/// dump, or returns null when the dump carries no resolvable location.
///
/// The search is anchored inside the error-causing-widget block: the deep dump
/// (`toDiagnosticsNode().toStringDeep()`, which the golden runner uses) also
/// contains a `creator:` chain whose entries match [_locationPattern], and the
/// two blocks' relative order comes from the order of Flutter's
/// `informationCollector` list — an implementation detail that an SDK upgrade
/// could reorder. `FlutterErrorDetails.toString()`, which the collector passes,
/// filters the creator chain out at `DiagnosticLevel.info`, so the anchor is
/// redundant for that input and load-bearing for the other; it costs one
/// `indexOf`.
///
/// Resolution relies on widget creation tracking, which `flutter test` enables
/// by default.
///
/// Every failure mode here is absence, not an exception. This runs inside
/// `FlutterError.onError`, and a diagnostic that throws turns a measurement into
/// a test failure — the one thing an instrument must never do.
_SourceLocation? _parseSourceLocation(
  String diagnosticsDump, {
  String? runDirectory,
}) {
  try {
    final blockStart = diagnosticsDump.indexOf(_widgetBlockMarker);
    if (blockStart == -1) return null;

    final match = _locationPattern.firstMatch(
      diagnosticsDump.substring(blockStart),
    );
    if (match == null) return null;

    final line = int.tryParse(match.group(3)!);
    if (line == null) return null;

    return _SourceLocation(
      match.group(1)!,
      normalizeOverflowSourcePath(
        match.group(2)!,
        runDirectory: runDirectory ?? Directory.current.path,
      ),
      line,
    );
  } catch (_) {
    // Location unresolved; the measurement the caller actually asserts on stands.
    return null;
  }
}
