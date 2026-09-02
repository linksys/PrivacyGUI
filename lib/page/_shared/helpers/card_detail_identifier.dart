/// Pure derivation of the E2E `identifier`s a dashboard card publishes: its entry
/// into its detail page — the `View details` / `View all` button — and, for a card
/// degraded to the popup form, the tile that opens it (#1450, unblocks
/// PrivacyGUI-USP-E2E#115).
///
/// Pure and in its own library per constitution Article XVI §16.3, which requires
/// a per-instance key's derivation helper to be a pure, unit-tested function. The
/// widget-facing wrapper that reads the card id out of the tree lives in
/// `dashboard_card_template.dart`; everything decidable without a `BuildContext`
/// is decided here, so the slug contract can be tested without pumping a widget.
library;

/// Prefix every card's detail-entry hook carries, per §16.3's
/// `{page-or-feature}-{control}[-{instance-key}]`: feature `card`, control
/// `detail`, instance the card's registry id.
const String kCardDetailIdentifierPrefix = 'card-detail-';

/// The shape the E2E identifier generator accepts.
///
/// `PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` STATIC_RE — all-lowercase
/// kebab, at least two segments — and anything else is **silently dropped** from
/// `identifiers.generated.ts` rather than reported. Restated here (and asserted
/// over every registry id in this helper's unit test) because a hook that does
/// not match is indistinguishable from a hook that was never added: the app looks
/// correct, the generator emits nothing, and the gap surfaces one repo away. The
/// same reasoning is written out at `_connectionTypeSlug` in
/// `usp_ipv4_section.dart`, which is where this trap was first paid for.
final RegExp kE2eIdentifierPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)+$');

/// Composes the detail-entry hook for the card registered as [cardId].
///
/// ## Why the card's id and not its route
///
/// The obvious derivation, the card's `detailRoute`, is not unique: `wifi_status`
/// and `wifi_networks` both enter `uspWifiSettings`, and `system_status` and
/// `traffic_analysis` both enter `uspStatistics` (differing only in a `tab`
/// query parameter), so four of the thirteen buttons would share a handle with
/// another card — the very defect #1450 exists to remove. Registry ids are unique
/// by construction: they are the switch arms of `UspWidgetFactory._buildCard`.
///
/// ## Underscores become hyphens
///
/// Registry ids are `snake_case` (`wifi_status`); identifiers are kebab
/// ([kE2eIdentifierPattern], and §16.3). This is the whole transform, and it is
/// only sufficient while ids stay lowercase and alphanumeric — which is why the
/// unit test asserts the *result* for every registered card against the
/// generator's pattern rather than trusting that they do. An id that broke the
/// pattern would otherwise ship a hook the generator drops in silence.
String cardDetailIdentifierFor(String cardId) =>
    '$kCardDetailIdentifierPrefix${_kebab(cardId)}';

/// Prefix every popup tile's hook carries: feature `card`, control `popup`,
/// instance the card's registry id.
///
/// `popup` and not `tile`, because that is the vocabulary the code is written in —
/// `CardPopupForm`, `CardDensity.popup`, `selectableForms` — and a slug is read
/// alongside the widget it names. "Tile" appears only in prose.
const String kCardPopupIdentifierPrefix = 'card-popup-';

/// Composes the hook for [cardId]'s popup tile — the degraded, one-value form that
/// opens the card's full form in a presentation (#1239 by width, #1299 by pick).
///
/// ## Why the tile needs a handle of its own
///
/// It is a real control: the *whole card* is the tap target (`AppCard(onTap:)`, so
/// ui_kit gives it a `button: true` semantics node), and it is the only way to
/// reach the presentation. A card in this form shows no footer, so for the thirteen
/// cards with a detail entry the presentation holds the **only** copy of that
/// button — [cardDetailIdentifierFor]'s hook is unreachable without this one. For
/// the four cards with no detail entry it is stronger still: the presentation is
/// the only place their content can be read at all when degraded.
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
String cardPopupIdentifierFor(String cardId) =>
    '$kCardPopupIdentifierPrefix${_kebab(cardId)}';

/// Registry ids are `snake_case`, identifiers are kebab — shared by both hooks so
/// the two families cannot transform an id differently.
String _kebab(String cardId) => cardId.replaceAll('_', '-');
