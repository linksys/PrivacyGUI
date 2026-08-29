import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_grid_geometry.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Floats [CardFormToolbar] over the grid it belongs to (#1299).
///
/// Wraps the edit-mode grid — `DashboardOverlay` and the scroll view under it —
/// and paints the form toolbar on top, anchored to whichever card the grid has
/// selected.
///
/// ## Why the toolbar is a sibling above the grid, not a row over it
///
/// It first shipped as a row between the page header and the grid, and that read
/// as part of the dashboard rather than as a control: nothing about a row of
/// chrome says "this is adjusting the card you just tapped". Anchoring it to the
/// card says it spatially, which is the whole point of the placement.
///
/// The card itself is still not an option — `density_control_gesture_spike_test`
/// records why (edit mode's `AbsorbPointer` swallows anything drawn inside a
/// card, and a control hoisted above it arms a drag on desktop that
/// `cancelInteraction()` cannot stop). This placement is neither: the toolbar is
/// a [Stack] sibling *above* `DashboardOverlay`, so the pointer never reaches
/// the overlay's raw `Listener` at all. `RenderStack` hit-tests children in
/// reverse paint order and stops at the first hit, so a press that lands on the
/// toolbar is the toolbar's and nothing else's. That is asserted, on the desktop
/// regime that the spike showed to be the dangerous one, by
/// `card_form_toolbar_test.dart`'s last group.
///
/// ## Why the scroll offset is read from notifications
///
/// The toolbar has to follow its card as the grid scrolls, and the offset is not
/// available from the view: `UspSliverDashboardView` builds a fresh
/// `ScrollController` on every build, so anything that held onto one would be
/// reading a controller the scroll view has already detached. The notifications
/// come from whichever `Scrollable` is currently mounted, which is the one on
/// screen by definition.
class CardFormToolbarLayer extends StatefulWidget {
  const CardFormToolbarLayer({
    super.key,
    required this.geometry,
    required this.child,
  });

  /// The geometry the grid was laid out with, so the toolbar can find the cell
  /// its card occupies.
  final CardGridGeometry geometry;

  /// The edit-mode grid.
  final Widget child;

  @override
  State<CardFormToolbarLayer> createState() => _CardFormToolbarLayerState();
}

class _CardFormToolbarLayerState extends State<CardFormToolbarLayer> {
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          // `depth == 0` keeps this to the grid's own viewport. A card that
          // scrolls internally (a device list, say) would otherwise report its
          // offset as the grid's and drag every toolbar with it.
          onNotification: (notification) {
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical) {
              _scrollOffset.value = notification.metrics.pixels;
            }
            return false;
          },
          child: widget.child,
        ),
        // Second in the Stack, so it paints over — and therefore hit-tests
        // before — the grid.
        Positioned.fill(
          child: CardFormToolbar(
            geometry: widget.geometry,
            scrollOffset: _scrollOffset,
          ),
        ),
      ],
    );
  }
}

/// The form picker for the selected card, drawn just above that card (#1299).
///
/// Select a card in the grid and its forms appear here; the form decides how far
/// the card can then be resized — popup not at all, compact only larger, normal
/// as before. Nothing selected means nothing drawn: the toolbar is the answer to
/// "what can I do with this card", so it has nothing to say until there is one.
///
/// ## Why it is its own widget
///
/// Watching the selection here keeps the rebuild to the toolbar. Watching it in
/// [UspSliverDashboardView] would rebuild the whole page — header, banner, grid
/// and every uncached tile — on each tap of a card, which is a lot of frame for
/// a chip row moving a few hundred pixels. (It would not lose the scroll offset:
/// the view's per-build `ScrollController` re-attaches the position it already
/// had, as the note on that controller records.)
///
/// ## What it does not follow
///
/// The cell arithmetic is [CardGridGeometry.cellRect], fed by the geometry the
/// view laid the grid out with and the item coordinates the controller holds.
/// Both are read fresh, but they cross a window resize a frame apart: the
/// geometry arrives with the new width immediately, and the controller
/// is only told the new slot count in a post-frame callback. For that one frame
/// the toolbar is drawn against a cell the grid no longer uses. It is a paint
/// position, it corrects itself on the next frame, and no gesture can land
/// inside the window — see the same argument in [_pickedForm] for the pick
/// itself, where it would matter.
class CardFormToolbar extends ConsumerStatefulWidget {
  const CardFormToolbar({
    super.key,
    required this.geometry,
    required this.scrollOffset,
  });

  /// The geometry the grid was laid out with.
  final CardGridGeometry geometry;

  /// The grid's current scroll offset, in pixels.
  final ValueListenable<double> scrollOffset;

  /// Distance between the toolbar and the top edge of its card.
  static const double gap = AppSpacing.sm;

  @override
  ConsumerState<CardFormToolbar> createState() => _CardFormToolbarState();
}

class _CardFormToolbarState extends ConsumerState<CardFormToolbar> {
  /// The controller whose layout beacon [_guard] is watching.
  DashboardController? _bound;

  /// Cancels that subscription.
  VoidCallback? _guard;

  /// Follows the selected card's coordinates.
  ///
  /// The selection arrives through Riverpod (the controller mirrors it into
  /// [selectedCardIdProvider]), but the card's *position* only exists on the
  /// controller's layout beacon, and it moves for reasons this widget does not
  /// see: a drag, a resize, a neighbour's reflow, a preset swap. Re-armed on a
  /// controller swap, like every other subscription to it — a reset builds a new
  /// instance, and a toolbar still listening to the old one would sit on the
  /// coordinates the discarded grid had.
  void _bind(DashboardController controller) {
    if (identical(controller, _bound)) return;
    _guard?.call();
    _bound = controller;
    // `startNow: false` because this runs from `build`: the default would
    // publish the current layout synchronously and call `setState` mid-build.
    // The current value is read below instead.
    _guard =
        controller.layout.subscribe((_) => _onLayoutChanged(), startNow: false);
  }

  void _onLayoutChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _guard?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    _bind(controller);

    // No membership check against the grid beyond finding the cell: a selected
    // card is on the grid by construction. Every removal path — the trash zone,
    // the settings dialog's remove, a preset swap — ends in
    // `DashboardController.removeItems`, which calls `clearSelection()` itself,
    // and the mirror publishes that.
    final cardId = ref.watch(selectedCardIdProvider);
    if (cardId == null) return const SizedBox.shrink();

    final options = UspWidgetSpecs.selectableForms(cardId);
    // A card with one form has nothing to pick. Drawing an empty surface over it
    // would read as a control that does not work.
    if (options.isEmpty) return const SizedBox.shrink();

    final item = _itemFor(controller, cardId);
    if (item == null) return const SizedBox.shrink();

    return ValueListenableBuilder<double>(
      valueListenable: widget.scrollOffset,
      builder: (context, scrollOffset, _) {
        final cell = widget.geometry.cellRect(item, scrollOffset);
        return LayoutBuilder(
          builder: (context, constraints) {
            // Scrolled out of the viewport: no cell to sit above. Clamping it to
            // the edge instead would leave a control floating over whatever card
            // happens to be there.
            if (cell.bottom <= 0 || cell.top >= constraints.maxHeight) {
              return const SizedBox.shrink();
            }
            return CustomSingleChildLayout(
              delegate: _AboveTheCard(
                cell: cell,
                gap: CardFormToolbar.gap,
              ),
              child: _buildToolbar(context, cardId, options),
            );
          },
        );
      },
    );
  }

  LayoutItem? _itemFor(DashboardController controller, String cardId) {
    for (final item in controller.layout.value) {
      if (item.id == cardId) return item;
    }
    return null;
  }

  Widget _buildToolbar(
    BuildContext context,
    String cardId,
    List<CardDensity> options,
  ) {
    final picked = _pickedForm(context, cardId);

    return Semantics(
      container: true,
      identifier: 'card-form-toolbar',
      label: loc(context).cardFormForNamed(_displayName(cardId)),
      // Opaque so the whole surface — chips, padding and the gaps between them —
      // stops the hit test here. Without it a press that lands between two chips
      // would fall through to `DashboardOverlay`, which on desktop arms a drag on
      // pointer-down. It carries no callbacks and does not enter the gesture
      // arena, so the chips still win their own taps.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: AppSurface(
          variant: SurfaceVariant.elevated,
          // No outline. The pill is small, it floats over a card that has a
          // border of its own, and a frame around it reads as a second card
          // rather than as a control. What it leaves the pill standing on is the
          // elevated surface's shadow, which is the separation this needs.
          //
          // Frameless takes both of these, because a style can draw a border two
          // ways and `showBorder` only stops one of them. It covers the standard
          // border and the gradient one; the shimmer border that glass (the
          // demo's default) animates is that style's *enhanced* effect, which
          // `AppSurface` applies whenever the theme's shimmer bit is on,
          // whatever `showBorder` says. Its intensity is the knob that stops it.
          showBorder: false,
          enhancedEffect: EnhancedEffectIntensity.none,
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: AppChipGroup(
            chips: [for (final option in options) _chipFor(context, option)],
            selectedIndices: {options.indexOf(picked)},
            selectionMode: ChipSelectionMode.single,
            size: ChipSize.compact,
            onSelectionChanged: (indices) {
              if (indices.isEmpty) return;
              final option = options[indices.first];
              if (option == picked) return;
              ref
                  .read(uspSliverDashboardControllerProvider.notifier)
                  .setCardForm(cardId, option);
            },
          ),
        ),
      ),
    );
  }

  /// The form [cardId] is in on the breakpoint currently on screen.
  ///
  /// The breakpoint is read from the context rather than from
  /// `controller.slotCount`, even though that is the number `setCardForm` writes
  /// under. The two are the same number — the grid is handed
  /// `breakpoints: {0: context.currentMaxColumns}` — but the controller is only
  /// told about a resize in a post-frame callback, so it trails by a frame.
  /// Reading the context means this follows a window resize across a breakpoint
  /// at all: `currentMaxColumns` goes through `MediaQuery.sizeOf`, which
  /// registers the dependency that rebuilds it.
  ///
  /// Which leaves the frame where the two disagree: this has already rebuilt at
  /// the new width, and the controller has not been told yet. A pick made in that
  /// window would be shown as the new grid's and written as the old one's. No
  /// gesture can land there. A frame is one synchronous run of Dart — build,
  /// layout, paint, then the post-frame callbacks — so a pointer event arriving
  /// mid-frame is delivered after it, by which time `setSlotCount` has run.
  ///
  /// A card with no stored pick reads as normal: normal is the absence of a pick,
  /// not a stored value, so the two have to read the same.
  CardDensity _pickedForm(BuildContext context, String cardId) =>
      ref
          .watch(cardFormsProvider)
          .densityFor(context.currentMaxColumns, cardId) ??
      CardDensity.normal;

  /// The card's name, for the toolbar's screen-reader label.
  ///
  /// Read from [allWidgetSpecsProvider] rather than [UspWidgetSpecs] so a package
  /// widget is named too, and falling back to the id so the label is never empty.
  String _displayName(String cardId) {
    for (final spec in ref.read(allWidgetSpecsProvider)) {
      if (spec.id == cardId) return spec.displayName;
    }
    return cardId;
  }

  /// The chip that offers [option] — a glyph, with the form's name carried as the
  /// accessible label rather than drawn.
  ///
  /// ## Why the icon and the name are picked in one switch
  ///
  /// They are one decision: a glyph that is not the one the label names is a bug,
  /// and two switches over [CardDensity] are two places to make it in.
  ///
  /// ## Why icons rather than the three names
  ///
  /// The pill floats over the card, so its width is spent on top of content the
  /// user is looking at, and three localized names is most of a card wide — in
  /// Polish, "Wyskakujące okno" alone. Icons also make the pill the same size in
  /// all 26 locales, which is what puts the narrow-screen case to rest: there is
  /// no longest locale to fit any more.
  ///
  /// What that costs is the label, and it is not free. The glyphs mitigate it by
  /// being one ladder rather than three pictures: Material's density triad, read
  /// left to right as how much of the card shows. Note the names run backwards
  /// from ours — the glyphs count *spacing*, so `density_small` is the packed one,
  /// everything the card has, and `density_large` the sparsest. Screen readers get
  /// the name from [ChipItem.semanticLabel], which is what it is for.
  ///
  /// ## The chips keep a frame of their own, and cannot be told not to
  ///
  /// Dropping the pill's border left three smaller ones inside it. Each chip is
  /// its own `AppSurface`, built inside `AppChipGroup` with `showBorder` at its
  /// default, and the group exposes no way to reach it: [ChipGroupStyle] carries
  /// background, text, radius and a `selectedBorderColor` the group never reads —
  /// no border switch and no width. So this is the kit's to fix, and it is asked
  /// for as such rather than worked around here (`AppChipGroup` gaining the
  /// passthrough, and `applyEnhancedEffect` honouring `showBorder` the way
  /// `applyBorder` already does). Until then the chips are framed under any style
  /// whose surfaces are, which is most of them, and only the pill is not.
  ///
  /// The other cost is the target: a chip that was a word wide is now about 36x24,
  /// under the 48x48 a touch guideline asks for. Stated rather than hidden, and
  /// accepted here — this is edit mode on a card the user has already tapped once,
  /// so the pointer is on the pill, and the three sit side by side under
  /// [ChipSize.compact], which is the size the kit offers. Widening them would
  /// spend back the width that moving off the labels bought.
  ChipItem _chipFor(BuildContext context, CardDensity option) {
    final (icon, name) = switch (option) {
      CardDensity.popup => (Icons.density_large, loc(context).cardFormPopup),
      CardDensity.compact => (
          Icons.density_medium,
          loc(context).cardFormCompact
        ),
      CardDensity.normal => (Icons.density_small, loc(context).cardFormNormal),
    };
    return ChipItem(
      // Empty, which is how `AppChipGroup` is told to draw a chip as its icon
      // alone: it skips the gap and the text when there is no label.
      label: '',
      icon: icon,
      semanticLabel: name,
      identifier: 'card-form-${option.name}',
    );
  }
}

/// Puts the toolbar in the gap above [cell], kept inside the layer.
///
/// Clamping rather than flipping: the toolbar is wider than most cards and taller
/// than the row gap, so the honest position is often outside the layer on one
/// side or the other. A card in the top row gets the toolbar resting on its own
/// top edge, which is where a flip would have put it anyway.
///
/// What that costs, stated rather than discovered later: the toolbar absorbs
/// pointers, so where it overlaps a card it takes that strip out of the card's 20px
/// resize band. Only the top row pays it, and only along the top edge — a card
/// narrower than the pill loses that edge entirely, a wider one keeps its corners —
/// while the sides below the pill and the whole bottom edge stay grabbable. The
/// card it can cover completely is a popup tile, which has no handles to lose.
class _AboveTheCard extends SingleChildLayoutDelegate {
  const _AboveTheCard({required this.cell, required this.gap});

  /// The selected card's cell, in the layer's coordinates.
  final Rect cell;

  /// Distance to leave between the toolbar and the cell.
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      _clamp(
          cell.center.dx - childSize.width / 2, size.width - childSize.width),
      _clamp(cell.top - childSize.height - gap, size.height - childSize.height),
    );
  }

  /// [value] held within `0..limit`, and at 0 when the toolbar is larger than
  /// the layer — where `clamp` itself would throw on an inverted range.
  double _clamp(double value, double limit) =>
      value.clamp(0.0, math.max(0.0, limit));

  @override
  bool shouldRelayout(_AboveTheCard oldDelegate) =>
      oldDelegate.cell != cell || oldDelegate.gap != gap;
}
