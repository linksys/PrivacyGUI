import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';

/// The overflow gate's **second data profile** and the cards it is swept on
/// (#1267).
///
/// ## The hole this closes
///
/// The gate sweeps 26 locales × every width realization × every tab — 1644 cases
/// — against exactly one router shape, because `kitchenSinkOverrides()` hardcodes
/// every fixture. Width and locale were the swept dimensions; **data was fixed**.
/// So every "clean" verdict was a verdict about `testRadios` (two radios, 2-digit
/// channels, `160MHz`), and the sweep's own thoroughness made it read as broader
/// than it was.
///
/// #1266 walked into that twice in one change: the WiFi Performance Channels tab
/// came out clean in all 26 locales at both widths, and overflowed on a tri-band
/// router the harness had no way to express (`+9.0px bottom`, `tr` @261px), found
/// only by hand-editing the fixture and reverting.
///
/// ## Why opt-in per card, and what it costs
///
/// #1267 offered three sweep shapes. This is option 1 — a per-card opt-in list —
/// chosen for what it does to the **ratchet**:
///
///  - Sweeping a second profile across all 18 cards doubles 1644 cases and
///    surfaces coordinates in cards nobody has examined. The ratchet's contract
///    (design §2.9) is that the allowlist count only ever *falls*; a mechanism
///    whose first act is to add a dozen entries reads as a mass regression and
///    devalues every landed ticket's "N coordinates cleared" claim.
///  - Option 3 (all cards, one allowlist) is that failure without even a key to
///    separate the profiles by. Option 2 (all cards, per-profile allowlist) is
///    the honest full-coverage answer, and is what this should grow into — but
///    the growth belongs to the ticket that measures each card, not to the one
///    that builds the mechanism.
///
/// The cost is stated plainly because it is real: **a card is only covered on the
/// second profile once someone adds it here.** This list is not a claim about the
/// other 17 cards. What #1267 makes possible is measuring them; measuring them is
/// separate work that will add coordinates.
///
/// Non-default profiles used to get their own allowlist keys
/// (`card|width|tab@profile`), which kept the default profile's arithmetic — the
/// number every closed ticket in this epic quotes — untouched by anything here.
/// **#1341 re-keyed the allowlist on the overflow's `file:line`**, and a source
/// location has no profile axis, so an exemption earned here now covers that same
/// location on the default data too. The cell ids the profile sweep records
/// (`OverflowCell`) still carry `profile`, so the *dataset* keeps the two apart;
/// it is only exemptions that no longer separate. Nothing is in fact widened
/// today — the allowlist is empty — and `dashboard_card_overflow_test.dart`'s
/// profile-sweep header states the trade in full.
class CardDataProfile {
  /// Short key used in test names and in the baseline dataset's cell ids. Must be
  /// stable: renaming it reads as every cell of this profile disappearing and a
  /// new profile's cells appearing. Since #1341 it is *not* part of an allowlist
  /// key — those are `file:line`.
  final String key;

  /// What varies from the default fixtures, for the failure message.
  final String description;

  /// Overrides layered *after* `kitchenSinkOverrides()`, so a provider named in
  /// both resolves to this one (Riverpod is last-wins).
  final List<Override> Function() overrides;

  /// Substrings that must appear in the rendered card when this profile is in
  /// effect — locale-independent, so one `en` pump can check them.
  ///
  /// This exists because the failure mode of a data profile is **silence**. There
  /// are two `testWifiData` fixtures in the repo (the dashboard's and
  /// `statistics_test_data.dart`'s), and more than one provider a card's data can
  /// arrive through; override the wrong one and every case in the sweep pumps the
  /// default fixture, reports green, and reads as 52 extra cases of coverage that
  /// were never measured. A green profile sweep is only evidence if the profile
  /// reached the tree, so that is asserted rather than assumed (#1267).
  final List<String> markers;

  const CardDataProfile({
    required this.key,
    required this.description,
    required this.overrides,
    required this.markers,
  });
}

/// One extra sweep: a card, the tabs worth sweeping, and the profile to sweep.
class CardDataProfileSweep {
  final String cardId;

  /// The tabs this profile can change. Deliberately not "all tabs": a profile
  /// that only varies the radio list cannot change a tab that renders clients,
  /// and 26 locales × every width × every tab is not a cost to pay for cases
  /// that are byte-identical to the default profile's.
  final List<int> tabs;

  final CardDataProfile profile;

  const CardDataProfileSweep({
    required this.cardId,
    required this.tabs,
    required this.profile,
  });
}

/// The tri-band profile: [testWifiDataTriBand] in place of `testWifiData`.
final triBandProfile = CardDataProfile(
  key: 'triband',
  description: '3 radios, 3-digit auto channel, 320MHz '
      '(testWifiDataTriBand)',
  overrides: () => cardOverrides(wifiData: testWifiDataTriBand),
  // The third radio's channel string, which only this profile can produce:
  // `channelDisplay` appends ` (Auto)` unlocalized, and no default fixture has a
  // 320MHz radio. Both halves are checked because either alone could survive a
  // partially-applied override.
  markers: const ['233 (Auto)', '320MHz'],
);

/// Six radios: the load the Channels tab's scroll net is measured under, and the
/// one profile here the gate deliberately does **not** sweep.
///
/// #1267 gave that tab a scrolling content region so content taller than the card
/// has somewhere to go. Once the band-distribution donut was removed, no realistic
/// fixture in the repo is tall enough to exercise it — [triBandProfile] fits with
/// ~120px to spare — so the mechanism would have shipped untested. This supplies
/// the load; see [testRadiosSixRadio] for why six and not five, and why a router
/// nobody sells is the honest fixture for a net rather than for a sweep.
///
/// Keeping it out of [kCardDataProfileSweeps] is the same ratchet argument the
/// class doc makes: coordinates recorded against imaginary hardware become
/// allowlist entries no ticket can ever clear.
final sixRadioProfile = CardDataProfile(
  key: 'sixradio',
  description: '6 radios — taller than the card at any supported width '
      '(testWifiDataSixRadio)',
  overrides: () => cardOverrides(wifiData: testWifiDataSixRadio),
  // The fifth radio's channel, which no other profile produces.
  markers: const ['197 (Auto)'],
);

/// Every non-default sweep the gate runs.
///
/// `wifi_performance` tab 2 (Channels) is the one entry, and it is the case
/// #1267 exists for. Tabs 0 and 1 (Signal, Speed) render *clients*, which this
/// profile does not touch — their trees are identical to the default profile's,
/// so sweeping them would buy 52 duplicate cases per width.
final kCardDataProfileSweeps = <CardDataProfileSweep>[
  CardDataProfileSweep(
    cardId: 'wifi_performance',
    tabs: const [2],
    profile: triBandProfile,
  ),
];
