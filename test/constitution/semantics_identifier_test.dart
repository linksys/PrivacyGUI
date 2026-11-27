import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_identifier.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('an identifier on a button node reaches the DOM', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Semantics(
        container: true,
        identifier: 'foo-add',
        child: IconButton(icon: const Icon(Icons.add), onPressed: () {}),
      ),
    );

    expect(identifierProblem(tester, 'foo-add'), isNull);
    semantics.dispose();
  });

  testWidgets('an identifier no node has is a problem', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      IconButton(icon: const Icon(Icons.add), onPressed: () {}),
    );

    expect(identifierProblem(tester, 'foo-add'), 'no node has it');
    semantics.dispose();
  });

  testWidgets(
      'a container wrapper alone merges into the text field node, which the '
      'web engine drops', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Semantics(
        container: true,
        identifier: 'foo-name',
        child: const TextField(),
      ),
    );

    expect(identifierProblem(tester, 'foo-name'),
        'it is on a text field node, which the 3.27.2 web engine drops');
    semantics.dispose();
  });

  testWidgets(
      'a wrapper with explicitChildNodes keeps the text field a child, so its '
      'identifier reaches the DOM', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Semantics(
        container: true,
        explicitChildNodes: true,
        identifier: 'foo-name',
        child: const TextField(),
      ),
    );

    expect(identifierProblem(tester, 'foo-name'), isNull);
    semantics.dispose();
  });

  testWidgets('an identifier on two nodes is a problem', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Column(children: [
        for (final label in ['A', 'B'])
          Semantics(
            container: true,
            identifier: 'foo-rule',
            child: TextButton(onPressed: () {}, child: Text(label)),
          ),
      ]),
    );

    expect(identifierProblem(tester, 'foo-rule'), '2 nodes have it');
    semantics.dispose();
  });

  testWidgets(
      'an identifier merged into a node that has another one is a problem',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      MergeSemantics(
        child: Column(children: [
          Semantics(
              container: true, identifier: 'foo-a', child: const Text('A')),
          Semantics(
              container: true, identifier: 'foo-b', child: const Text('B')),
        ]),
      ),
    );

    expect(identifierProblem(tester, 'foo-a'), isNull);
    expect(identifierProblem(tester, 'foo-b'),
        'it merges into a node whose identifier is foo-a');
    semantics.dispose();
  });

  // The 3.27.2 engine drops the identifier on its text field role only. Its
  // heading, image, slider and route roles add behaviours, so update() goes on
  // to write it (constitution 11.4).
  testWidgets('a heading and a slider node keep their identifiers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Column(children: [
        Semantics(
          container: true,
          headingLevel: 1,
          identifier: 'foo-title',
          child: const Text('Title'),
        ),
        Semantics(
          container: true,
          identifier: 'foo-volume',
          child: Slider(value: 0.5, onChanged: (_) {}),
        ),
      ]),
    );

    expect(identifierProblem(tester, 'foo-title'), isNull);
    expect(identifierProblem(tester, 'foo-volume'), isNull);
    semantics.dispose();
  });

  testWidgets(
      'a text field that is also a heading gets the heading role, which the '
      'engine checks first', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Semantics(
        container: true,
        headingLevel: 2,
        textField: true,
        identifier: 'foo-heading-field',
        child: const SizedBox(width: 10, height: 10),
      ),
    );

    expect(identifierProblem(tester, 'foo-heading-field'), isNull);
    semantics.dispose();
  });
}
