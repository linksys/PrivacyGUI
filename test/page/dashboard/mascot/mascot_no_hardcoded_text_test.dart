import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #1312: nothing under `lib/page/dashboard/mascot/` shows the user English
/// that is not from an ARB key.
///
/// The mascot is on by default in local builds, and before #1312 every word it
/// said was a string literal: greetings, health statuses, tips, alerts. A
/// literal added there now fails this test.
///
/// ## What counts as user-visible
///
/// A string literal whose text, with interpolations removed, has a letter and
/// either whitespace, a leading capital or trailing sentence punctuation. That
/// reads `'Tap for actions'`, `'Loading...'`, `'internet connection'` and
/// `'$enabled/$total enabled'` as copy, and `'health_dashboard'`, `'cat_$i'`
/// and `'mascot-to-ai-assistant'` as identifiers. The detector's own cases
/// below pin both halves.
///
/// One shape it cannot tell apart: a single lowercase word, which reads like
/// `'back'` or `'main'`, the dialog's option ids. A bare `'enabled'` shown to
/// the user would pass here; `dashboard_text_translated_test.dart` and the
/// per-locale widget test in `health_dialog_provider_test.dart` are the
/// backstop for that.
///
/// ## The allowlist
///
/// Literals inside a call in [_nonUiCalls] are logs, never shown to the user.
/// That is the whole allowlist: a log is exempt by where it is, so a literal
/// moved out of a log call is caught.
const _mascotDir = 'lib/page/dashboard/mascot';

/// Calls whose string arguments are logs, not UI.
final _nonUiCalls = RegExp(r'(?:\bdebugPrint|\blogger\s*\.\s*\w+)\s*$');

class _Literal {
  _Literal(this.line, this.text, {required this.inLog});

  final int line;

  /// The text between the quotes, with each interpolation replaced by `{}`.
  final String text;

  final bool inLog;
}

/// Whether [text] reads as copy for a person rather than as an identifier.
bool _looksUserVisible(String text) {
  final words = text.replaceAll('{}', '').trim();
  if (!RegExp('[A-Za-z]').hasMatch(words)) return false;
  return RegExp(r'\s').hasMatch(words) ||
      RegExp('^[A-Z]').hasMatch(words) ||
      RegExp(r'[.!?]$').hasMatch(words);
}

/// Every string literal in [source], in order.
///
/// A small lexer rather than a regex: comments are skipped, `'`, `"`, triple
/// quotes and raw strings are read whole, and an interpolation is lexed as
/// code, so a string inside `${...}` is found too. Open parentheses are kept on
/// a stack that remembers whether each one opened a [_nonUiCalls] call.
List<_Literal> _literals(String source) {
  final found = <_Literal>[];
  final logParens = <bool>[];
  var i = 0;

  int lineAt(int offset) =>
      '\n'.allMatches(source.substring(0, offset)).length + 1;

  bool inLog() => logParens.contains(true);

  late void Function({required int closeBrace}) code;

  // Reads a string starting at [i] (on its opening quote) and records it.
  void string({required bool raw}) {
    final start = i;
    final quote = source[i];
    final triple = source.startsWith(quote * 3, i);
    final close = triple ? quote * 3 : quote;
    i += close.length;
    final text = StringBuffer();
    while (i < source.length && !source.startsWith(close, i)) {
      final c = source[i];
      if (!raw && c == r'\') {
        text.write(source[i + 1]);
        i += 2;
      } else if (!raw && source.startsWith(r'${', i)) {
        i += 2;
        code(closeBrace: 1);
        text.write('{}');
      } else if (!raw &&
          c == r'$' &&
          RegExp('[A-Za-z_]').hasMatch(source[i + 1])) {
        i++;
        while (i < source.length && RegExp(r'\w').hasMatch(source[i])) {
          i++;
        }
        text.write('{}');
      } else {
        text.write(c);
        i++;
      }
    }
    i += close.length;
    found.add(_Literal(lineAt(start), text.toString(), inLog: inLog()));
  }

  // Lexes code from [i]. With [closeBrace] > 0 it is an interpolation, and
  // returns after the brace that closes it.
  code = ({required int closeBrace}) {
    var braces = closeBrace;
    while (i < source.length) {
      final c = source[i];
      if (source.startsWith('//', i)) {
        i = source.indexOf('\n', i);
        if (i < 0) i = source.length;
      } else if (source.startsWith('/*', i)) {
        i = source.indexOf('*/', i) + 2;
      } else if ((c == 'r') &&
          i + 1 < source.length &&
          (source[i + 1] == "'" || source[i + 1] == '"') &&
          (i == 0 || !RegExp(r'\w').hasMatch(source[i - 1]))) {
        i++;
        string(raw: true);
      } else if (c == "'" || c == '"') {
        string(raw: false);
      } else if (c == '(') {
        logParens.add(_nonUiCalls.hasMatch(source.substring(0, i)));
        i++;
      } else if (c == ')') {
        if (logParens.isNotEmpty) logParens.removeLast();
        i++;
      } else if (closeBrace > 0 && c == '{') {
        braces++;
        i++;
      } else if (closeBrace > 0 && c == '}') {
        braces--;
        i++;
        if (braces == 0) return;
      } else {
        i++;
      }
    }
  };

  code(closeBrace: 0);
  return found;
}

void main() {
  final files = Directory(_mascotDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  group('the detector', () {
    test('reads copy as user-visible', () {
      for (final copy in [
        'Tap for actions',
        'Loading...',
        'Hi!',
        'internet connection',
        '{} WiFi radio has been disabled.',
        'Your mesh network has {} node{} active',
        // The ticket's own example: `'$enabledCount/$totalCount enabled'`.
        '{}/{} enabled',
        '{}% used',
      ]) {
        expect(_looksUserVisible(copy), isTrue, reason: copy);
      }
    });

    test('reads identifiers and formats as not', () {
      for (final id in [
        'health_dashboard',
        'cat_{}',
        'mascot-to-ai-assistant',
        'back',
        '{}/{}',
        '{}%',
      ]) {
        expect(_looksUserVisible(id), isFalse, reason: id);
      }
    });

    test('finds a literal in an interpolation and knows a log from copy', () {
      final found = _literals(r'''
        // 'In a comment'
        final a = 'Shown ${b ? 'Nested' : r'Raw'}';
        logger.d('[Tag]: logged '
            '(${n} more)');
        debugPrint("Also logged");
        final c = """Triple""";
      ''');
      expect(
        [for (final l in found) (l.text, l.inLog)],
        [
          // An interpolation's strings are recorded before the string that
          // holds them, which ends after them.
          ('Nested', false),
          ('Raw', false),
          ('Shown {}', false),
          ('[Tag]: logged ', true),
          ('({} more)', true),
          ('Also logged', true),
          ('Triple', false),
        ],
      );
    });
  });

  test('every mascot source file is scanned', () {
    expect(files.length, greaterThan(20),
        reason: 'the mascot directory moved, or this is listing the wrong one');
    final logs = [
      for (final f in files)
        ..._literals(f.readAsStringSync()).where((l) => l.inLog),
    ];
    expect(
        logs.map((l) => l.text), contains('[Mascot][Trigger]: WAN went down'),
        reason: 'the scan no longer sees the trigger provider\'s logs, so it '
            'is not reading the files it claims to');
  });

  test('no mascot file shows the user a hardcoded string', () {
    final offenders = <String>[];
    for (final file in files) {
      for (final literal in _literals(file.readAsStringSync())) {
        if (!literal.inLog && _looksUserVisible(literal.text)) {
          offenders.add('${file.path}:${literal.line}: "${literal.text}"');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Put user-visible text in app_en.arb and read it through '
            'AppLocalizations — loc(context) in a widget, '
            'appLocalizationsProvider elsewhere — then translate it in all 26 '
            'locales.');
  });
}
