import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Why the 1.x web engine would not write [identifier] to the DOM as
/// `flt-semantics-identifier` for what [tester] has pumped, or null when it
/// would (constitution 11.4). Semantics must be on.
String? identifierProblem(WidgetTester tester, String identifier) {
  final finder = find.bySemanticsIdentifier(identifier);
  final count = finder.evaluate().length;
  if (count == 0) return 'no node has it';
  if (count > 1) return '$count nodes have it';
  // The node the engine receives: a node merged into its parent is sent as
  // part of the parent, which getSemantics walks up to.
  final data = tester.getSemantics(finder).getSemanticsData();
  if (data.identifier != identifier) {
    return 'it merges into a node whose identifier is ${data.identifier}';
  }
  if (_isTextField(data)) {
    return 'it is on a text field node, which the 3.27.2 web engine drops';
  }
  return null;
}

/// Whether the 3.27.2 web engine gives [data] its text field role, the one
/// role whose `update()` never writes the identifier: `SemanticTextField`
/// adds no behaviours, so `SemanticRole.update()` returns before it gets to
/// `_updateIdentifier()`. The heading, image, slider and route roles add
/// behaviours and keep it. `_getSemanticRoleKind()` checks a platform view
/// and a heading before a text field.
bool _isTextField(SemanticsData data) =>
    data.platformViewId == null &&
    data.headingLevel == 0 &&
    data.hasFlag(SemanticsFlag.isTextField);
