import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/helpers/card_identifier.dart';

/// The half of the #1450 contract no runtime test can see: that the card hooks are
/// written in `lib/` in a shape the E2E identifier generator **harvests**.
///
/// ## Why a source scan
///
/// `PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` builds the specs' typed SSOT
/// (`fixtures/identifiers.generated.ts`) by reading the app's Dart *text* — a
/// single-quoted literal directly after `identifier:`, with `prefix-${expr}`
/// becoming a builder. It never runs the app. So an identifier composed by a helper
/// call, a ternary or a `switch` is invisible to it, and the failure is silent in
/// both directions: the widget renders the hook, `find.bySemanticsIdentifier` finds
/// it, `flutter test` is green — and the generator emits nothing, so the spec that
/// needs the hook cannot import it and E2E stays blocked.
///
/// One mechanism escapes that, by name rather than by shape: `extractIndirectHooks`
/// also scans helper *declarations*, for the hook families listed in its
/// `INDIRECT_HOOK_PREFIXES` allowlist — today `['topology-node-']`, which is what
/// lets `topology-node-slave-$key` reach the specs from inside a function. Nothing
/// in this repo can extend that list; it is the generator's. So for a hook this repo
/// adds, "harvestable" means "spelled inline", and that is the property measured
/// here.
///
/// This file therefore re-runs the generator's own extraction over `lib/` and
/// asserts the two card prefixes come out of it. The regexes below are copies of
/// the generator's, which is the one weakness of the approach — a drift in *its*
/// rules is not visible from this repo. It is still the strongest check available
/// here, and it is what turns "the hook exists" into "the hook is reachable from
/// the other repo".
///
/// Deliberately untagged, so the PR-blocking unit lane runs it.

/// The attributes the generator treats as identifier hooks (IDENTIFIER_ATTRS).
///
/// All six, `itemIdentifier` included. In practice that one is never an inline
/// literal — `AppDropdown` takes a `(item) => …` mapper, which the generator reads
/// in `extractItemIdentifierHooks` instead — so it contributes nothing to the two
/// checks below today. It is listed for the same reason the generator lists it: an
/// inline call site added later is a hook, and a list that quietly disagreed with
/// IDENTIFIER_ATTRS would stop being the generator's own extraction.
const List<String> _identifierAttrs = [
  'identifier',
  'startIdentifier',
  'endIdentifier',
  'positiveIdentifier',
  'negativeIdentifier',
  'itemIdentifier',
];

/// The generator's extraction: an attribute followed by a single-quoted literal.
/// Anything else — a call, a conditional, a variable — is not a hook to it.
final RegExp _hookRe =
    RegExp("(?:${_identifierAttrs.join('|')}):\\s*'([^']+)'");

/// DYNAMIC_RE: a literal prefix, one interpolation, nothing after it.
final RegExp _dynamicRe = RegExp(r'^([a-z0-9-]+-)\$\{[^}]+\}$');

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// The dynamic prefixes the generator would emit as `idFor` builders, mapped to the
/// files that declare them.
final Map<String, Set<String>> _dynamicPrefixes = () {
  final byPrefix = <String, Set<String>>{};
  for (final file in _dartFiles('lib')) {
    for (final m in _hookRe.allMatches(file.readAsStringSync())) {
      final value = m.group(1)!;
      if (!value.contains(r'${')) continue;
      final dynamic_ = _dynamicRe.firstMatch(value);
      if (dynamic_ == null) continue;
      byPrefix
          .putIfAbsent(dynamic_.group(1)!, () => <String>{})
          .add(file.path.replaceAll(r'\', '/'));
    }
  }
  return byPrefix;
}();

void main() {
  test('both card hook prefixes are harvestable out of lib/', () {
    expect(
      _dynamicPrefixes.keys,
      containsAll([kCardDetailIdentifierPrefix, kCardPopupIdentifierPrefix]),
      reason: 'the generator found no such prefix in the app source, so '
          'identifiers.generated.ts would gain no builder for it and no spec '
          'could import the hook — the id has to be spelled inline as '
          "identifier: '$kCardDetailIdentifierPrefix\${…}', not returned by a "
          'helper or chosen by a conditional',
    );
  });

  /// Where each prefix is spelled, and that it is spelled once.
  ///
  /// Once is the point of `cardDetailLink`: a literal cannot express "no card
  /// here", so the null case is a second `Semantics`, and four footers each
  /// carrying that branch is four places to get it wrong. The generator does not
  /// care how many sites there are — this asserts the factoring, so a fifth footer
  /// that copies the branch instead of calling the wrapper is visible here.
  ///
  /// It is also what keeps the test above from passing vacuously, and that is not
  /// hypothetical: the generator scans raw text and does **not** strip comments, so
  /// `card_identifier.dart`'s header — which spells the hook exactly as a call site
  /// must, single quotes and all, precisely so nobody copies an unharvestable
  /// variant out of it — is itself harvested. Deleting the real site would leave
  /// the prefix in the SSOT and the check above green; this one turns two files
  /// into one and fails. (Which is the general hazard: a doc comment can add an
  /// `idFor` builder for a hook the app does not publish, and a spec using it
  /// compiles and then times out.)
  test('each prefix is declared at exactly one site', () {
    expect(
      _dynamicPrefixes[kCardDetailIdentifierPrefix],
      {
        'lib/page/_shared/components/dashboard_card_template.dart',
        'lib/page/_shared/helpers/card_identifier.dart', // the header's example
      },
      reason: 'the detail hook belongs to cardDetailLink, which every footer '
          'goes through',
    );
    expect(
      _dynamicPrefixes[kCardPopupIdentifierPrefix],
      {'lib/page/_shared/components/card_popup_form.dart'},
      reason: 'the tile hook belongs to the tile',
    );
  });

  /// The three cards that hand-roll a footer, because their route needs a query
  /// parameter the template cannot pass. They are the sites most likely to grow a
  /// hook of their own — and a hand-written one would be the unharvestable shape
  /// again, with every runtime test still green.
  test('the hand-rolled footers borrow the shared link', () {
    for (final path in const [
      'lib/page/admin/cards/usp_device_info_card.dart',
      'lib/page/dashboard/views/components/usp_system_status_card.dart',
      'lib/page/dashboard/views/components/usp_traffic_analysis_card.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('cardDetailLink('),
        reason: '$path must reach its hook through the shared wrapper, so that '
            'the one harvestable literal is the one it publishes',
      );
    }
  });

  /// A hook the generator cannot classify is worse than one it drops: `extract()`
  /// **throws** on an interpolated value that is not `prefix-${expr}`, which fails
  /// `npm run gen:ids -- --check` and blocks the whole E2E run rather than one
  /// spec. Swept over every attribute-site hook in `lib/`, not just the card ones,
  /// because the blast radius is the same for all of them and nothing else in this
  /// repo looks.
  ///
  /// Scoped exactly to that one site, and it is one of eight the generator can throw
  /// from: the other seven live in `extractIndirectHooks`, `extractItemIdentifierHooks`
  /// (three, including the enum it cannot enumerate), `enumerateEnum` (two) and the
  /// final identifier/`semanticLabel` collision guard. Reproducing those would mean
  /// reimplementing a helper-declaration scan, a Dart enum parser and a cross-family
  /// collision check from copied regexes — at which point the copy is the risk. What
  /// makes the narrow check worth having anyway is that this is the site every hook
  /// in this PR goes through, and the shape it rejects is the one a hand-written
  /// call site actually produces.
  test('no inline interpolated hook in lib/ would make the generator throw',
      () {
    final unhandled = <String, String>{};
    for (final file in _dartFiles('lib')) {
      for (final m in _hookRe.allMatches(file.readAsStringSync())) {
        final value = m.group(1)!;
        if (!value.contains(r'${')) continue;
        if (!_dynamicRe.hasMatch(value)) unhandled[value] = file.path;
      }
    }
    expect(
      unhandled,
      isEmpty,
      reason: 'gen-identifiers.mts only derives builders for '
          "'prefix-\${expr}' templates (interpolation last, nothing after the "
          'closing brace) and throws on anything else',
    );
  });
}
