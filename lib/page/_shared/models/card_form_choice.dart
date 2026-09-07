import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';

/// The form a user picked for one card on one breakpoint, plus what it takes to
/// undo the pick.
///
/// #1299 inverts #1232's mechanism. #1232 reads a card's rendered width and
/// derives the form from it; this reads the form the user asked for and derives
/// the sizes that are legal. A [CardFormChoice] is the stored half of that
/// inversion.
///
/// ## Where it is stored (#1400)
///
/// On the grid item it describes, in `LayoutItem.extra`, under [extraKey]. That
/// is a change of address rather than of meaning: #1299 kept the picks in a
/// `(slotCount, cardId)`-keyed map beside the geometry, because `LayoutItem` had
/// a closed field set at the time and `exportLayout()` dropped anything else.
/// `sliver_dashboard` 1.2.0 added `LayoutItem.extra`, a per-item payload
/// `exportLayout`/`importLayout` round-trip and `setSlotCount` keeps per grid —
/// so the pick and the geometry it justifies are now one value that cannot be
/// written, restored or undone by halves.
///
/// Still per breakpoint, and now by construction rather than by a key: each
/// slot count has its own cached list of items, so a pick made on the phone grid
/// is on the phone grid's copy of the card and nowhere else.
///
/// Why the inversion does not contradict §2.1's "not a user preference": the
/// framework still guarantees the layout, it just guarantees it by constraining
/// the geometry rather than by degrading the content. On a phone the user has no
/// influence over width at all — the 4-column grid pins `x`, `w` and both width
/// caps, which since `sliver_dashboard` 2.6.0 is the whole of the #1293 lock
/// (#1399) — so a pick is the only mechanism that puts a phone user in control of
/// density.
class CardFormChoice extends Equatable {
  const CardFormChoice({
    required this.density,
    this.restoreW,
    this.restoreH,
  });

  final CardDensity density;

  /// The `w` the card had on this breakpoint before popup collapsed it, or null
  /// when the card is not in popup.
  ///
  /// Recorded on the way into popup and consumed on the way out, per breakpoint
  /// because each grid has its own geometry. Without it "cannot be resized" is a
  /// one-way door: an icon-and-one-value tile has no handles to drag back, so
  /// whatever the card was is unrecoverable unless it was written down.
  ///
  /// Deliberately not recorded for compact. Compact only ever *grows* a card, to
  /// its floor, and that width is one the card genuinely needs — the user can
  /// shrink it again the moment they return to normal, whose floor is lower.
  final int? restoreW;

  /// The `h` counterpart of [restoreW].
  final int? restoreH;

  /// Whether this choice carries a size to put back.
  bool get hasRestore => restoreW != null || restoreH != null;

  /// The key a choice occupies inside a `LayoutItem.extra` map.
  ///
  /// Nested under a key of its own rather than spread across `extra` so the next
  /// feature that needs a per-item payload does not have to know this one exists.
  static const String extraKey = 'cardForm';

  Map<String, dynamic> toJson() => {
        'density': density.name,
        if (restoreW != null) 'restoreW': restoreW,
        if (restoreH != null) 'restoreH': restoreH,
      };

  /// Parses one stored choice, or returns null when it cannot be read.
  ///
  /// An unreadable choice is dropped rather than rejecting the whole payload:
  /// the geometry beside it is the user's real work, and losing a density pick
  /// is a far smaller loss than resetting a dashboard they arranged.
  static CardFormChoice? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final density = CardDensity.values.asNameMap()[raw['density']];
    if (density == null) return null;
    final restoreW = raw['restoreW'];
    final restoreH = raw['restoreH'];
    return CardFormChoice(
      density: density,
      restoreW: restoreW is int ? restoreW : null,
      restoreH: restoreH is int ? restoreH : null,
    );
  }

  /// The pick carried by an item's `extra` payload, or null when it carries
  /// none.
  ///
  /// Takes [Object?] rather than a typed map because the same call reads both a
  /// live `LayoutItem.extra` and the serialised item maps `exportLayout()`
  /// produces and `jsonDecode` hands back, and those arrive as three different
  /// map types.
  static CardFormChoice? readFrom(Object? extra) =>
      extra is Map ? tryFromJson(extra[extraKey]) : null;

  /// [extra] with this choice written into it, leaving any other payload alone.
  Map<String, dynamic> writeInto(Object? extra) => {
        if (extra is Map) ...extra.cast<String, dynamic>(),
        extraKey: toJson(),
      };

  @override
  List<Object?> get props => [density, restoreW, restoreH];

  @override
  String toString() => 'CardFormChoice(${density.name}'
      '${hasRestore ? ', restore ${restoreW}x$restoreH' : ''})';
}

/// The form each card is in on the grid currently on screen, by card id.
///
/// A read model and nothing else (#1400). The picks themselves live on the grid
/// items — see [CardFormChoice] — and this is the projection of the *live* grid's
/// items that the render side watches: [CardDensityHost] for the form a card
/// draws itself in, and the edit-mode toolbar for the chip it shows as selected.
///
/// Not keyed by breakpoint, and that is the point of #1400 rather than a
/// simplification of it. #1299 keyed a stored map by `(slotCount, cardId)`
/// because the picks were a second store that had to name the grid it described.
/// A projection of the live layout has one grid by definition — the one whose
/// geometry is on screen — so there is no key to get wrong and no second store to
/// disagree with. `UspSliverDashboardControllerNotifier` republishes this from the
/// controller's own layout beacon, so it follows a breakpoint change, an import,
/// a revert and a gesture without any of them having to remember to.
///
/// Absent means "no pick": the card falls back to #1232's width-derived form.
/// That is not the same as an explicit [CardDensity.normal], which pins the card
/// to normal at every width — see `UspWidgetSpecs.applyPickedForms`.
///
/// Value equality is load-bearing rather than decorative: this is the value of a
/// `StateProvider` (`cardFormsProvider`), and it is republished on every write to
/// the layout beacon — which includes each leg of the persistence walk's visit to
/// the other breakpoints. On identity alone each of those would rebuild every
/// card that reads its density, for picks that did not change. [Equatable]
/// compares the map deeply, keys included.
class CardForms extends Equatable {
  const CardForms(this.byCard);

  static const CardForms empty = CardForms({});

  /// The picks read off the live grid's items, by card id.
  final Map<String, CardFormChoice> byCard;

  /// The picks carried by [items], for a caller holding a grid's live items.
  ///
  /// The one place this projection is built, so "the read model is the live
  /// layout" is a fact about one function rather than a convention.
  ///
  /// Takes `(id, extra)` pairs rather than the grid's own item type so that this
  /// file — a value object under `_shared/`, read by every card that resolves a
  /// density — does not have to import the dashboard's grid package. The two
  /// fields are all the projection uses, and the caller that has the items is the
  /// controller, which imports the package anyway.
  static CardForms of(Iterable<(String, Object?)> items) => CardForms({
        for (final (id, extra) in items)
          if (CardFormChoice.readFrom(extra) case final choice?) id: choice,
      });

  bool get isEmpty => byCard.isEmpty;

  /// The form picked for [cardId], or null when the user has not picked one and
  /// the width should decide.
  CardDensity? densityFor(String cardId) => byCard[cardId]?.density;

  @override
  List<Object?> get props => [byCard];

  @override
  String toString() => 'CardForms($byCard)';
}
