import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    this.normalHeight,
    required super.child,
  });

  final CardDensity density;

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

  /// The declared whole-form height in effect at [context], or null outside any
  /// card.
  static double? normalHeightOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CardDensityScope>()
      ?.normalHeight;

  @override
  bool updateShouldNotify(CardDensityScope oldWidget) =>
      oldWidget.density != density || oldWidget.normalHeight != normalHeight;
}

/// Wraps a dashboard card, measures the width it was actually given, and
/// publishes the resulting [CardDensity] to its subtree.
///
/// Applied in `UspWidgetFactory.buildWidget`, the one place both production and
/// the #1183 overflow gate construct cards — so the two cannot disagree about
/// which form is on screen.
///
/// The width comes from a `LayoutBuilder`, i.e. from the constraints the grid
/// hands this card, never from `MediaQuery` or `context.colWidth`. #1231 and
/// #1251 were spent removing screen-derived widths from cards for the reason
/// that makes them wrong here too: a card is resizable independently of the
/// window, so the screen says nothing about how much room this card has.
///
/// ## Three sources, in this order
///
/// 1. [cardDensityOverrideProvider] — a forced value, used by the #1183 gate to
///    render a card in a form the width would not have selected.
/// 2. [cardFormsProvider] — the form the user picked for this card on this grid
///    (#1299). It wins over the measurement because that is the whole inversion:
///    the pick has already constrained which widths the card can be, so the width
///    has nothing left to decide. `normal` is excluded — it is the *removal* of a
///    pick, so it falls through to the measurement rather than pinning.
/// 3. the measured width (#1232).
class CardDensityHost extends ConsumerWidget {
  const CardDensityHost({
    super.key,
    required this.cardId,
    required this.normalAbove,
    this.normalHeight,
    required this.child,
  });

  /// Widget spec ID, used to look up an override.
  final String cardId;

  /// The card's declared threshold, from its `WidgetSpec`. Null means the card
  /// has no degraded form.
  final double? normalAbove;

  /// Height the card's whole form needs, in pixels — see
  /// [CardDensityScope.normalHeight].
  ///
  /// Optional where [normalAbove] is required, because omitting it restores the
  /// behaviour that predates it (the presentation uses the box it was tapped
  /// from) rather than making a claim about the card. A card built outside the
  /// dashboard has no declared height to give.
  final double? normalHeight;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(cardDensityOverrideProvider(cardId));
    if (override != null) {
      return CardDensityScope(
        density: override,
        normalHeight: normalHeight,
        child: child,
      );
    }

    // The pick, if there is one for this card on this grid. `currentMaxColumns`
    // is the breakpoint the picks are keyed by — the view feeds the same value to
    // `SliverDashboard(breakpoints: …)`, so the grid's slot count and this are the
    // same number by construction, and it has non-throwing fallbacks so a card
    // built outside a real MediaQuery still reads something.
    final picked = ref
        .watch(cardFormsProvider)
        .densityFor(context.currentMaxColumns, cardId);
    if (picked != null && picked != CardDensity.normal) {
      return CardDensityScope(
        density: picked,
        normalHeight: normalHeight,
        child: child,
      );
    }

    // No threshold declared means the density is a constant: normal at every
    // width. Measuring a constant would still cost a rebuild of the whole card
    // subtree on every layout pass while a card is being drag-resized, so the
    // measurement is skipped rather than performed and discarded. Pinned by
    // test, because "no LayoutBuilder above the card" is also what keeps this
    // ticket's output byte-identical for all 18 cards, none of which declares a
    // threshold (#1240 AC 1/2).
    //
    // Not a correctness crutch: the gate was also run once with this branch
    // removed, so every card rendered through the LayoutBuilder, and stayed at
    // 1644/1644. Inserting the measurement is layout-neutral — so the first card
    // to declare a threshold is not taking on that risk at the same time.
    if (normalAbove == null) {
      return CardDensityScope(density: CardDensity.normal, child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) => CardDensityScope(
        density: densityForWidth(
          width: constraints.maxWidth,
          normalAbove: normalAbove,
        ),
        normalHeight: normalHeight,
        child: child,
      ),
    );
  }
}
