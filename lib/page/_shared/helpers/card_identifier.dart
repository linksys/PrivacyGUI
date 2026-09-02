/// The E2E `identifier`s a dashboard card publishes: its entry into its detail
/// page — the `View details` / `View all` button — and, for a card degraded to the
/// popup form, the tile that opens it (#1450, unblocks PrivacyGUI-USP-E2E#115).
///
/// Pure and in its own library per constitution Article XVI §16.3, which requires
/// a per-instance key's derivation to be a pure, unit-tested function. What needs
/// a `BuildContext` — finding out which card the widget is standing in — is
/// `cardDetailLink` in `dashboard_card_template.dart`.
///
/// ## The prefix is spelled at the call site, and that is not a style choice
///
/// `PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` harvests hooks out of the app's
/// Dart **source text**, not out of its behaviour:
///
/// ```js
/// new RegExp(`(?:identifier|startIdentifier|…):\\s*'([^']+)'`, 'g')
/// ```
///
/// A single-quoted literal directly after `identifier:`, and nothing else. A
/// `prefix-${expr}` template becomes a builder in `identifiers.generated.ts`
/// (`idFor.cardDetail('wifi-status')`); a value arriving from a helper call, a
/// ternary or a `switch` is **invisible**. Nothing fails: the app renders the hook,
/// `find.bySemanticsIdentifier` finds it in a widget test, the generator emits
/// nothing, and the gap surfaces one repo away as a count-0 timeout that reads like
/// a flake. Measured on this branch — `topology-node-slave-${…}`, composed inside
/// `topology/helpers/node_identifier.dart`, is absent from the committed snapshot,
/// and `e2e/tests/P15-topology.spec.ts` records the consequence as a deferred test.
/// `devices/views/components/usp_device_list_tile.dart` documents the same trap and
/// suppresses an analyzer lint rather than lose the shape.
///
/// So this library exports the **key** and not the whole identifier: each hook is
/// written inline at its own attribute site as
/// `identifier: 'card-detail-${cardIdentifierKey(cardId)}'`, which the generator
/// harvests, while the part that needs a rule — snake to kebab — stays here, pure
/// and unit-tested. [kCardDetailIdentifierPrefix] and [kCardPopupIdentifierPrefix]
/// are the strings those templates must spell, and
/// `test/page/_shared/helpers/card_identifier_harvest_test.dart` re-runs the
/// generator's own extraction over `lib/` to prove they do.
library;

/// The shape the E2E identifier generator accepts.
///
/// `gen-identifiers.mts` STATIC_RE — all-lowercase kebab, at least two segments —
/// and anything else is **silently dropped** rather than reported (its DYNAMIC_RE
/// is the same alphabet with the interpolation at the end). Restated here, and
/// asserted below on every composed hook, because a hook that does not match is
/// indistinguishable from a hook that was never added. The same reasoning is
/// written out at `_connectionTypeSlug` in `usp_ipv4_section.dart`, which is where
/// this trap was first paid for.
final RegExp kE2eIdentifierPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)+$');

/// Prefix every card's detail-entry hook carries, per §16.3's
/// `{page-or-feature}-{control}[-{instance-key}]`: feature `card`, control
/// `detail`, instance the card's registry id.
///
/// Read by tests, not by the widgets: a call site has to spell it as a literal to
/// be harvested (see the library header), so this constant is the declaration those
/// literals are checked against rather than the thing they interpolate.
const String kCardDetailIdentifierPrefix = 'card-detail-';

/// Prefix every popup tile's hook carries: feature `card`, control `popup`,
/// instance the card's registry id.
///
/// `popup` and not `tile`, because that is the vocabulary the code is written in —
/// `CardPopupForm`, `CardDensity.popup`, `selectableForms` — and a slug is read
/// alongside the widget it names. "Tile" appears only in prose.
///
/// ## Why the tile needs a handle of its own
///
/// It is a real control: the *whole card* is the tap target (`AppCard(onTap:)`, so
/// ui_kit gives it a `button: true` semantics node), and it is the only way to
/// reach the presentation. A card in this form shows no footer, so for the thirteen
/// cards with a detail entry the presentation holds the **only** copy of that
/// button — the detail hook is unreachable without this one. For the four cards
/// with no detail entry it is stronger still: the presentation is the only place
/// their content can be read at all when degraded.
///
/// Before this, the tile's sole handle was `AppCard.semanticLabel` — the localized
/// `'$title, $value'`, which is precisely the locator Article XVI §16.1 exists to
/// replace, and which additionally moves with the card's data.
///
/// ## A second prefix rather than a suffix on the first
///
/// The tile and the detail button are two different controls on two different
/// surfaces, and §16.3's shape is `{feature}-{control}[-{instance}]` — `popup` and
/// `detail` are the controls. It also keeps the two families disjoint by
/// construction, which the unit test pins: no card's tile can ever answer to
/// another card's detail hook.
const String kCardPopupIdentifierPrefix = 'card-popup-';

/// The instance key a card contributes to both of its hooks: its registry id, in
/// kebab.
///
/// ## Why the card's id and not its route
///
/// The obvious derivation, the card's `detailRoute` (which is what #1450 proposed),
/// is not unique: `wifi_status` and `wifi_networks` both enter `uspWifiSettings`,
/// and `system_status` and `traffic_analysis` both enter `uspStatistics` (differing
/// only in a `tab` query parameter), so four of the thirteen buttons would share a
/// handle with another card — the very defect #1450 exists to remove. Registry ids
/// are unique by construction: they are the switch arms of
/// `UspWidgetFactory._buildCard`.
///
/// ## Underscores become hyphens
///
/// Registry ids are `snake_case` (`wifi_status`); identifiers are kebab
/// ([kE2eIdentifierPattern], and §16.3). That is the whole transform, and it is
/// only sufficient while ids stay lowercase and alphanumeric — hence the assert,
/// which checks the *composed* hook rather than the key: the key alone can look
/// fine (`wifiStatus`) and still produce an identifier the generator drops. Debug
/// only, but every card widget test runs in debug, so a registry id that broke the
/// contract fails here rather than one repo away.
String cardIdentifierKey(String cardId) {
  final key = cardId.replaceAll('_', '-');
  assert(
    kE2eIdentifierPattern.hasMatch('$kCardDetailIdentifierPrefix$key'),
    'card id "$cardId" derives the key "$key", so its hooks would be '
    '"$kCardDetailIdentifierPrefix$key" / "$kCardPopupIdentifierPrefix$key" — '
    'shapes gen-identifiers.mts silently drops. An uppercase letter or a '
    'non-alphanumeric character in the registry id is the usual cause.',
  );
  return key;
}
