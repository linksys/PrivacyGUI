import 'package:flutter/foundation.dart';

/// Extracts diagnostic detail from Flutter's RenderFlex overflow errors so the
/// golden reports can say where and by how much a layout overflowed, instead of
/// only that it did (#1197).
///
/// Both the error message and the diagnostics dump are Flutter implementation
/// details, not API contracts. Every extraction here is individually
/// failure-tolerant: an unmatched pattern yields absent fields rather than an
/// exception, because a diagnostic path must never turn a passing golden run
/// into a failure. `overflow_diagnostics_test.dart` pins the formats so an SDK
/// upgrade that changes them fails loudly in one place.

/// Matches `A RenderFlex overflowed by 50 pixels on the right.`
///
/// The pixel group tolerates a decimal point: Flutter's `_formatPixels` emits
/// one decimal for values in (1, 10] and three significant digits at or below
/// 1.0.
final RegExp _amountPattern =
    RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)');

/// Matches the creation location Flutter appends after a widget name, e.g.
/// `Row:file:///abs/path/to/lib/page/foo/bar.dart:47:12`.
final RegExp _locationPattern =
    RegExp(r'([A-Za-z_]\w*):file://([^\s:]+):(\d+):(\d+)');

/// The heading of the block naming the widget that caused the error.
const String _widgetBlockMarker = 'The relevant error-causing widget was';

/// Parses the overflow direction and pixel amount out of an error message.
///
/// Returns `pixels` and `side`, or an empty map when [message] does not match.
/// A single overflow can report two sides (`... on the left and ... on the
/// top`); the first is recorded and the full text stays in the raw message.
Map<String, String> parseOverflowAmount(String message) {
  final match = _amountPattern.firstMatch(message);
  if (match == null) return const {};
  return {'pixels': match.group(1)!, 'side': match.group(2)!};
}

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
/// An unrecognized path is returned unchanged — better a long path than none.
String normalizeSourcePath(String absolutePath,
    {required String runDirectory}) {
  final root = runDirectory.endsWith('/') ? runDirectory : '$runDirectory/';
  if (absolutePath.startsWith(root)) {
    return absolutePath.substring(root.length);
  }

  const cacheMarkers = ['/.pub-cache/git/', '/.pub-cache/hosted/'];
  for (final marker in cacheMarkers) {
    final index = absolutePath.indexOf(marker);
    if (index == -1) continue;
    var tail = absolutePath.substring(index + marker.length);
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

  return absolutePath;
}

/// Parses the offending widget's name and source location out of a deep
/// diagnostics dump.
///
/// Returns `widget`, `file` and `line`, or an empty map when the dump carries no
/// resolvable location. The search is anchored inside the error-causing-widget
/// block: the dump also contains a `creator:` chain whose entries match
/// [_locationPattern], and the two blocks' relative order comes from the order
/// of Flutter's `informationCollector` list — an implementation detail that an
/// SDK upgrade could reorder.
///
/// Resolution relies on widget creation tracking, which `flutter test` enables
/// by default.
Map<String, String> parseOverflowSource(
  String diagnosticsDump, {
  required String runDirectory,
}) {
  final blockStart = diagnosticsDump.indexOf(_widgetBlockMarker);
  if (blockStart == -1) return const {};

  final match =
      _locationPattern.firstMatch(diagnosticsDump.substring(blockStart));
  if (match == null) return const {};

  return {
    'widget': match.group(1)!,
    'file': normalizeSourcePath(match.group(2)!, runDirectory: runDirectory),
    'line': match.group(3)!,
  };
}

/// Builds the full record written for one overflow error.
///
/// [runDirectory] is the directory the test process runs in, which is the app
/// root: `golden_runner` reads and writes `goldens/...` through relative paths.
///
/// `message` is kept verbatim so nothing that reads it today breaks and so
/// multi-side overflows keep their full text. The two extractions are
/// independent: if one pattern misses, the fields the other resolved are still
/// written.
Map<String, String> buildOverflowRecord({
  required String goldenName,
  required FlutterErrorDetails details,
  required String runDirectory,
}) {
  final message = details.exceptionAsString();
  final record = <String, String>{
    'golden': goldenName,
    'message': message,
    ...parseOverflowAmount(message),
  };

  // toDiagnosticsNode() runs the inspector transformer that resolves the
  // creating widget's source location. Guard it: this runs inside an error
  // handler, and a throw here would surface as a test failure.
  try {
    record.addAll(parseOverflowSource(
      details.toDiagnosticsNode().toStringDeep(),
      runDirectory: runDirectory,
    ));
  } catch (_) {
    // Location unresolved; the amount fields above still stand.
  }

  return record;
}
