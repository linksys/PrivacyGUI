import 'package:test/test.dart';

import 'source_scan.dart';

String _constitution(String rows) => 'Prose before the table.\n'
    '<!-- t:begin -->\n'
    '| File | Depends on | What it uses |\n'
    '|---|---|---|\n'
    '$rows'
    '<!-- t:end -->\n';

void main() {
  group('readExceptionTable', () {
    test('reads each row as <from> -> <to>', () {
      final rows = readExceptionTable(
        _constitution('| `lib/a.dart` | `lib/b.dart` | |\n'
            '| `lib/a.dart` | `fooProvider` | `bar()` |\n'),
        't',
      );

      expect(rows, {'lib/a.dart -> lib/b.dart', 'lib/a.dart -> fooProvider'});
    });

    test('a row without backticks around its first two cells fails', () {
      expect(
        () => readExceptionTable(
          _constitution('| `lib/a.dart` | `lib/b.dart` | |\n'
              '| lib/c.dart | lib/d.dart | |\n'),
          't',
        ),
        throwsStateError,
      );
    });

    test('two rows for the same <from> -> <to> fail, whatever their reasons',
        () {
      // A merge that keeps both sides of a conflict leaves a row twice, an old
      // and a new reason. Read as a set, the two would pass as one (#1802).
      expect(
        () => readExceptionTable(
          _constitution('| `lib/a.dart` | `lib/b.dart` | old reason |\n'
              '| `lib/c.dart` | `lib/d.dart` | |\n'
              '| `lib/a.dart` | `lib/b.dart` | new reason |\n'),
          't',
        ),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('lib/a.dart -> lib/b.dart'))),
      );
    });

    test('markers that appear twice fail', () {
      expect(
        () => readExceptionTable(
          '<!-- t:begin --> <!-- t:end -->\n'
              '${_constitution('| `lib/a.dart` | `lib/b.dart` | |\n')}',
          't',
        ),
        throwsStateError,
      );
    });

    test('a table without its header row fails', () {
      expect(
        () => readExceptionTable(
          '<!-- t:begin -->\n'
              '|---|---|\n'
              '| `lib/a.dart` | `lib/b.dart` |\n'
              '| `lib/c.dart` | `lib/d.dart` |\n'
              '<!-- t:end -->\n',
          't',
        ),
        throwsStateError,
      );
    });

    test('a table without its separator row fails', () {
      expect(
        () => readExceptionTable(
          '<!-- t:begin -->\n'
              '| File | Depends on |\n'
              '| `lib/a.dart` | `lib/b.dart` |\n'
              '| `lib/c.dart` | `lib/d.dart` |\n'
              '<!-- t:end -->\n',
          't',
        ),
        throwsStateError,
      );
    });

    test('missing markers fail', () {
      expect(
        () => readExceptionTable('| `lib/a.dart` | `lib/b.dart` |\n', 't'),
        throwsStateError,
      );
    });
  });
}
