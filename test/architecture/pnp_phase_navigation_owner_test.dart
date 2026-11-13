import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The only file allowed to navigate on a PnP phase (#1511 P2).
const _owner = 'lib/page/instant_setup/views/pnp_flow_shell.dart';

/// A navigation call on a `BuildContext` or a `GoRouter`.
final _navigation =
    RegExp(r'\.(go|goNamed|push|pushNamed|pushReplacement|replace|pop)\s*[<(]');

/// A listener on PnP's flow state, `select`ed or not.
final _pnpListener =
    RegExp(r'\bref\.listen(Manual)?\s*(<[^>]*>)?\s*\(\s*pnpProvider\b');

/// The text of the call that opens at [open], an index of `(`, through its
/// matching `)`. Good enough for this repo's sources: string literals inside a
/// listener do not carry unbalanced parentheses.
String _call(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '(') depth++;
    if (source[i] == ')' && --depth == 0) return source.substring(open, i + 1);
  }
  return source.substring(open);
}

/// Exactly one place maps a PnP phase to a page (#1511 P2 AC 1).
///
/// It used to be six — the entry view's listener and five in the troubleshooting
/// views — kept in step by hand. #1511 P1 moved the five to troubleshooting's own
/// state and P2 moved the sixth into `PnpFlowShell`, so the mapping is
/// `pnpFlowDestination` and the shell is what acts on it. This pins that: a
/// listener on `pnpProvider` anywhere else in `lib/` may react to a phase (the
/// setup view's snackbar does), but it may not navigate.
void main() {
  test('only the PnP shell navigates on a PnP phase', () {
    final navigators = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in _pnpListener.allMatches(source)) {
        final open = source.indexOf('(', match.start);
        if (_navigation.hasMatch(_call(source, open))) {
          navigators.add(file.path.replaceAll('\\', '/'));
        }
      }
    }

    expect(
      navigators,
      {_owner},
      reason: 'a listener on pnpProvider that navigates is a second phase→page '
          'mapping; put the destination in pnpFlowDestination instead. And '
          'if the shell is missing from the set, the scan no longer sees the '
          'one listener that must navigate, so it cannot see a second either.',
    );
  });
}
