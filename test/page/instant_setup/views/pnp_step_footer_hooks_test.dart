import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The PnP step footer's four E2E hooks stay where the E2E repo can harvest
/// them (Art. XVI §16.4).
///
/// `PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` builds the specs' identifier
/// map from this app's Dart *text*: only a single-quoted literal directly after
/// `identifier:` is captured, and anything else is skipped without a word. A
/// footer that picked its hook into a variable and passed `identifier: id`
/// renders and passes every widget test here while its hooks vanish from the
/// map — #1511 P5's review fixes did exactly that and were caught by reading,
/// not by a test. This is that test.
void main() {
  test('every footer hook is a literal at its identifier: site', () {
    final source = File(
      'lib/page/instant_setup/views/components/pnp_step_footer.dart',
    ).readAsStringSync();
    final harvested = RegExp(r"identifier:\s*'([a-z0-9-]+)'")
        .allMatches(source)
        .map((m) => m.group(1))
        .toSet();

    expect(harvested, {
      'pnp-step-back',
      'pnp-step-next',
      'pnp-step-save',
      'pnp-step-done',
    });
    // A variable, a call or an expression after `identifier:` — not a
    // comment's backtick.
    expect(RegExp(r'identifier:\s*[A-Za-z_$(]').hasMatch(source), isFalse,
        reason: 'an identifier: that is not a literal is skipped by the E2E '
            'generator');
  });
}
