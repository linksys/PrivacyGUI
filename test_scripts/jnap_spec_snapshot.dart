// Writes the service → actions table of the JNAP spec that 1.x firmware
// builds, for the tests of lib/core/jnap/actions/ (#1923).
//
// usage: dart test_scripts/jnap_spec_snapshot.dart <JNAP checkout> <pin> <baseline>
//            > test/test_data/jnap_spec.json
//
// - <JNAP checkout> is a clone of linksys/JNAP. A partial clone is enough:
//   gh repo clone linksys/JNAP <dir> -- --filter=blob:none --no-checkout
// - <pin> is the commit 1.x firmware builds: PKG_SOURCE_VERSION in
//   linksys/feed_linksys jnap/Makefile. Not linksys/JNAP's main branch.
// - <baseline> is the JNAP release in the oldest firmware 1.x still supports.
//   Its services need no gate (#1923).
//
// The specs are openwrt-jnap/src/spec/**/*.hsl. Each file declares a
// namespace, and each `service` in it lists the full set of actions of that
// version. The legacy JNAP API reference is not a source: it disagrees with
// openwrt-jnap (it lists GetWANExternal under Router13).
//
// Rerun when feed_linksys moves the pin, and commit the result with the tests
// it changes.
import 'dart:convert';
import 'dart:io';

const _specDir = 'openwrt-jnap/src/spec';

/// The services that one .hsl file defines, each keyed by its full URL
/// (namespace and name, as in GetDeviceInfo's `services`), with its actions
/// in the order the file lists them.
Map<String, List<String>> parseHsl(String text) {
  final namespacePattern = RegExp(r'^namespace\s+"([^"]+)"');
  final servicePattern = RegExp(r'^service\s+([A-Za-z0-9_]+)\s*$');
  final namePattern = RegExp(r'^[A-Za-z0-9_]+$');

  String? namespace;
  String? service;
  var inActions = false;
  final services = <String, List<String>>{};

  for (final raw in const LineSplitter().convert(text)) {
    // `#` starts a comment, and `#@` a doc comment; neither ends a block.
    final line = raw.replaceFirst(RegExp(r'#.*$'), '').trimRight();
    if (line.isEmpty) continue;

    final namespaceMatch = namespacePattern.firstMatch(line);
    if (namespaceMatch != null) {
      namespace = namespaceMatch.group(1);
      service = null;
      continue;
    }
    final serviceMatch = servicePattern.firstMatch(line);
    if (serviceMatch != null) {
      if (namespace == null) {
        throw FormatException(
            'service ${serviceMatch.group(1)} appears before any namespace');
      }
      service = '$namespace${serviceMatch.group(1)}';
      services[service] = [];
      inActions = false;
      continue;
    }
    // Any other statement at the start of a line ends the service.
    if (!line.startsWith(' ') && !line.startsWith('\t')) {
      service = null;
      continue;
    }
    if (service == null) continue;

    final token = line.trim();
    if (token == 'actions') {
      inActions = true;
    } else if (inActions && namePattern.hasMatch(token)) {
      services[service]!.add(token);
    }
  }
  return services;
}

/// Joins the services of several files. A service that two files define
/// (healthcheck.hsl and healthcheck_samknows.hsl, which firmware builds one
/// of) gets the union of their actions. Keys and actions come out sorted.
Map<String, List<String>> mergeServices(
    Iterable<Map<String, List<String>>> files) {
  final merged = <String, Set<String>>{};
  for (final file in files) {
    file.forEach((service, actions) {
      merged.putIfAbsent(service, () => <String>{}).addAll(actions);
    });
  }
  final keys = merged.keys.toList()..sort();
  return {for (final key in keys) key: merged[key]!.toList()..sort()};
}

/// The baseline services whose actions differ at the pin, or that the pin
/// drops. The tests read a baseline service's actions from the pin, which
/// holds only while this is empty.
List<String> baselineMismatches({
  required Map<String, List<String>> baseline,
  required Map<String, List<String>> pin,
}) {
  final mismatches = <String>[];
  for (final MapEntry(key: service, value: actions) in baseline.entries) {
    final atPin = pin[service];
    if (atPin == null) {
      mismatches.add('$service: the pin drops it');
      continue;
    }
    final added = atPin.where((a) => !actions.contains(a)).toList();
    final dropped = actions.where((a) => !atPin.contains(a)).toList();
    if (added.isNotEmpty || dropped.isNotEmpty) {
      mismatches.add([
        '$service:',
        if (added.isNotEmpty) 'the pin adds ${added.join(', ')}',
        if (dropped.isNotEmpty) 'the pin drops ${dropped.join(', ')}',
      ].join(' '));
    }
  }
  return mismatches;
}

Future<String> _git(String checkout, List<String> args) async {
  final result = await Process.run('git', ['-C', checkout, ...args]);
  if (result.exitCode != 0) {
    throw ProcessException('git', args, '${result.stderr}', result.exitCode);
  }
  return result.stdout as String;
}

Future<Map<String, List<String>>> _servicesAt(
    String checkout, String ref) async {
  final listing =
      await _git(checkout, ['ls-tree', '-r', '--name-only', ref, _specDir]);
  final paths = const LineSplitter()
      .convert(listing)
      .where((path) => path.endsWith('.hsl'))
      .toList();
  final files = <Map<String, List<String>>>[];
  for (final path in paths) {
    files.add(parseHsl(await _git(checkout, ['show', '$ref:$path'])));
  }
  return mergeServices(files);
}

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
        'usage: dart test_scripts/jnap_spec_snapshot.dart <JNAP checkout> <pin> <baseline>');
    exit(2);
  }
  final [checkout, pin, baseline] = args;
  final pinSha = (await _git(checkout, ['rev-parse', '$pin^{commit}'])).trim();
  final baselineSha =
      (await _git(checkout, ['rev-parse', '$baseline^{commit}'])).trim();

  final services = await _servicesAt(checkout, pinSha);
  final baselineSpec = await _servicesAt(checkout, baselineSha);
  final mismatches = baselineMismatches(baseline: baselineSpec, pin: services);
  if (mismatches.isNotEmpty) {
    stderr.writeln('The tests read a baseline service from the pin, but these '
        'differ. Store the baseline actions too before regenerating:');
    mismatches.forEach(stderr.writeln);
    exit(1);
  }
  final baselineServices = baselineSpec.keys;

  const encoder = JsonEncoder.withIndent('  ');
  stdout.writeln(encoder.convert({
    'about': 'Generated by test_scripts/jnap_spec_snapshot.dart from '
        'linksys/JNAP $_specDir. Do not edit by hand (#1923).',
    'pin': {
      'commit': pinSha,
      'from': 'linksys/feed_linksys jnap/Makefile PKG_SOURCE_VERSION',
    },
    'baseline': {
      'ref': baseline,
      'commit': baselineSha,
      'about': 'The JNAP release in the oldest firmware 1.x still supports. '
          'Its services need no gate. Provisional until #1923 confirms it.',
    },
    'services': services,
    'baselineServices': baselineServices.toList(),
  }));
}
