import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/prompts/router_system_prompt.dart';

/// Guards the A2UI envelope the prompt teaches the model to emit.
///
/// The spec requires `"version":"v0.9"` on every message, and the reference
/// implementation (`a2ui_core`) rejects a message without it rather than
/// defaulting. Our own renderer tolerates its absence, so nothing in the app
/// fails if the prompt stops asking for it — the cost would appear only as a
/// wholesale rejection the first time our output meets a conformant parser.
/// Hence a test rather than a comment.
void main() {
  group('A2UI envelope', () {
    late String prompt;

    setUp(() {
      prompt = RouterSystemPrompt.staticPrompt;
    });

    /// Whole-message example lines, i.e. those carrying a message-type key.
    ///
    /// Component-schema snippets (`{"id":…,"component":…}`) are excluded: they
    /// are entries inside a message's `components` array and correctly carry no
    /// version of their own.
    List<String> messageExamples(String text) {
      const messageKeys = [
        'updateComponents',
        'createSurface',
        'updateDataModel',
        'deleteSurface',
      ];
      return text
          .split('\n')
          .where((l) => l.startsWith('{"'))
          .where((l) => messageKeys.any((k) => l.contains('"$k"')))
          .toList();
    }

    test('every message example carries the protocol version', () {
      final examples = messageExamples(prompt);

      expect(examples, isNotEmpty,
          reason: 'the prompt must show the model what to emit');

      final missing =
          examples.where((l) => !l.startsWith('{"version":"v0.9"')).toList();

      expect(missing, isEmpty,
          reason:
              'a conformant parser rejects a message with no version, so an '
              'example without one teaches output that cannot migrate');
    });

    test('the version requirement is stated, not only demonstrated', () {
      // Models improvise message shapes the examples do not cover, so the rule
      // has to appear as a rule.
      expect(prompt, contains('"version":"v0.9"'));
      expect(prompt, contains('EVERY message'));
    });

    test('each correct-format example stays on one line', () {
      // Pre-existing contract worth pinning here: the version edit rewrote every
      // example line, and a stray newline inside one would break parsing while
      // still looking correct in review.
      //
      // The prompt also contains a deliberately-WRONG multi-line sample, shown
      // so the model can recognise the mistake. Excluded by taking only lines
      // that close their own object — which is exactly the property under test
      // for the rest.
      final wellFormed = messageExamples(prompt)
          .where((l) => l.trimRight().endsWith('}'))
          .toList();

      expect(wellFormed.length, greaterThanOrEqualTo(8),
          reason: 'most examples must be single-line; if this drops, the '
              'exclusion above is hiding a real regression');

      for (final line in wellFormed) {
        expect(RegExp(r'^\{.*\}$').hasMatch(line.trim()), isTrue,
            reason: 'one complete JSON object per line: $line');
      }
    });
  });
}
