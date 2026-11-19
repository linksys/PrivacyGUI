/// One RenderFlex overflow, read from Flutter's report (#1802).
///
/// Ported from 2.x's `test/layout_gate/incident.dart`, trimmed to what 1.x's
/// measurement and gate read. Left out: the golden-report dump transforms, the
/// pub-cache path collapsing and the Windows path handling.
library;

import 'dart:io';

/// An overflow this small is ignored: sub-pixel text shaping differs between
/// macOS and the CI runner, while real defects are many pixels over.
const double kOverflowTolerancePx = 2.0;

/// One RenderFlex overflow captured during a pump.
class OverflowIncident {
  /// How many logical pixels the child exceeded its parent by.
  final double pixels;

  /// The side it overflowed on: `right`, `bottom`, `left` or `top`, or
  /// `unknown` when the report could not be read.
  final String side;

  /// The widget Flutter blamed, e.g. `Row`, or null when the dump named none.
  final String? widget;

  /// Where that widget was created, as `file:line` relative to the repository,
  /// or null when the location did not resolve to a file in the repository.
  final String? site;

  const OverflowIncident({
    required this.pixels,
    required this.side,
    this.widget,
    this.site,
  });

  /// One "<n> pixels on the <side>" clause. Flutter writes a sub-pixel amount
  /// with `toStringAsPrecision(3)`, which can give `1.00e-7`.
  static final _clause = RegExp(r'([\d.]+(?:e-?\d+)?) pixels on the (\w+)');

  /// Parses Flutter's [report], e.g. "A RenderFlex overflowed by 41 pixels on
  /// the right."
  ///
  /// A report can name several sides, always in the order left, top, bottom,
  /// right, so the first clause is not the largest. This keeps the worst one.
  ///
  /// A report with no readable clause gives [unparseablePixels] and side
  /// `unknown`, so it fails every tolerance instead of passing them all.
  ///
  /// The location comes from [fullLog], `FlutterErrorDetails.toString()`,
  /// which carries the "error-causing widget" block; the one-line report does
  /// not. [runDirectory] is stripped from the path, and defaults to the
  /// directory `flutter test` runs in, the app root.
  factory OverflowIncident.parse(
    String report, {
    String fullLog = '',
    String? runDirectory,
  }) {
    var pixels = -1.0;
    var side = 'unknown';
    for (final match in _clause.allMatches(report)) {
      final amount = double.tryParse(match.group(1)!);
      if (amount != null && amount > pixels) {
        pixels = amount;
        side = match.group(2)!;
      }
    }
    final location = _location(
      fullLog.isEmpty ? report : fullLog,
      runDirectory ?? Directory.current.path,
    );
    return OverflowIncident(
      pixels: pixels < 0 ? unparseablePixels : pixels,
      side: side,
      widget: location?.widget,
      site: location?.site,
    );
  }

  /// The amount of a report this parser could not read.
  static const double unparseablePixels = double.infinity;
}

/// Whether [exceptionAsString] is Flutter's own overflow report,
/// "A <RenderObject> overflowed by <n> pixels on the <side>.", the one error
/// the collector may take instead of letting it fail the test.
bool isOverflowError(String exceptionAsString) =>
    exceptionAsString.contains('overflowed by') &&
    exceptionAsString.contains('pixels on the');

/// A creation location as Flutter prints it after a widget's name, e.g.
/// `Row:file:///abs/lib/page/foo/bar.dart:47:12`.
final RegExp _creationLocation =
    RegExp(r'([A-Za-z_]\w*):file://(/[^\s:]+):(\d+):(\d+)');

/// The heading of the block that names the widget that caused the error. The
/// dump can also hold a `creator:` chain whose entries look the same, so the
/// search starts here.
const String _widgetBlock = 'The relevant error-causing widget was';

({String widget, String? site})? _location(String dump, String runDirectory) {
  final start = dump.indexOf(_widgetBlock);
  if (start == -1) return null;
  final match = _creationLocation.firstMatch(dump.substring(start));
  if (match == null) return null;

  final path = _decoded(match.group(2)!);
  final root = runDirectory.endsWith('/') ? runDirectory : '$runDirectory/';
  // A path outside the repository embeds someone's home directory or a
  // runner's workspace, so it is no key: the widget is kept, the site is not.
  final site = path.startsWith(root)
      ? '${path.substring(root.length)}:${match.group(3)}'
      : null;
  return (widget: match.group(1)!, site: site);
}

/// The path out of a `file://` URI arrives percent-encoded, e.g. a space in a
/// home directory as `%20`. An invalid escape is left as it is: this runs
/// inside `FlutterError.onError`, where a throw would fail the test.
String _decoded(String path) {
  if (!path.contains('%')) return path;
  try {
    return Uri.decodeFull(path);
  } on ArgumentError {
    return path;
  } on FormatException {
    return path;
  }
}
