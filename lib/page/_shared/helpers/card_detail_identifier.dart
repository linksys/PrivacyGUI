/// Pure derivation of the E2E `identifier` on a dashboard card's entry into its
/// detail page — the `View details` / `View all` button (#1450, unblocks
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
    '$kCardDetailIdentifierPrefix${cardId.replaceAll('_', '-')}';
