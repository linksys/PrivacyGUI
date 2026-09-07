import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';

/// Carries the current [CardDensity] down a card's subtree.
///
/// Density is *injected*, not threaded through constructors: a card's blocks are
/// several levels deep and mostly shared, so a parameter would have to be added
/// to every one of them and passed by every caller, including the ones that have
/// no density to give. Reading it from context means a block that cares can ask,
/// and a block that does not is untouched — which is the stated shape of #1232:
/// leaf blocks stay density-free.
class CardDensityScope extends InheritedWidget {
  const CardDensityScope({
    super.key,
    required this.density,
    this.cardId,
    this.normalHeight,
    this.liveForm,
    this.presented = false,
    required super.child,
  });

  final CardDensity density;

  /// Which card this subtree belongs to — the widget registry's id
  /// (`'wifi_status'`), not a display name.
  ///
  /// Travels alongside the density because it travels the same route: the id is
  /// known only to whoever looked the card up, and the blocks that need it are
  /// several levels below with shared widgets in between. Threading it through
  /// constructors would mean a parameter on every one of them, which is the
  /// argument this class already makes for the density itself.
  ///
  /// The one thing that needs it is the E2E handle on the card's detail-entry
  /// button (#1450): the identifier has to be unique per card, and the card's own
  /// route is not — `wifi_status` and `wifi_networks` both enter `uspWifiSettings`,
  /// `system_status` and `traffic_analysis` both enter `uspStatistics`. Registry
  /// ids are unique by construction, so deriving the handle from this one cannot
  /// collide, and a card added later gets its handle without an edit.
  ///
  /// Null outside a [CardDensityHost] — a shared block built by a settings page
  /// belongs to no card, and saying so is more useful than a placeholder id that
  /// reads like a real one.
  final String? cardId;

  /// Height, in pixels, the card's *whole* form needs — carried down alongside
  /// the density because the presentation the popup form opens needs it.
  ///
  /// It answers a question the widget tree cannot: once a card has been picked
  /// into popup its cell is pinned to one grid row (#1299), so the box the tap
  /// came out of is a *consequence* of the degradation and says nothing about what
  /// the card needs. Null means nothing declared a height, and the presentation
  /// falls back to the box it was tapped from.
  ///
  /// Pixels rather than rows, so `_shared` needs no notion of a grid: the row
  /// count is a dashboard concept and the conversion happens there.
  ///
  /// The card's declared *width* threshold used to travel here too, for the same
  /// tap. It no longer does: the presentation is one fixed width for every card
  /// (`kCardPresentationWidth`), so the only reader of the declared width is
  /// [CardDensityHost]'s own selection, which has it from the spec already.
  final double? normalHeight;

  /// The card *widget* this scope wraps — what the popup form's presentation
  /// builds, rather than the widget it was handed.
  ///
  /// A `StatelessWidget` handed down as `normalForm: this` is a *snapshot*: the
  /// element that built it — the card's own `ConsumerWidget`, which watches
  /// `cardTabIndexProvider`, its data providers and its interval menu — lives
  /// outside the presentation's tree. So a provider write rebuilt the tile's copy
  /// of the card and could not rebuild the presented one, and the presentation
  /// froze at whatever state the tap happened in: tabs moved their own highlight
  /// and changed nothing under it, menus selected nothing, live numbers stopped.
  ///
  /// Publishing the widget instead lets the presentation mount its own element
  /// for it, under its own scope, so both copies watch the same providers and
  /// neither is a snapshot of the other. Null outside a [CardDensityHost] — a
  /// bare [CardPopupForm] falls back to the widget it was given, which is all
  /// there is.
  final Widget? liveForm;

  /// Whether this scope is the *presentation* rather than a card in the grid.
  ///
  /// A card is normally free to ignore where it is drawn, and nearly all of them
  /// do. Topology cannot: the presentation is a box of its own with no `ClipRect`
  /// competing for the space, so the graph is pannable there and its nodes want
  /// the spacing the dashboard cell had to double to look right.
  final bool presented;

  /// The density in effect at [context], or [CardDensity.normal] outside any
  /// card.
  ///
  /// Defaults rather than throws on purpose. Shared blocks are also built by
  /// non-card callers (settings pages, dialogs), and those have no card width to
  /// measure; making the read an assertion would turn every such call site into
  /// a crash the moment a block starts consulting density.
  static CardDensity of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CardDensityScope>();
    return scope?.density ?? CardDensity.normal;
  }

  /// The id of the card [context] is inside, or null outside any card — see
  /// [cardId].
  static String? cardIdOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardDensityScope>()?.cardId;

  /// The declared whole-form height in effect at [context], or null outside any
  /// card.
  static double? normalHeightOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CardDensityScope>()
      ?.normalHeight;

  /// The card widget published at [context] — see [liveForm].
  static Widget? liveFormOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardDensityScope>()?.liveForm;

  /// Whether [context] is inside the presentation rather than the grid — see
  /// [presented]. False outside any card, which is what a card drawn on its own
  /// page is: not a presentation of a smaller form.
  static bool isPresented(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CardDensityScope>()
          ?.presented ??
      false;

  @override
  bool updateShouldNotify(CardDensityScope oldWidget) =>
      oldWidget.density != density ||
      oldWidget.cardId != cardId ||
      oldWidget.normalHeight != normalHeight ||
      oldWidget.presented != presented ||
      oldWidget.liveForm != liveForm;
}

/// Wraps a dashboard card and publishes the [CardDensity] its width selects to
/// its subtree.
///
/// Applied in `UspWidgetFactory.buildWidget`, the one place both production and
/// the #1183 overflow gate construct cards — so the two cannot disagree about
/// which form is on screen.
///
/// The width is [cardWidth], handed down by whoever laid the card out, never read
/// from `MediaQuery` or `context.colWidth`. #1231 and #1251 were spent removing
/// screen-derived widths from cards for the reason that makes them wrong here too:
/// a card is resizable independently of the window, so the screen says nothing
/// about how much room this card has.
///
/// ## Three sources, in this order
///
/// 1. [cardDensityOverrideProvider] — a forced value, used by the #1183 gate to
///    render a card in a form the width would not have selected.
/// 2. [cardFormsProvider] — the form the user picked for this card on this grid
///    (#1299). It wins over the width because that is the whole inversion: the
///    pick has already constrained which widths the card can be, so the width has
///    nothing left to decide. `normal` is excluded — it is the *removal* of a
///    pick, so it falls through to the width rather than pinning.
/// 3. [cardWidth] (#1232, supplied by the grid since #1401).
///
/// The first two are read with `ref.watch` from *inside* the tile on purpose. The
/// grid caches what its item builder returned and will not call it again for a
/// provider write (#1395), so a pick or an override has to reach a consumer below
/// that boundary or it would not be seen until the next geometry change.
class CardDensityHost extends ConsumerWidget {
  const CardDensityHost({
    super.key,
    required this.cardId,
    required this.normalAbove,
    required this.cardWidth,
    this.normalHeight,
    required this.child,
  });

  /// Widget spec ID, used to look up an override.
  final String cardId;

  /// The card's declared threshold, from its `WidgetSpec`. Null means the card
  /// has no degraded form.
  final double? normalAbove;

  /// Pixel width of the box this card was laid out in, from the caller that
  /// computed the box — `DashboardItemBreakpointBuilder` in the dashboard, the
  /// probe's own `SizedBox` on the gate path (#1401).
  ///
  /// Required, and required *nullable*: every construction site has to say
  /// something, and a caller with no box to report says so with `null` rather
  /// than by omission. Null resolves to [CardDensity.normal] — see
  /// [densityForSuppliedWidth] for why that, and not popup.
  ///
  /// ## Accurate to the band, not to the pixel
  ///
  /// The grid re-invokes its builder when the *resolved breakpoint* transitions,
  /// not on every pixel, so between transitions this holds the width the card was
  /// built at rather than the width it currently occupies. That is exactly enough
  /// for the density — a width that would change the answer has by definition
  /// crossed a boundary, which is what re-invokes the builder — and it is not
  /// enough for anything reading it as a measurement. Whatever #1240 AC 1 does
  /// with a card's real box has to say which of the two it needs.
  final double? cardWidth;

  /// Height the card's whole form needs, in pixels — see
  /// [CardDensityScope.normalHeight].
  ///
  /// Optional where [normalAbove] is required, because omitting it restores the
  /// behaviour that predates it (the presentation uses the box it was tapped
  /// from) rather than making a claim about the card. A card built outside the
  /// dashboard has no declared height to give.
  final double? normalHeight;

  final Widget child;

  /// The scope this host publishes, whichever of the three sources decided
  /// [density].
  ///
  /// One place, because everything travelling down alongside the density has to
  /// travel down every path: a card whose form was *picked* and one whose form
  /// was *measured* both open the same presentation, and a field supplied on one
  /// path only is a bug that shows up in one of the two and not the other.
  CardDensityScope _scope(CardDensity density) => CardDensityScope(
        density: density,
        cardId: cardId,
        normalHeight: normalHeight,
        // The card widget, not the built card: see [CardDensityScope.liveForm].
        liveForm: child,
        child: child,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(cardDensityOverrideProvider(cardId));
    if (override != null) return _scope(override);

    // The pick, if there is one for this card. Not keyed by breakpoint here
    // because it does not need to be (#1400): the picks are read off the items of
    // the grid that is on screen, so "this grid" is what the provider holds rather
    // than something this card has to name. It used to pass
    // `context.currentMaxColumns` and rely on that being the controller's slot
    // count by construction.
    final picked = ref.watch(cardFormsProvider).densityFor(cardId);
    if (picked != null && picked != CardDensity.normal) return _scope(picked);

    // The width the grid already computed, rather than a `LayoutBuilder`
    // re-deriving it under every card (#1401). The two produced the same number —
    // the package's `itemWidth` is the same formula this view uses for its own
    // `slotWidth` — so this is about *when* the number is asked for, not what it
    // is.
    //
    // It also retires the branch that used to sit here: a card with no declared
    // threshold skipped the measurement entirely, because inserting a
    // `LayoutBuilder` to compute a constant would have cost that card a build
    // during every layout pass of a drag-resize. There is nothing to skip now —
    // the width arrives as an argument, and a threshold-less card resolves to a
    // constant breakpoint, so the grid holds its subtree across a resize for the
    // same reason the skip used to.
    return _scope(
      densityForSuppliedWidth(width: cardWidth, normalAbove: normalAbove),
    );
  }
}
