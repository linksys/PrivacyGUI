import 'dart:io';

/// The one parser of Flutter's RenderFlex overflow report — written by #1338,
/// sole since #1339.
///
/// ## Why this file exists
///
/// The #1183 gate family grew two independent parsers of the same string, and
/// each had what the other lacked: `test/util/overflow_probe.dart` took the
/// **worst** side, applied the shared 2.0px tolerance and failed loudly on a
/// string it could not read; `golden_framework/overflow_diagnostics.dart` (deleted
/// by #1339) took the first side, applied no tolerance, was failure-tolerant —
/// and was the only one of the two that resolved the incident's **`file:line`**.
/// This file is the merge: the loud-failure behaviour, the worst side, the
/// tolerance, and the source location.
///
/// `file:line` is not decoration. It is the correct ratchet key — a
/// coordinate-keyed allowlist invalidates wholesale whenever a layout is
/// rearranged, whereas a source-location key survives it — and it is the join
/// column that makes golden CI's advisory findings and the local gate's verdicts
/// one comparable dataset, which is what turns the graduation rule from
/// something a person has to watch into something a diff computes. See
/// `doc/testing/overflow_gate_architecture.md` §3.5 and §8.
///
/// ## One parser, since #1339
///
/// The path normalisation below used to be a verbatim copy of
/// `overflow_diagnostics.dart`'s, carried rather than shared so that both
/// libraries could be imported into one file while the overlap lasted.
/// `test/util/overflow_baseline.dart` was that one file; **#1351 ended the import
/// and #1339 deleted the copy**, so this file is now the repo's only reader of
/// Flutter's overflow report.
///
/// The golden framework builds its advisory record from here too
/// (`golden_framework/overflow_record.dart`), which is why two functions that
/// read like golden-report concerns live below: [normalizeOverflowDumpPaths] and
/// [stripOverflowObjectIds]. They are transforms of the same string, they need
/// the same pattern and the same normalisation rules, and hosting them is what
/// keeps [_locationPattern] private — exporting a regex is how the second parse
/// gets written next time.
///
/// The two parsers disagreed on more than loudness, and #1339 resolved the
/// disagreement rather than averaging it: this one reports the **worst** side,
/// the copy reported the first. [pixelsText] exists because of the other half of
/// that swap — see its doc.
///
/// ## Files do not move
///
/// `test/util/overflow_probe.dart` re-exports everything here, so its 22
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

  /// [pixels] exactly as Flutter spelled it, or null when no clause parsed.
  ///
  /// The same measurement as [pixels] and not a substitute for it: nothing should
  /// compare or threshold on this. It exists for one caller — the golden
  /// framework's advisory record (#1339), whose `pixels` field is a **String**
  /// that reaches a report badge and a site key verbatim
  /// (`test_scripts/overflow_details.dart:61,110`).
  ///
  /// Re-formatting `pixels` there would rewrite user-visible text: Flutter's
  /// `_formatPixels` picks its precision from the *unrounded* value (`>10` →
  /// no decimals, `>1` → one, else three significant digits), so `18` must not
  /// become `18.0` — and no mirror of that function can be round-trip safe,
  /// because `10.04` prints as `10` and re-formats as `10.0`. Carrying the matched
  /// text is the only way the swap changes nothing a person reads; all 16 records
  /// in `test/fixtures/golden_overflow_warnings.json` would otherwise differ.
  ///
  /// Null exactly when [pixels] is [unparseablePixels], so a caller that wants
  /// "the amount, or nothing" can test this one field.
  final String? pixelsText;

  /// The raw Flutter error string (first line), kept for diagnostics.
  final String message;

  /// Full Flutter details string (includes line numbers, stack, and cause).
  final String fullLog;

  /// Normalised, repo-relative source file of the widget that overflowed.
  ///
  /// Null when [fullLog] carried no resolvable creation location — which is not
  /// an error condition, only a less useful incident. See [site].
  ///
  /// "Normalised" is best-effort: a path [normalizeOverflowSourcePath] could not
  /// reduce stays absolute here on purpose, because it is still the only lead a
  /// person reading the failure has. [site] is where that stops being acceptable.
  final String? file;

  /// 1-based line in [file] where the overflowing widget was created.
  final int? line;

  /// Name of the widget Flutter blamed, e.g. `Row`.
  ///
  /// Carried rather than dropped for two reasons: it comes free out of the same
  /// match as [file] and [line], and #1337's baseline dataset has a `widget`
  /// column. That column is filled from here since #1351
  /// (`overflow_baseline.dart:217`), which is what let that ticket drop the
  /// `parseOverflowSource` call outright instead of keeping the second parser
  /// alive for one field.
  final String? widget;

  const OverflowIncident({
    required this.pixels,
    required this.side,
    required this.message,
    this.pixelsText,
    this.fullLog = '',
    this.file,
    this.line,
    this.widget,
  });

  /// The join key: `file:line`, or null when the location did not resolve or did
  /// not reduce to a path every machine spells the same way.
  ///
  /// This is what the ratchet keys on (#1341) and what joins the gate's verdicts
  /// to golden CI's advisory findings (#1346), and it is committed twice over —
  /// as a `known_overflows.json` key and as the `site` column of #1337's
  /// baselines. A null here is a diagnostic that cannot participate in that
  /// join, never a reason to fail.
  ///
  /// Both halves are checked, not just [file]: [parse] only ever sets the two
  /// together, but the const constructor is public, and a file with a null line
  /// is not half a join key — `'lib/x.dart:null'` would be a key that joins to
  /// nothing while reading as resolved.
  ///
  /// The third check is [_isMachineIndependentPath], and it is why this is no
  /// longer a one-line getter — see that function for which paths reach here
  /// absolute and what committing one costs.
  String? get site {
    final path = file;
    if (path == null || line == null) return null;
    if (!_isMachineIndependentPath(path)) return null;
    return '$path:$line';
  }

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
    String? worstText;
    for (final m in _re.allMatches(errorString)) {
      final pixels = double.tryParse(m.group(1)!);
      if (pixels != null && pixels > worst) {
        worst = pixels;
        worstSide = m.group(2)!.toLowerCase();
        // The clause's own digits, not a re-rendering of `pixels` — see
        // [pixelsText]. Captured here because this is the only place that still
        // knows which clause won.
        worstText = m.group(1)!;
      }
    }
    final log = fullLog.isNotEmpty ? fullLog : errorString;
    final location = _parseSourceLocation(log, runDirectory: runDirectory);
    return OverflowIncident(
      pixels: worst < 0 ? unparseablePixels : worst,
      side: worst < 0 ? 'unknown' : worstSide,
      pixelsText: worstText,
      message: firstLine,
      fullLog: log,
      file: location?.file,
      line: location?.line,
      widget: location?.widget,
    );
  }

  /// `+41.0px right at lib/page/foo/bar.dart:47`, or `+41.0px right` when the
  /// location did not resolve.
  ///
  /// Read by people, not by machines, but read in six places: the sweeps' own
  /// failure messages (`dashboard_card_overflow_test.dart:478,721,866,876`) and
  /// the report generator's Markdown detail line and HTML badge
  /// (`dashboard_overflow_report_generator.dart:125,380`). Appending the site is
  /// the one behavioural change #1338 makes to output a person sees, and it is
  /// pinned by test rather than left to the baselines: those serialize `px`,
  /// `side` and the source columns, never this string, so nothing else would
  /// notice it changing.
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
/// That makes the result safe to *print* and not safe to *commit*, so
/// [OverflowIncident.site] withholds the key for anything still absolute; see
/// [_isMachineIndependentPath] for the two shapes that get that far.
///
/// The `Overflow` in the name is a leftover with a use: it was needed while
/// `overflow_diagnostics.dart`'s `normalizeSourcePath` still existed and
/// `test/util/overflow_baseline.dart` imported both (a shared name would have
/// been an ambiguity error). #1339 deleted that copy, and the name stays because
/// this library is imported unprefixed by 20-odd files and `normalizeSourcePath`
/// is too general a name to take from them.
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

/// Rewrites **every** absolute source path inside a diagnostics dump.
///
/// [OverflowIncident.parse] reads one location out of a dump — the culprit's.
/// This rewrites all of them, because a dump kept whole (the golden framework's
/// `log` field, #1197) names a creation location for every widget in the
/// `creator:` chain, each carrying the directory the run happened in. Left
/// as-is, a report built on CI embeds the runner's workspace and two machines
/// produce different text for the same overflow.
///
/// Note what it drops: the whole match is rebuilt as `Widget:path:line:col`, so
/// the `file://` scheme goes with it. That is the pre-#1339 behaviour, kept
/// deliberately — the strings are compared against a stored real report, and the
/// scheme is not information once the path is repo-relative.
///
/// [_toComparablePath] is applied here and was not applied by the golden copy.
/// On POSIX every clause of it is a no-op, so the stored corpus is unaffected;
/// on Windows it is the difference between a collapsed path and a leaked one,
/// and leaving the two functions disagreeing about the same path in the same
/// record was the more expensive choice.
String normalizeOverflowDumpPaths(
  String diagnosticsDump, {
  required String runDirectory,
}) {
  final root = _toComparablePath(runDirectory);
  return diagnosticsDump.replaceAllMapped(
    _locationPattern,
    (match) => '${match.group(1)}:'
        '${normalizeOverflowSourcePath(_toComparablePath(match.group(2)!), runDirectory: root)}'
        ':${match.group(3)}:${match.group(4)}',
  );
}

/// Matches the short hash Flutter appends to a diagnosable object's name, e.g.
/// the `#4195b` in `RenderFlex#4195b` or `GlobalKey#18e2d`.
///
/// Anchored on an identifier character so a `#` in ordinary text — a reservation
/// number in a rendered string, say — is left alone.
final RegExp _objectIdPattern = RegExp(r'(?<=\w)#[0-9a-f]{5}\b');

/// Removes the per-run object ids Flutter embeds in a diagnostics dump.
///
/// The ids are allocation details, reassigned on every run. Left in, the same
/// overflow yields different text each time: the recorded JSON churns, and the
/// reports cannot tell that one culprit explains many goldens — a single card
/// reported in 24 goldens stayed 24 distinct logs. The geometry that actually
/// explains an overflow (`constraints:`, `size:`) is untouched.
String stripOverflowObjectIds(String diagnosticsDump) =>
    diagnosticsDump.replaceAll(_objectIdPattern, '');

/// Whether [file] is a path every machine spells the same way.
///
/// [normalizeOverflowSourcePath] is best-effort by design: it strips the run
/// directory, collapses a pub-cache path, and returns anything else unchanged,
/// because a long absolute path is still a lead for a person reading a failure —
/// "better a long path than none". That trade is right for [file], which is read,
/// and wrong for [OverflowIncident.site], which is *committed*.
///
/// Two shapes reach here uncollapsed, and neither is exotic:
///
/// * a cache relocated with `PUB_CACHE=/opt/pubcache`, which no `/.pub-cache/`
///   marker matches — a CI image's choice, not a developer's;
/// * a dependency mounted from outside the checkout by `path:` or
///   `pubspec_overrides.yaml`, which anyone debugging `ui_kit_library` against a
///   local clone has.
///
/// Both carry someone's home directory or a runner's workspace. As a key that is
/// two failures at once: `tool/overflow_baseline.sh capture` emits different
/// bytes on two machines for the same layout, so `check` reports a diff nobody
/// changed anything to cause (`test/util/overflow_baseline.dart:96`), and an
/// entry written under such a key exempts that overflow on exactly one machine.
///
/// Withholding the key rather than the incident is the whole point: the
/// measurement, the widget and [file] all survive into the failure message, and
/// a null site is a case the ratchet already handles as "cannot be exempted,
/// must be fixed" (`ratchet.dart`'s library comment). What is lost is the
/// ability to grandfather an overflow found under a relocated cache — which was
/// never really there, since the entry could not have worked for a second
/// machine.
bool _isMachineIndependentPath(String file) =>
    !file.startsWith('/') && !_driveLetterPattern.hasMatch(file);

/// Matches a Windows drive at the start of a path (`C:/src/…`), with the leading
/// slash a `file://` URI puts in front of it (`/C:/src/…`) optional.
final RegExp _driveLetterPattern = RegExp(r'^/?([A-Za-z]):');

/// Rewrites a path into the single spelling both sides of the run-directory
/// comparison can be made in: forward slashes, no leading slash before a drive
/// letter, drive letter upper-cased.
///
/// Only Windows needs it, and it needs all three clauses: Flutter reports
/// `file:///c:/src/app/lib/x.dart` while `Directory.current.path` is
/// `C:\src\app`, so the prefix test in [normalizeOverflowSourcePath] fails on the
/// separator, on the leading slash and on the drive case independently. On POSIX
/// every clause is a no-op.
///
/// It stays out of [normalizeOverflowSourcePath] for a reason that outlived its
/// original one. It began as a separate step because that function was a verbatim
/// copy of the golden parser's and had to stay byte-identical to it; #1339 deleted
/// the copy, and it is still separate because the two callers need different
/// amounts of it — [_parseSourceLocation] converts both sides of the comparison,
/// [normalizeOverflowDumpPaths] converts the run directory once and each of many
/// paths as it goes. Folding it in would convert the run directory per match.
String _toComparablePath(String path) {
  final slashed = path.replaceAll(r'\', '/');
  final drive = _driveLetterPattern.firstMatch(slashed);
  if (drive == null) return slashed;
  return '${drive.group(1)!.toUpperCase()}:${slashed.substring(drive.end)}';
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
///
/// The path group allows one `X:` drive prefix and excludes `:` everywhere else,
/// so the trailing `:line:col` stays unambiguous. The drive alternative is what
/// makes this match on Windows at all: in `file:///C:/src/app/lib/x.dart:47:12`
/// a bare `[^\s:]+` stops at the drive colon and the character after it is not a
/// digit, so the whole pattern fails and every incident comes back with no
/// location. Under a site key that is not a cosmetic loss — `isAllowlisted(null,
/// tag)` is hard-coded false (`ratchet.dart:272`), so on that machine every
/// grandfathered overflow blocks and no fixture can say otherwise.
final RegExp _locationPattern = RegExp(
  r'([A-Za-z_]\w*):file://(/(?:[A-Za-z]:)?[^\s:]+):(\d+):(\d+)',
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
        _toComparablePath(match.group(2)!),
        runDirectory: _toComparablePath(
          runDirectory ?? Directory.current.path,
        ),
      ),
      line,
    );
  } catch (_) {
    // Location unresolved; the measurement the caller actually asserts on stands.
    return null;
  }
}
