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

/// Files allowed to import a service, each with the reason.
///
/// Empty is the goal. An entry here is a decision, not a fix: it has to say why
/// the import is the right shape for that file.
const _allowed = <String, String>{
  // Reads `awsCredentialsStoreProvider`, a `Provider<AwsCredentialsStore>`, so
  // the view already reaches the store through a Provider. The page has no
  // notifier to route it through, and adding one only to hold four calls was
  // decided against (2026-10-12).
  'lib/page/ai_assistant/views/router_assistant_view.dart':
      'reads a service Provider<T>; page has no notifier',

  // A developer tool whose job is to talk to USP directly: it builds its own
  // `UspClient` / `UspBridgeClient` against a URL the developer types, so there
  // is no service to route it through that would not be this view again.
  'lib/page/test_console/views/usp_test_console_view.dart':
      'developer USP console; builds its own client by design',

  // A debt left on purpose: the widget holds a whole data layer (USP reads, CGI
  // calls, SSE subscription, polling) and imports the throttler for one enum.
  // Moving the enum would make this green and fix nothing, and package widgets
  // may be removed outright, so the data layer is not moved for now
  // (2026-10-13). If they stay, it moves to a service and a notifier.
  'lib/page/dashboard/widgets/package_widget_renderer.dart':
      'holds its own data layer; package widgets may be removed',
};

/// An import of a file under a `services/` directory: a feature's at any depth
/// (`login/auto_parent/services/`) or `lib/core/`'s (`core/usp/services/`),
/// absolute or relative, including into another feature (`../../other/services/`).
/// Either quote. `[a-z0-9_/]` because directories carry digits
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
      if (_allowed.containsKey(f.path)) continue;
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
          'models/, or route an I/O call through the page\'s Notifier. Only add '
          'to _allowed with a reason the import is the right shape.\n'
          '${offenders.join('\n')}',
    );
  });

  test('every allowed exception still imports a service', () {
    // An entry whose file no longer imports a service is a stale exemption: it
    // would silently allow the next import added there.
    final stale = _allowed.keys
        .where((p) => !_serviceImport.hasMatch(File(p).readAsStringSync()))
        .toList();
    expect(stale, isEmpty, reason: 'remove these from _allowed: $stale');
  });
}
