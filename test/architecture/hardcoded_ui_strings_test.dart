// Interface text is read from the ARB files with `loc(context)`, never written
// into a widget. Nothing else enforces it: `flutter analyze` has no rule for
// it, `tools/check_l10n.dart` (#959) matches only `Text('…')`, `label:` and
// the like, and is not run by CI. So the diagnostics result card kept every one
// of its step names and summaries in English until #1778's review (PR #1984).
// This test is the rule.
//
// What it scans: every string literal in the Presentation layer, the
// directories of [_layers] under `lib/page/<feature>/` and all of
// `lib/components/`. A literal is interface text when it holds a word of two
// letters or more that is not in [_technicalTokens]. It skips literals in
// places that are never shown: directives, annotations, identifiers and keys,
// log and debug calls, map keys and index lookups, comparisons and switch
// patterns, thrown errors, asserts and `toString()`.
//
// What it does not see: text built from a constant declared elsewhere, text a
// model or a service returns (models are not scanned: their strings are data,
// such as the keys the views map to ARB lookups), and English that is spelled
// without letters.
//
// The baseline (`test/fixtures/hardcoded_ui_strings_baseline.json`) holds the
// app's text from before this test, per file and literal. It may only shrink:
// a literal not in it fails, and so does an entry that no longer occurs, so a
// fix also deletes its line. Regenerate it after a fix with
// `HARDCODED_UI_STRINGS_UPDATE=1`, and check that the diff only removes lines.
// [_cleanFeatures] may not appear in it at all.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Directories under `lib/page/<feature>/` whose files render: the
/// Presentation layer (`presentation_no_service_import_test.dart`, without
/// `models`).
const _layers = ['views', 'cards', 'widgets', 'components', 'dialogs'];

/// Features whose interface text is all in the ARB files, and must stay so:
/// none of their files may be in the baseline.
const _cleanFeatures = [
  'lib/page/unified_diagnostics/',
  'lib/page/channel_finder/',
];

const _baselinePath = 'test/fixtures/hardcoded_ui_strings_baseline.json';

/// Words that stay as they are in every locale: units, protocol and standard
/// names, and brand-like terms the ARB files themselves keep in English.
const _technicalTokens = {
  // Units.
  'ms', 'dBm', 'dB', 'Mbps', 'Kbps', 'Gbps', 'KB', 'MB', 'GB', 'TB',
  'GHz', 'MHz', 'Hz', 'bps',
  // Network and protocol names.
  'WAN', 'LAN', 'DNS', 'DHCP', 'IP', 'IPv4', 'IPv6', 'MAC', 'SSID', 'BSSID',
  'RTT', 'MTU', 'TCP', 'UDP', 'NAT', 'DMZ', 'UPnP', 'WPS', 'VPN', 'PPPoE',
  'PPTP', 'L2TP', 'QoS', 'MLO', 'DFS', 'ICMP', 'HTTP', 'HTTPS', 'SSH', 'NTP',
  'ISP', 'URL', 'ID', 'TTL', 'WPA', 'WPA2', 'WPA3', 'WEP', 'AES', 'TKIP',
  'USB', 'LED', 'CPU', 'RAM', 'GPS', 'SIP', 'FTP', 'ax', 'ac', 'be',
  'WiFi', 'Ethernet', 'USP', 'TR',
};

void main() {
  test(
      'interface text is read from the ARB files, not written into a widget '
      '(#1778)', () {
    final found = _scan();

    if (Platform.environment['HARDCODED_UI_STRINGS_UPDATE'] == '1') {
      _writeBaseline(found);
      return;
    }

    final baseline = _readBaseline();
    final problems = <String>[];

    for (final file in baseline.keys) {
      for (final clean in _cleanFeatures) {
        if (file.startsWith(clean)) {
          problems.add('$file is in the baseline, but every file under $clean '
              'must read its text from the ARB files. Fix it; do not exempt it.');
        }
      }
    }

    for (final MapEntry(key: file, value: literals) in found.entries) {
      final allowed = baseline[file] ?? const <String, int>{};
      final counts = <String, int>{};
      for (final literal in literals) {
        counts[literal.text] = (counts[literal.text] ?? 0) + 1;
      }
      for (final literal in literals) {
        if ((counts[literal.text] ?? 0) > (allowed[literal.text] ?? 0)) {
          problems.add('$file:${literal.line} writes interface text into the '
              "widget: '${literal.text}'. Add it to lib/l10n/app_en.arb and "
              'every other locale, and read it with loc(context). A word that '
              'stays the same in every language goes in _technicalTokens.');
          counts[literal.text] = counts[literal.text]! - 1;
        }
      }
    }

    for (final MapEntry(key: file, value: allowed) in baseline.entries) {
      final counts = <String, int>{};
      for (final literal in found[file] ?? const <_Literal>[]) {
        counts[literal.text] = (counts[literal.text] ?? 0) + 1;
      }
      for (final MapEntry(key: text, value: count) in allowed.entries) {
        if ((counts[text] ?? 0) < count) {
          problems.add("$_baselinePath lists '$text' in $file, which no longer "
              'has it. Delete the entry: the baseline only shrinks. '
              '(HARDCODED_UI_STRINGS_UPDATE=1 rewrites it.)');
        }
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the scanner flags interface text and skips what is never shown', () {
    final literals = _scanSource('''
import 'package:flutter/material.dart';

@Deprecated('Use the other one')
class Example extends StatelessWidget {
  Widget build(BuildContext context) {
    logger.i('Building the example');
    debugPrint('Debug text');
    final map = {'downloadMbps': 1};
    if (status == 'Complete') {}
    final v = data['rawKey'];
    assert(v != null, 'Never null here');
    return Column(children: [
      Text('Channel Congestion'),
      Text('\${count} devices'),
      Text('\${rssi} dBm'),
      Text('2.4GHz'),
      AppButton(identifier: 'channel-finder-scan', label: 'Scan'),
      Container(key: ValueKey('row-key')),
      Text('--'),
    ]);
  }

  @override
  String toString() => 'Example(debug)';

  void fail() => throw StateError('Broken state');
}
''');

    expect(literals.map((l) => l.text),
        ['Channel Congestion', r'${…} devices', 'Scan']);
  });
}

/// One string literal the scanner took for interface text.
class _Literal {
  final int line;

  /// The literal as written, with each interpolation shown as `${…}`.
  final String text;

  const _Literal(this.line, this.text);
}

Map<String, List<_Literal>> _scan() {
  final files = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final segments = path.split('/');
    final inPageLayer = segments.length > 3 &&
        segments[1] == 'page' &&
        segments.skip(3).any(_layers.contains);
    final inComponents = segments.length > 2 && segments[1] == 'components';
    if (inPageLayer || inComponents) files.add(path);
  }
  files.sort();
  return {
    for (final path in files)
      if (_scanSource(File(path).readAsStringSync(), path: path)
          case final found when found.isNotEmpty)
        path: found,
  };
}

List<_Literal> _scanSource(String source, {String path = 'example.dart'}) {
  final result =
      parseString(content: source, path: path, throwIfDiagnostics: false);
  final visitor = _LiteralVisitor(result.lineInfo.getLocation);
  result.unit.accept(visitor);
  return visitor.found;
}

class _LiteralVisitor extends RecursiveAstVisitor<void> {
  _LiteralVisitor(this._location);

  final dynamic Function(int offset) _location;
  final found = <_Literal>[];

  @override
  void visitAnnotation(Annotation node) {}

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // 'a' 'b' is one text.
    final text = node.strings.map(_text).join();
    _consider(node, text);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.parent is AdjacentStrings) return;
    _consider(node, node.value);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.parent is! AdjacentStrings) _consider(node, _text(node));
    super.visitStringInterpolation(node);
  }

  static String _text(StringLiteral literal) => switch (literal) {
        SimpleStringLiteral(:final value) => value,
        StringInterpolation(:final elements) => [
            for (final e in elements)
              e is InterpolationString ? e.value : r'${…}',
          ].join(),
        AdjacentStrings(:final strings) => strings.map(_text).join(),
      };

  void _consider(AstNode node, String text) {
    if (!_isWords(text) || _neverShown(node)) return;
    found.add(_Literal(_location(node.offset).lineNumber as int, text));
  }

  static final _token = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  static final _letters = RegExp(r'\p{L}', unicode: true);
  static final _notText = [
    RegExp(r'^(https?|wss?)://'),
    RegExp(r'^(assets|packages)/'),
    RegExp(r'^[\w.]+\.(dart|png|svg|json|jpg|ttf|woff2?)$'),
    RegExp(r'^/[\w/{}:]*$'), // route paths
  ];

  /// Whether [text] holds a word of two letters or more that is not a
  /// technical token. Leading digits are not part of the word: "2.4GHz" is
  /// "GHz".
  static bool _isWords(String text) {
    if (_notText.any((p) => p.hasMatch(text))) return false;
    for (final match in _token.allMatches(text)) {
      final word = match.group(0)!.replaceFirst(RegExp(r'^\d+'), '');
      if (_letters.allMatches(word).length < 2) continue;
      if (_technicalTokens.contains(word)) continue;
      return true;
    }
    return false;
  }

  static const _hiddenArguments = {
    'identifier',
    'semanticsIdentifier',
    'key',
    'heroTag',
    'restorationId',
    'debugLabel',
    'fontFamily',
    'package',
    'name',
    'routeName',
    'path',
  };

  static const _hiddenCalls = {
    // Keys, patterns, parsing, formats.
    'Key', 'ValueKey', 'ObjectKey', 'GlobalKey', 'PageStorageKey', 'RegExp',
    'Uri', 'DateFormat', 'NumberFormat', 'AssetImage', 'Image.asset',
    // Logs and debugging.
    'debugPrint', 'print', 'log',
    // String and map plumbing.
    'containsKey', 'startsWith', 'endsWith', 'contains', 'split',
    'replaceAll', 'replaceFirst', 'indexOf', 'lastIndexOf', 'padLeft',
    'padRight', 'join', 'getString', 'setString', 'remove', 'parse',
    'tryParse',
    // Navigation by route name.
    'pushNamed', 'goNamed', 'replaceNamed', 'pushReplacementNamed', 'go',
    'push',
  };

  static bool _neverShown(AstNode node) {
    AstNode child = node;
    for (var parent = node.parent; parent != null; parent = parent.parent) {
      switch (parent) {
        case NamedArgument(:final name)
            when _hiddenArguments.contains(name.lexeme):
          return true;
        case MethodInvocation(:final methodName, :final target):
          if (_hiddenCalls.contains(methodName.name)) return true;
          final receiver = target?.toSource();
          if (receiver == 'logger' || receiver == 'developer') return true;
        case InstanceCreationExpression(:final constructorName):
          final type = constructorName.type.name.lexeme;
          if (_hiddenCalls.contains(type) ||
              type.endsWith('Error') ||
              type.endsWith('Exception')) {
            return true;
          }
        case IndexExpression(:final index) when index == child:
          return true;
        case MapLiteralEntry(:final key) when key == child:
          return true;
        case BinaryExpression(:final operator)
            when operator.lexeme == '==' || operator.lexeme == '!=':
          return true;
        case ConstantPattern() || SwitchCase():
          return true;
        case ThrowExpression() || Assertion() || Directive():
          return true;
        case MethodDeclaration(:final name) when name.lexeme == 'toString':
          return true;
        case Statement() || ClassMember() || CompilationUnitMember():
          // Past the expression the literal is in; nothing further up
          // changes whether it is shown.
          if (parent is! FunctionBody) return false;
      }
      child = parent;
    }
    return false;
  }
}

Map<String, Map<String, int>> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return const {};
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final MapEntry(key: path, value: entries) in json.entries)
      path: {
        for (final MapEntry(key: text, value: count)
            in (entries as Map<String, dynamic>).entries)
          text: count as int,
      },
  };
}

void _writeBaseline(Map<String, List<_Literal>> found) {
  final json = <String, Map<String, int>>{};
  for (final MapEntry(key: path, value: literals) in found.entries) {
    final counts = <String, int>{};
    for (final literal in literals) {
      counts[literal.text] = (counts[literal.text] ?? 0) + 1;
    }
    json[path] = Map.fromEntries(
        counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
  File(_baselinePath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
}
