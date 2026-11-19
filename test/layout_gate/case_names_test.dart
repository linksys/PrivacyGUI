import 'package:flutter_test/flutter_test.dart';

import '../constitution/source_scan.dart';
import 'case_names.dart';
import 'gate.dart';

void main() {
  group('caseNamesIn', () {
    test('finds the name of every testLocalizations call, in groups too', () {
      const source = '''
void main() {
  testLocalizations('A page - init', (tester, locale) async {});
  group('a group', () {
    testLocalizations("A page - editing", (tester, locale) async {},
        screens: responsiveMobileScreens);
  });
}
''';

      expect(caseNamesIn(source), {'A page - init', 'A page - editing'});
    });

    test('reads a name split over adjacent strings, trailing space included',
        () {
      const source = '''
void main() {
  testLocalizations('A page - '
      'reboot alert ', (tester, locale) async {});
}
''';

      expect(caseNamesIn(source), {'A page - reboot alert '});
    });

    test('ignores other tests and names it cannot read', () {
      const source = r'''
void main() {
  testWidgets('a unit test', (tester) async {});
  for (final mode in modes) {
    testLocalizations('A page - $mode', (tester, locale) async {});
  }
}
''';

      expect(caseNamesIn(source), isEmpty);
    });
  });

  test('every case on the short-viewport list exists', () {
    final names = {
      for (final source in dartSources('test').values) ...caseNamesIn(source),
    };
    final dead = shortViewportSkips.difference(names);

    expect(
      dead,
      isEmpty,
      reason: 'These entries of shortViewportSkips in '
          'test/layout_gate/gate.dart name no testLocalizations case. '
          'Delete them:\n${bulletList(dead)}',
    );
  });
}
