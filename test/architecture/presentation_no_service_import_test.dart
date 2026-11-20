// constitution.md §5.4: dependencies point downward. Presentation renders and
// "access[es] only Providers"; services are the Application layer underneath it,
// reached through a Provider or a Notifier. Models sit below both and must not
// reach back up into services either.
//
// Nothing else enforces it. `flutter analyze` has no rule for import direction,
// and every test of a feature keeps passing when a view imports a service, which
// is how twenty-six files came to do it while the rule stood: sixteen into a
// feature's `services/`, ten into `lib/core/**/services/`. This test is the rule.
//
// What it does not check: that a view reads only providers. A view may still
// import a model, a widget, a util or another view. The one thing it may not do is
// name a file under a `services/` directory, a feature's or `lib/core/`'s.
//
// Also outside it, each a known gap rather than an oversight:
// - `export` directives. A provider may re-export a service's types.
// - `helpers/` and other directories not in [_layers]. `support/shared_widgets/`
//   is the one UI-named one: its `components/` are scanned, and its only
//   service imports are in `generators/`, which are logic, not UI.
//
// There is no allowlist. #1836 fixed the last three files that had one (the
// router assistant view, the USP test console, the package widget renderer) and
// deleted the map with them, under the team's 2026-11-17 no-exceptions policy: an
// import that breaks this rule is fixed, never exempted.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directories under `lib/page/<feature>/` whose files render or describe state:
/// the Presentation layer and the models beneath it.
const _layers = [
  'views',
  'cards',
  'widgets',
  'components',
  'dialogs',
  'models'
];

/// An import of a file under a `services/` directory: a feature's at any depth
/// (`support/shared_widgets/faq_agent/services/`) or `lib/core/`'s
/// (`core/usp/services/`), absolute or relative, including into another feature
/// (`../../other/services/`). Either quote. `[a-z0-9_/]` because directories carry digits
/// (`ipv6_port_service`) and nest.
final _serviceImport = RegExp(
  r"""^\s*import\s+['"](package:privacy_gui/(page|core)/([a-z0-9_]+/)*services/|(\.\./)+([a-z0-9_]+/)*services/)[^'"]*['"]""",
  multiLine: true,
);

void main() {
  /// Every Dart file under `lib/page/` that belongs to one of [_layers].
  List<File> layerFiles() => Directory('lib/page')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
        final parts = f.path.split('/');
        return _layers.any(parts.contains);
      }).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the scan reaches the layers it is meant to', () {
    // A guard that finds no files passes by construction. These two are known to
    // exist; if either drops out the path filter is wrong, not the code clean.
    final paths = layerFiles().map((f) => f.path).toSet();
    expect(paths, contains('lib/page/firewall/views/usp_firewall_view.dart'));
    expect(
        paths,
        contains(
            'lib/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart'));
  });

  test('no view, card, widget, component, dialog or model imports a service',
      () {
    final offenders = <String>[];
    for (final f in layerFiles()) {
      for (final m in _serviceImport.allMatches(f.readAsStringSync())) {
        offenders.add('${f.path}: ${m.group(0)!.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'constitution §5.4: Presentation and models depend downward, never '
          'on services. Move a pure constant, enum, function or UI model into '
          'models/; move a service Provider into providers/; or route an I/O '
          'call through the page\'s Notifier.\n'
          '${offenders.join('\n')}',
    );
  });
}
