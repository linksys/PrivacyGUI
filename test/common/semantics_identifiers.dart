import 'package:flutter_test/flutter_test.dart';

/// Each of [ids] with the number of semantics nodes that carry it as their
/// identifier: an E2E test needs exactly one (constitution 11.3).
///
/// Semantics must be on: call it after `tester.ensureSemantics()` and before
/// that handle's `dispose()`, which has to come before any `expect`.
Map<String, int> identifierCounts(List<String> ids) => {
      for (final id in ids) id: find.bySemanticsIdentifier(id).evaluate().length
    };
