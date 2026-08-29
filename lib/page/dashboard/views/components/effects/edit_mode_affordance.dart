import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/jiggle_shake.dart';

/// The edit-mode affordance around a dashboard card: the jiggle that says the
/// card can be moved, and the absorber that keeps taps out of card content while
/// the grid is being edited.
///
/// ## Why it reads the flag itself (#1395)
///
/// `sliver_dashboard` 2.3.1 made toggling edit mode nearly free by caching what a
/// tile's `itemBuilder` returned (`dashboard_item_widget.dart:487`,
/// `_cachedWidget ??=`). The cache is invalidated only when the item's content
/// signature or its measured dimensions change — not when edit mode toggles,
/// despite the comment at `:190` still listing "the global edit mode" as a
/// trigger. So a tile that is *handed* the flag by the enclosing page build reads
/// it once and keeps that answer for as long as its element lives.
///
/// The dashboard page happens to get away with passing it down today, but only
/// because entering edit mode also changes the shape of the widget tree around
/// the tiles — the grid background appears (`gridStyle`), the trash zone appears
/// (`trashBuilder`), and the toolbar layer wraps the grid — and each of those on
/// its own remounts the tile elements, which throws the cache away. Measured:
/// hold all three constant across the toggle and `itemBuilder` is not called
/// again, leaving every card unwrapped in edit mode. That is not a property worth
/// depending on; it would be lost by exactly the kind of change 2.x invites, such
/// as mounting the chrome once and animating its opacity.
///
/// So the dependency lives here, below the cache boundary, where an element can
/// rebuild without its parent's permission. The absorber is the half that carries
/// behaviour rather than decoration: without it a tap reaches card content while
/// the grid thinks it is being edited, which is how accidental deletions
/// happened.
///
/// ## Shape, not properties — and when that has to change
///
/// [build] swaps the widget *shape* (a bare child, or a wrapped one) rather than
/// mounting [JiggleShake] and [AbsorbPointer] permanently and driving their
/// `active`/`absorbing` flags. Driving the flags would keep one element across
/// the toggle; swapping shape remounts the card's subtree under it. Today that
/// buys nothing, because the three chrome changes above already remount every
/// tile on the same toggle — and view mode, which is nearly all of the time,
/// pays for no ticker, no `AnimatedBuilder` and no identity transform per card.
///
/// If those chrome changes ever stop remounting the tiles — the opacity change
/// this class exists to survive — this has to become
/// `JiggleShake(active: isEditMode, child: AbsorbPointer(absorbing: isEditMode,
/// …))` on the same day, or the toggle starts disposing every card's state and
/// re-issuing whatever its providers were holding.
class EditModeAffordance extends ConsumerWidget {
  const EditModeAffordance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select`, because this is the one field of the state the affordance reads
    // and there is one of these per card: `enterEditMode` publishes twice — the
    // flag, then the snapshots it took — and every unselected watcher would
    // rebuild for both, each time running an `Equatable` comparison over the
    // layout snapshot it does not look at.
    final isEditMode =
        ref.watch(dashboardEditModeProvider.select((s) => s.isEditing));
    if (!isEditMode) return child;

    // AbsorbPointer blocks content interactions while keeping the area hittable
    // for DashboardOverlay's drag/resize detection. Widget removal is handled via
    // drag-to-trash (trashBuilder on the overlay), NOT via in-cell tap — a
    // GestureDetector here conflicts with the overlay's raw Listener and causes
    // accidental deletions.
    return JiggleShake(
      active: true,
      child: AbsorbPointer(child: child),
    );
  }
}
