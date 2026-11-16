import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The PnP wizard's step hooks — the footer's four and Your Network's "Add
/// nodes" — stay where the E2E repo can harvest them (Art. XVI §16.4).
///
/// `PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` builds the specs' identifier
/// map from this app's Dart *text*: only a single-quoted literal directly after
/// `identifier:` is captured, and anything else is skipped without a word. A
/// footer that picked its hook into a variable and passed `identifier: id`
/// renders and passes every widget test here while its hooks vanish from the
/// map — #1511 P5's review fixes did exactly that and were caught by reading,
/// not by a test. This is that test. "Add nodes" passed a `const` the same way
/// from #1734 until the #1816 review.
void main() {
  /// The literals after `identifier:` in [path], and whether any
  /// `identifier:` there is followed by something else — a variable, a call or
  /// an expression, not a comment's backtick.
  (Set<String?>, bool) hooksIn(String path) {
    final source = File(path).readAsStringSync();
    return (
      RegExp(r"identifier:\s*'([a-z0-9-]+)'")
          .allMatches(source)
          .map((m) => m.group(1))
          .toSet(),
      RegExp(r'identifier:\s*[A-Za-z_$(]').hasMatch(source),
    );
  }

  const notALiteral = 'an identifier: that is not a literal is skipped by the '
      'E2E generator';

  test('every footer hook is a literal at its identifier: site', () {
    final (harvested, other) =
        hooksIn('lib/page/instant_setup/views/components/pnp_step_footer.dart');

    expect(harvested, {
      'pnp-step-back',
      'pnp-step-next',
      'pnp-step-save',
      'pnp-step-done',
    });
    expect(other, isFalse, reason: notALiteral);
  });

  test('Your Network\'s add-nodes hook is a literal at its identifier: site',
      () {
    final (harvested, other) =
        hooksIn('lib/page/instant_setup/views/pnp_your_network_step_view.dart');

    expect(harvested, {'pnp-add-nodes'});
    expect(other, isFalse, reason: notALiteral);
  });
}
