/// Which screenshot suites a change can break the layout of, for the layout
/// gate's pre-push hook (#1802 P3, Decision 12). Plain Dart, so a script can
/// run it without Flutter.
library;

/// The parts that every page lays out with. A change in one of them runs every
/// suite: the shared components, the widgets package, the ARB strings, the
/// test harness and the gate itself, and the fonts and images.
const List<String> sharedLayoutPaths = [
  'lib/page/components',
  'plugins/widgets',
  'lib/l10n',
  'test/common',
  'test/layout_gate',
  'assets',
];

/// The suites among [suites] that [changed] can affect.
///
/// - A change under a [sharedLayoutPaths] entry: every suite.
/// - A change under `lib/page/<feature>/` or `test/page/<feature>/`: the suites
///   under `test/page/<feature>/`.
/// - Anything else, such as `lib/core` or the docs: none. A PR's gate in `en`,
///   and the full gate on the way into `main`, still check it.
Set<String> affectedGateSuites(Iterable<String> changed, Set<String> suites) {
  final features = <String>{};
  for (final path in changed) {
    if (sharedLayoutPaths.any((p) => path == p || path.startsWith('$p/'))) {
      return suites;
    }
    final match = _feature.firstMatch(path);
    if (match != null) features.add(match.group(1)!);
  }
  return {
    for (final suite in suites)
      if (features.any((f) => suite.startsWith('test/page/$f/'))) suite,
  };
}

final RegExp _feature = RegExp(r'^(?:lib|test)/page/([^/]+)/');
