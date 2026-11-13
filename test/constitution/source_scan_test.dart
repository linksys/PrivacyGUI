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

    test('missing markers fail', () {
      expect(
        () => readExceptionTable('| `lib/a.dart` | `lib/b.dart` |\n', 't'),
        throwsStateError,
      );
    });
  });
}
