import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Every translation keeps each placeholder its English string declares, so
/// no locale drops a value the app passes in (#1802: Vietnamese showed
/// "WiFi Band" with no band, and a date and a time not at all).
void main() {
  final template = _arb('lib/l10n/app_en.arb');
  // What the metadata declares, and what the English string uses at its top
  // level: gen-l10n takes an undeclared `{x}` as a placeholder too.
  final placeholders = {
    for (final MapEntry(:key, :value) in template.entries)
      if (!key.startsWith('@') && value is String)
        if ({
          ..._topLevelNames(value),
          if (template['@$key'] case {'placeholders': final Map declared})
            ...declared.keys.cast<String>(),
        }
            case final names when names.isNotEmpty)
          key: names,
  };
  final translations = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.arb') && !path.endsWith('/app_en.arb'))
      .toList()
    ..sort();

  for (final path in translations) {
    test('$path keeps every placeholder', () {
      final arb = _arb(path);
      final dropped = [
        for (final MapEntry(key: name, value: wanted) in placeholders.entries)
          if (arb[name] case final String text)
            for (final placeholder in wanted)
              // `{x}`, or `{x, plural, …}` and the like.
              if (!RegExp('\\{\\s*$placeholder\\s*[,}]').hasMatch(text))
                '$name: {$placeholder}',
      ];

      expect(dropped, isEmpty,
          reason: 'These strings leave out a placeholder that app_en.arb '
              'declares, so the value never shows.');
    });
  }
}

/// The names an ICU message uses at its top level: `{x}`, or `{x, plural,
/// …}` and the like, but not the text inside a plural's branches.
Set<String> _topLevelNames(String message) {
  final names = <String>{};
  var depth = 0;
  for (var i = 0; i < message.length; i++) {
    if (message[i] == '{') {
      if (depth == 0) {
        final match = RegExp(r'\{\s*(\w+)\s*[,}]').matchAsPrefix(message, i);
        if (match != null) names.add(match.group(1)!);
      }
      depth++;
    } else if (message[i] == '}' && depth > 0) {
      depth--;
    }
  }
  return names;
}

Map<String, dynamic> _arb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
