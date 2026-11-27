import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'source_scan.dart';

/// A component the page layer calls: `App` and a capital, so `AppCard` but not
/// `AppsGamingSettingsView`.
final _appComponent = RegExp(r'^App[A-Z]');

/// An interaction callback: any named argument `on…` (constitution 11.2).
final _callback = RegExp(r'^on[A-Z]');

/// An argument that holds an identifier: `identifier`, or one that ends in
/// `Identifier`, such as `PageBottomBar`'s `positiveIdentifier`.
final _identifierArgument = RegExp(r'^(identifier|[a-z]+Identifier)$');

/// Lower-case words and digits joined by single hyphens (constitution 11.3).
final _kebabCase = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Each `PageBottomBar` button: the parameter for its label, the label its
/// default identifier stands for, and the parameter for its own identifier.
/// `negitiveLable` is spelled as `PageBottomBar` spells it.
const _bottomBarButtons = [
  ('positiveLabel', 'loc(context).save', 'positiveIdentifier'),
  ('negitiveLable', 'loc(context).cancel', 'negativeIdentifier'),
];

/// A place in a file that breaks `constitution.md` Article XI, and what it
/// does.
typedef Finding = ({String path, int line, String what});

/// [findings] as the rows of an Article XI table read them: one
/// `<file> -> <count>` per file.
Set<String> countsByFile(Iterable<Finding> findings) {
  final counts = <String, int>{};
  for (final finding in findings) {
    counts.update(finding.path, (count) => count + 1, ifAbsent: () => 1);
  }
  return {
    for (final MapEntry(:key, :value) in counts.entries) '$key -> $value'
  };
}

/// The [findings] in the files that [entries], as [countsByFile] writes them,
/// name, one per line in file and line order, for a failure message.
String describeFindings(Iterable<Finding> findings, Set<String> entries) {
  final files = {for (final entry in entries) entry.split(' -> ').first};
  final lines = [
    for (final finding in findings)
      if (files.contains(finding.path)) finding,
  ]..sort((a, b) =>
      a.path == b.path ? a.line.compareTo(b.line) : a.path.compareTo(b.path));
  return 'The findings in those files:\n'
      '${lines.map((f) => '  - ${f.path}:${f.line}: ${f.what}').join('\n')}';
}

/// Finds the controls under `lib/page/` that break `constitution.md` 11.2 and
/// 11.3.
List<Finding> findHookViolations(Map<String, String> sources) => _scan(
      {
        for (final MapEntry(:key, :value) in sources.entries)
          if (key.startsWith('lib/page/')) key: value,
      },
      _HookVisitor.new,
    );

/// Finds every string literal that a `semanticLabel:` in [sources] can hold
/// (constitution 11.1.3): screen-reader text comes from the ARB files.
List<Finding> findLiteralSemanticLabels(Map<String, String> sources) =>
    _scan(sources, _LabelVisitor.new);

/// The public widget classes that [sources] declare (constitution 11.4): each
/// public class that extends one of [bases], or another widget class of
/// [sources], in whichever file that one is. The default base is `Widget`,
/// which finds the widgets of the Flutter SDK itself.
Set<String> widgetClassesIn(
  Map<String, String> sources, {
  Set<String> bases = const {'Widget'},
}) {
  final superclassOf = <String, String>{
    for (final source in sources.values)
      for (final declaration in parseDart(source).declarations)
        if (declaration is ClassDeclaration &&
            declaration.extendsClause != null)
          declaration.name.lexeme:
              declaration.extendsClause!.superclass.name2.lexeme,
  };
  bool isWidget(String name, Set<String> seen) {
    final superclass = superclassOf[name];
    if (superclass == null || !seen.add(name)) return false;
    return bases.contains(superclass) || isWidget(superclass, seen);
  }

  return {
    for (final name in superclassOf.keys)
      if (!name.startsWith('_') && isWidget(name, {})) name,
  };
}

/// The public widget classes of the Flutter SDK that runs the tests, in its
/// widgets, material and cupertino libraries: the classes that a widget of
/// `plugins/widgets` can extend.
Set<String> flutterWidgetClasses() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    throw StateError('FLUTTER_ROOT is not set. Run the test with `flutter '
        'test`, which sets it to the SDK that runs the test.');
  }
  return widgetClassesIn({
    for (final library in ['widgets', 'material', 'cupertino'])
      ...dartSources('$root/packages/flutter/lib/src/$library'),
  });
}

/// What each visitor that [visitor] makes finds in [sources].
List<Finding> _scan(
  Map<String, String> sources,
  _FindingVisitor Function(String path, LineInfo lineInfo, List<Finding> into)
      visitor,
) {
  final findings = <Finding>[];
  sources.forEach((path, source) {
    final unit = parseDart(source);
    unit.accept(visitor(path, unit.lineInfo, findings));
  });
  return findings;
}

/// The name of a named argument.
String _argumentName(NamedExpression argument) => argument.name.label.name;

/// [literal]'s text, with `x` for each interpolated expression.
String _flatten(StringLiteral literal) => switch (literal) {
      SimpleStringLiteral(:final value) => value,
      StringInterpolation(:final elements) => [
          for (final element in elements)
            element is InterpolationString ? element.value : 'x',
        ].join(),
      AdjacentStrings(:final strings) => strings.map(_flatten).join(),
    };

/// The string literals that [value] can evaluate to: itself, either branch of
/// a conditional, either side of `??`, through parentheses. A literal passed
/// to a call inside [value] is the call's, not [value]'s.
Iterable<StringLiteral> _possibleLiterals(Expression value) sync* {
  switch (value) {
    case StringLiteral():
      yield value;
    case ParenthesizedExpression(:final expression):
      yield* _possibleLiterals(expression);
    case ConditionalExpression(:final thenExpression, :final elseExpression):
      yield* _possibleLiterals(thenExpression);
      yield* _possibleLiterals(elseExpression);
    case BinaryExpression(:final leftOperand, :final rightOperand)
        when value.operator.lexeme == '??':
      yield* _possibleLiterals(leftOperand);
      yield* _possibleLiterals(rightOperand);
  }
}

/// A visitor that adds what it finds in the file at [path] to [findings].
abstract class _FindingVisitor extends RecursiveAstVisitor<void> {
  final String path;
  final LineInfo lineInfo;
  final List<Finding> findings;

  _FindingVisitor(this.path, this.lineInfo, this.findings);

  void add(AstNode at, String what) => findings.add((
        path: path,
        line: lineInfo.getLocation(at.offset).lineNumber,
        what: what,
      ));
}

class _LabelVisitor extends _FindingVisitor {
  _LabelVisitor(super.path, super.lineInfo, super.findings);

  @override
  void visitNamedExpression(NamedExpression node) {
    if (_argumentName(node) == 'semanticLabel') {
      for (final literal in _possibleLiterals(node.expression)) {
        add(literal, 'semanticLabel ${literal.toSource()} is a literal');
      }
    }
    super.visitNamedExpression(node);
  }
}

class _HookVisitor extends _FindingVisitor {
  _HookVisitor(super.path, super.lineInfo, super.findings);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Unresolved, `AppCard(...)` parses as a call of `AppCard`, and
    // `AppTextButton.noPadding(...)` as a call of `noPadding` on
    // `AppTextButton`.
    final target = node.target;
    if (target == null) {
      _checkCall(node.methodName.name, null, node.argumentList, node);
    } else if (target is SimpleIdentifier) {
      _checkCall(target.name, node.methodName.name, node.argumentList, node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Unresolved, `new AppIconButton.noPadding(...)` parses as the type
    // `noPadding` with the prefix `AppIconButton`. A prefix with a capital is
    // a class; an import prefix is lower case.
    final type = node.constructorName.type;
    final prefix = type.importPrefix?.name.lexeme;
    if (prefix != null && _appComponent.hasMatch(prefix)) {
      _checkCall(prefix, type.name2.lexeme, node.argumentList, node);
    } else {
      _checkCall(type.name2.lexeme, node.constructorName.name?.name,
          node.argumentList, node);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    final name = _argumentName(node);
    final value = node.expression;
    if (_identifierArgument.hasMatch(name) && value is StringLiteral) {
      final text = value.toSource();
      final flat = _flatten(value);
      if (flat.startsWith('now-')) {
        add(value, '$name $text starts with now-');
      } else if (!_kebabCase.hasMatch(flat)) {
        add(value, '$name $text is not kebab-case');
      }
    }
    super.visitNamedExpression(node);
  }

  /// Checks a call, at [call], of [className]'s [constructor], or of its
  /// unnamed one.
  void _checkCall(String className, String? constructor,
      ArgumentList argumentList, AstNode call) {
    final named = argumentList.arguments.whereType<NamedExpression>().toList();
    if (className == 'PageBottomBar' || className == 'InversePageBottomBar') {
      _checkBottomBar(className, named);
      return;
    }
    if (!_appComponent.hasMatch(className)) return;
    final callback = named
        .where((argument) =>
            _callback.hasMatch(_argumentName(argument)) &&
            argument.expression is! NullLiteral)
        .firstOrNull;
    final hasIdentifier =
        named.any((argument) => _argumentName(argument) == 'identifier');
    if (callback == null || hasIdentifier) return;
    final name = constructor == null ? className : '$className.$constructor';
    add(call, '$name has ${_argumentName(callback)} and no identifier');
  }

  /// A bottom bar's button keeps its default identifier only with its
  /// default label (constitution 11.2).
  void _checkBottomBar(String className, List<NamedExpression> named) {
    NamedExpression? argument(String name) =>
        named.where((a) => _argumentName(a) == name).firstOrNull;
    for (final (labelName, defaultLabel, identifierName) in _bottomBarButtons) {
      final label = argument(labelName);
      if (label == null) continue;
      final text = label.expression.toSource();
      if (text == defaultLabel || argument(identifierName) != null) continue;
      add(label, '$className has $labelName $text and no $identifierName');
    }
  }
}
