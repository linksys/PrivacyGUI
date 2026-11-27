import 'package:test/test.dart';

import 'identifier_scanner.dart';

const _view = 'lib/page/foo/views/foo_view.dart';

void main() {
  group('App* calls', () {
    test('an App* call with onTap and no identifier is a violation', () {
      final violations = findHookViolations({
        _view: 'Widget build() =>\n'
            "    AppTextButton('Save', onTap: _save);\n",
      });

      expect(violations, [
        (
          path: _view,
          line: 2,
          what: 'AppTextButton has onTap and no identifier'
        ),
      ]);
    });

    test('an App* call with an identifier is not a violation', () {
      final violations = findHookViolations({
        _view: "final save = AppTextButton('Save',\n"
            "    identifier: 'foo-save', onTap: _save);\n",
      });

      expect(violations, isEmpty);
    });

    test('an App* call without a callback is not a violation', () {
      final violations = findHookViolations({
        _view: "final title = AppText('Title', maxLines: 1);\n",
      });

      expect(violations, isEmpty);
    });

    test('a callback that is the literal null is not an interaction', () {
      final violations = findHookViolations({
        _view: "final card = AppCard(onTap: null, child: AppText('Title'));\n",
      });

      expect(violations, isEmpty);
    });

    test('a call to a class outside App* is not checked', () {
      final violations = findHookViolations({
        _view: "final a = TextButton(onPressed: _save, child: Text('Save'));\n"
            'final b = AppsGamingSettingsView(onTap: _open);\n'
            'final c = apply(onTap: _open);\n',
      });

      expect(violations, isEmpty);
    });

    test('a named constructor is checked', () {
      final violations = findHookViolations({
        _view: "final save = AppTextButton.noPadding('Save', onTap: _save);\n",
      });

      expect(violations, [
        (
          path: _view,
          line: 1,
          what: 'AppTextButton.noPadding has onTap and no identifier',
        ),
      ]);
    });

    test('a const or new call is checked', () {
      final violations = findHookViolations({
        _view: 'final a = const AppSwitch(value: true, onChanged: _toggle);\n'
            'final b = new AppIconButton.noPadding(onTap: _add);\n',
      });

      expect(violations, [
        (
          path: _view,
          line: 1,
          what: 'AppSwitch has onChanged and no identifier'
        ),
        (
          path: _view,
          line: 2,
          what: 'AppIconButton.noPadding has onTap and no identifier',
        ),
      ]);
    });

    test('a file outside lib/page/ is not checked', () {
      final violations = findHookViolations({
        'lib/route/foo.dart':
            "final save = AppTextButton('Save', onTap: _save);\n",
      });

      expect(violations, isEmpty);
    });

    test(
        'a Semantics identifier around an App* call does not count: the '
        'component forwards it (constitution 11.1.2)', () {
      final violations = findHookViolations({
        _view: 'final toggle = Semantics(\n'
            '  container: true,\n'
            "  identifier: 'foo-enabled',\n"
            '  child: AppSwitch(value: true, onChanged: _toggle),\n'
            ');\n',
      });

      expect(violations, [
        (
          path: _view,
          line: 4,
          what: 'AppSwitch has onChanged and no identifier'
        ),
      ]);
    });

    test('calls in comments and strings are not checked', () {
      final violations = findHookViolations({
        _view: "// AppTextButton('Save', onTap: _save);\n"
            "/* AppCard(onTap: _open) */\n"
            "final help = \"AppTextButton('Save', onTap: _save)\";\n",
      });

      expect(violations, isEmpty);
    });
  });

  group('identifier literals', () {
    test('an identifier that starts with now- is a violation', () {
      final violations = findHookViolations({
        _view:
            "final banner = Semantics(identifier: 'now-read-only-banner');\n",
      });

      expect(violations, [
        (
          path: _view,
          line: 1,
          what: "identifier 'now-read-only-banner' starts with now-",
        ),
      ]);
    });

    for (final id in [
      'Foo-save',
      'foo_save',
      'foo save',
      'foo--save',
      'foo-'
    ]) {
      test('the identifier $id is not kebab-case', () {
        final violations = findHookViolations({
          _view: "final save = AppTextButton('Save', identifier: '$id');\n",
        });

        expect(violations, [
          (path: _view, line: 1, what: "identifier '$id' is not kebab-case"),
        ]);
      });
    }

    test('an interpolation is checked with its expressions as words', () {
      final violations = findHookViolations({
        _view: "final a = Semantics(identifier: 'pf-edit-\${rule.key}');\n"
            "final b = Semantics(identifier: '\$id-octet-\$index');\n"
            "final c = Semantics(identifier: 'now-menu-\${title.kebab()}');\n"
            "final d = Semantics(identifier: 'pf_edit_\${rule.key}');\n",
      });

      expect(violations, [
        (
          path: _view,
          line: 3,
          what: r"identifier 'now-menu-${title.kebab()}' starts with now-",
        ),
        (
          path: _view,
          line: 4,
          what: r"identifier 'pf_edit_${rule.key}' is not kebab-case",
        ),
      ]);
    });

    test('an identifier that is not a literal is not checked', () {
      final violations = findHookViolations({
        _view: 'final a = Semantics(identifier: widget.identifier);\n',
      });

      expect(violations, isEmpty);
    });

    test("a bottom bar's own identifiers are checked too", () {
      final violations = findHookViolations({
        _view: 'final bar = PageBottomBar(\n'
            '  isPositiveEnabled: true,\n'
            '  positiveLabel: loc(context).testAgain,\n'
            "  positiveIdentifier: 'now-speed-test-again',\n"
            '  negitiveLable: loc(context).delete,\n'
            "  negativeIdentifier: 'Delete',\n"
            '  onPositiveTap: _test,\n'
            ');\n',
      });

      expect(violations, [
        (
          path: _view,
          line: 4,
          what: "positiveIdentifier 'now-speed-test-again' starts with now-",
        ),
        (
          path: _view,
          line: 6,
          what: "negativeIdentifier 'Delete' is not kebab-case",
        ),
      ]);
    });
  });

  group('bottom bars', () {
    test(
        'a positive label other than save without an identifier is a violation',
        () {
      final violations = findHookViolations({
        _view: 'final bar = PageBottomBar(\n'
            '  isPositiveEnabled: true,\n'
            '  positiveLabel: loc(context).testAgain,\n'
            '  onPositiveTap: _test,\n'
            ');\n',
      });

      expect(violations, [
        (
          path: _view,
          line: 3,
          what: 'PageBottomBar has positiveLabel loc(context).testAgain and no '
              'positiveIdentifier',
        ),
      ]);
    });

    test('the default labels, or an identifier of its own, are not violations',
        () {
      final violations = findHookViolations({
        _view: 'final a = PageBottomBar(\n'
            '  isPositiveEnabled: true,\n'
            '  positiveLabel: loc(context).save,\n'
            '  negitiveLable: loc(context).cancel,\n'
            '  onPositiveTap: _save,\n'
            ');\n'
            'final b = PageBottomBar(\n'
            '  isPositiveEnabled: true,\n'
            '  positiveLabel: loc(context).testAgain,\n'
            "  positiveIdentifier: 'speed-test-again',\n"
            '  negitiveLable: loc(context).delete,\n'
            "  negativeIdentifier: 'dhcp-reservation-delete',\n"
            '  onPositiveTap: _test,\n'
            ');\n'
            'final c = PageBottomBar(isPositiveEnabled: true, onPositiveTap: _save);\n',
      });

      expect(violations, isEmpty);
    });

    test(
        'a negative label other than cancel without an identifier is a '
        'violation, on an InversePageBottomBar too', () {
      final violations = findHookViolations({
        _view: 'final bar = InversePageBottomBar(\n'
            '  isPositiveEnabled: true,\n'
            '  onPositiveTap: _save,\n'
            '  negitiveLable: loc(context).delete,\n'
            ');\n',
      });

      expect(violations, [
        (
          path: _view,
          line: 4,
          what:
              'InversePageBottomBar has negitiveLable loc(context).delete and '
              'no negativeIdentifier',
        ),
      ]);
    });
  });

  group('literal semantic labels', () {
    test('a literal semanticLabel anywhere in lib/ is a finding', () {
      final findings = findLiteralSemanticLabels({
        _view: "final a = AppSwitch(semanticLabel: 'upnp', value: true);\n"
            "final b = AppIconButton(semanticLabel: 'rule \$index');\n",
        'lib/core/foo.dart': "final c = AppText('x', semanticLabel: 'x');\n",
      });

      expect(findings, [
        (path: _view, line: 1, what: "semanticLabel 'upnp' is a literal"),
        (
          path: _view,
          line: 2,
          what: r"semanticLabel 'rule $index' is a literal"
        ),
        (
          path: 'lib/core/foo.dart',
          line: 1,
          what: "semanticLabel 'x' is a literal"
        ),
      ]);
    });

    test('a semanticLabel from the ARB files is not a finding', () {
      final findings = findLiteralSemanticLabels({
        _view: 'final a = AppSwitch(semanticLabel: loc(context).upnp);\n'
            '// AppSwitch(semanticLabel: "upnp");\n',
      });

      expect(findings, isEmpty);
    });

    test('each literal that a conditional or ?? can give is a finding', () {
      final findings = findLiteralSemanticLabels({
        _view: 'final a = AppSwitch(\n'
            "    semanticLabel: done ? 'checked circle' : 'circle');\n"
            "final b = AppTextField(semanticLabel: widget.label ?? ('wifi name'));\n"
            "final c = AppText('x', semanticLabel: loc(context).nRules('3'));\n",
      });

      expect(findings, [
        (
          path: _view,
          line: 2,
          what: "semanticLabel 'checked circle' is a literal",
        ),
        (path: _view, line: 2, what: "semanticLabel 'circle' is a literal"),
        (path: _view, line: 3, what: "semanticLabel 'wifi name' is a literal"),
      ]);
    });
  });

  group('widget classes', () {
    const widgets = 'plugins/widgets/lib/widgets';

    test('a public class that extends one of the bases is a widget', () {
      final classes = widgetClassesIn({
        '$widgets/a.dart': 'class AppA extends StatelessWidget {}\n'
            'class AppB extends StatefulWidget {}\n'
            'class AppChip extends Chip {}\n',
      }, bases: {
        'StatelessWidget',
        'StatefulWidget',
        'Chip',
      });

      expect(classes, {'AppA', 'AppB', 'AppChip'});
    });

    test('a class that extends another widget of the sources is a widget', () {
      final classes = widgetClassesIn({
        '$widgets/a.dart': 'class AppBase extends StatelessWidget {}\n',
        // Declared before its superclass's file is read, and generic.
        '$widgets/0.dart': 'class AppChild<T> extends AppBase {}\n'
            'class AppGrandchild extends AppChild<int> {}\n',
      }, bases: {
        'StatelessWidget'
      });

      expect(classes, {'AppBase', 'AppChild', 'AppGrandchild'});
    });

    test('a mixin application of a widget is a widget', () {
      final classes = widgetClassesIn({
        '$widgets/a.dart': 'class AppMixed = StatelessWidget with AppMixin;\n'
            'class AppMixedChild extends AppMixed {}\n'
            'class AppPlain = Object with AppMixin;\n',
      }, bases: {
        'StatelessWidget'
      });

      expect(classes, {'AppMixed', 'AppMixedChild'});
    });

    test('without bases, a widget is a class that extends Widget', () {
      final classes = widgetClassesIn({
        'flutter/framework.dart':
            'abstract class StatelessWidget extends Widget {}\n',
        'flutter/text.dart': 'class Text extends StatelessWidget {}\n'
            'class TextStyle with Diagnosticable {}\n',
      });

      expect(classes, {'StatelessWidget', 'Text'});
    });

    test('a private class, a State and a plain class are not widgets', () {
      final classes = widgetClassesIn({
        '$widgets/a.dart': 'class _AppHidden extends StatelessWidget {}\n'
            'class AppState extends State<AppA> {}\n'
            'class AppData extends Equatable {}\n'
            'class AppController {}\n'
            'class AppPainter extends CustomPainter {}\n',
      }, bases: {
        'StatelessWidget'
      });

      expect(classes, isEmpty);
    });

    test('a part file is read like any other file', () {
      final classes = widgetClassesIn({
        '$widgets/button.dart': "part 'text_button.dart';\n",
        '$widgets/text_button.dart': "part of 'button.dart';\n"
            'class AppTextButton extends StatelessWidget {}\n',
      }, bases: {
        'StatelessWidget'
      });

      expect(classes, {'AppTextButton'});
    });

    test("the Flutter SDK's widgets include its concrete widgets", () {
      final classes = flutterWidgetClasses();

      expect(
          classes,
          containsAll([
            'StatelessWidget',
            'StatefulWidget',
            'SingleChildRenderObjectWidget',
            'Chip',
            'AppBar',
            'CupertinoButton',
          ]));
      // A class that extends another class, but not a widget.
      expect(classes, isNot(contains('TextEditingController')));
    });
  });

  test('findings count per file, the way the tables list them', () {
    final counts = countsByFile([
      (path: 'lib/page/a.dart', line: 3, what: 'x'),
      (path: 'lib/page/b.dart', line: 1, what: 'x'),
      (path: 'lib/page/a.dart', line: 9, what: 'y'),
    ]);

    expect(counts, {'lib/page/a.dart -> 2', 'lib/page/b.dart -> 1'});
  });

  test('the findings behind table entries are listed by file and line', () {
    final listing = describeFindings([
      (path: 'lib/page/a.dart', line: 9, what: 'y'),
      (path: 'lib/page/b.dart', line: 1, what: 'x'),
      (path: 'lib/page/a.dart', line: 3, what: 'x'),
    ], {
      'lib/page/a.dart -> 2',
    });

    expect(
        listing,
        'The findings in those files:\n'
        '  - lib/page/a.dart:3: x\n'
        '  - lib/page/a.dart:9: y');
  });
}
