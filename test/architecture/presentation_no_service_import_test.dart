// constitution.md §5.4: dependencies point downward. Presentation renders and
// "access[es] only Providers"; services are the Application layer underneath it,
// reached through a Provider or a Notifier. Models sit below both and must not
// reach back up into services either.
//
// Nothing else enforces it. `flutter analyze` has no rule for import direction,
// and every test of a feature keeps passing when a view imports a service, which
// is how sixteen files came to do it while the rule stood. This test is the rule.
//
// What it does not check: that a view reads only providers. A view may still
// import a model, a widget, a util or another view. The one thing it may not do is
// name a file under `services/`.

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
};

/// `import '…/services/…'`, absolute or relative. `[a-z0-9_]` because feature
/// directories carry digits (`ipv6_port_service`).
final _serviceImport = RegExp(
  r"""^\s*import\s+'(package:privacy_gui/page/[a-z0-9_]+/services/|(\.\./)+services/)[^']*'""",
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
