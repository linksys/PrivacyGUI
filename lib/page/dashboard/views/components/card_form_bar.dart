import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The edit-mode toolbar row that picks the form of the selected card (#1299).
///
/// Select a card in the grid, then choose its form here. The form decides how far
/// that card can then be resized — popup not at all, compact only larger, normal
/// as before.
///
/// ## Why the toolbar, and not the card or the settings dialog
///
/// Not the card: the spike in
/// `test/page/dashboard/views/density_control_gesture_spike_test.dart` showed that
/// edit mode's `AbsorbPointer` swallows anything drawn inside a card, and that
/// hoisting a control above it arms a drag on desktop which `cancelInteraction()`
/// does not stop — the overlay's pointer-up still commits the move. So an on-card
/// control would either not receive the tap or would nudge the card while
/// receiving it.
///
/// Not the layout settings dialog either, which is where this first landed. A list
/// of every card's name with a dropdown beside it asks the user to find the card
/// they are looking at in a list, in a dialog covering the grid they were looking
/// at it in. Selecting the card and shaping it is the same gesture pair the rest of
/// edit mode already uses (select, then drag; select, then trash).
///
/// ## Why it is its own widget
///
/// [UspSliverDashboardView] builds its own `ScrollController` on every build, so
/// making the view rebuild on selection would send the grid back to the top each
/// time a card is tapped. Watching the selection here keeps the rebuild to this
/// row.
///
/// ## Why it keeps its height with nothing selected
///
/// A bar that appeared on selection would push the grid down by its own height on
/// every tap. It stays, and shows what to do instead — which is also the answer to
/// discoverability, since a control that is only reachable through a dialog is a
/// control most users never find.
class CardFormBar extends ConsumerWidget {
  const CardFormBar({super.key});

  /// Height of the picker, so the row is the same height with and without it.
  static const double _rowHeight = 48;

  /// Width of the picker. Wide enough for the longest form name in the 26 shipped
  /// locales, narrow enough to leave the card name legible at
  /// `kMinSupportedScreenWidth`.
  static const double _pickerWidth = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No membership check against the grid: a selected card is on the grid by
    // construction. Every removal path — the trash zone, the settings dialog's
    // remove, a preset swap — ends in `DashboardController.removeItems`, which
    // calls `clearSelection()` itself, and the mirror publishes that. A check
    // was written here first and then dropped: mutation-tested, no test could
    // kill it, which is the definition of a branch that cannot run.
    final cardId = ref.watch(selectedCardIdProvider);

    final options = cardId == null
        ? const <CardDensity>[]
        : UspWidgetSpecs.selectableForms(cardId);

    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          Expanded(
            child: cardId == null
                ? AppText.bodySmall(loc(context).cardFormSelectPrompt)
                : AppText.bodyMedium(
                    _displayName(ref, cardId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (cardId != null && options.isNotEmpty) ...[
            AppGap.md(),
            SizedBox(
              width: _pickerWidth,
              child: _buildPicker(context, ref, cardId, options),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPicker(
    BuildContext context,
    WidgetRef ref,
    String cardId,
    List<CardDensity> options,
  ) {
    // The breakpoint the pick belongs to, read from the context rather than from
    // `controller.slotCount`, even though that is the number `setCardForm`
    // writes under. The two are the same number — the grid is handed
    // `breakpoints: {0: context.currentMaxColumns}` — but the controller is only
    // told about a resize in a post-frame callback, so it trails by a frame.
    // Reading the context means this row follows a window resize across a
    // breakpoint at all: `currentMaxColumns` goes through `MediaQuery.sizeOf`,
    // which registers the dependency that rebuilds it. Watching the controller's
    // beacon instead would leave the row showing the previous breakpoint's pick
    // until something unrelated rebuilt it.
    final slots = context.currentMaxColumns;

    // A card with no stored pick shows normal: normal is the absence of a pick,
    // not a stored value, so the two have to read the same.
    final selected = ref.watch(cardFormsProvider).densityFor(slots, cardId) ??
        CardDensity.normal;

    return AppDropdown<CardDensity>(
      identifier: 'card-form-picker',
      semanticLabel: loc(context).cardFormForNamed(_displayName(ref, cardId)),
      items: options,
      value: selected,
      itemAsString: (density) => _cardFormLabel(context, density),
      itemIdentifier: (density) => 'card-form-${density.name}',
      onChanged: (density) {
        if (density == null || density == selected) return;
        ref
            .read(uspSliverDashboardControllerProvider.notifier)
            .setCardForm(cardId, density);
      },
    );
  }

  /// The selected card's name, falling back to its id.
  ///
  /// Read from [allWidgetSpecsProvider] rather than [UspWidgetSpecs] so a package
  /// widget is named too. Such a card offers no form — `selectableForms` returns
  /// nothing for it — so it appears here as a name with no picker, which reads as
  /// "selected, nothing to choose" rather than as a broken row.
  String _displayName(WidgetRef ref, String cardId) {
    for (final spec in ref.read(allWidgetSpecsProvider)) {
      if (spec.id == cardId) return spec.displayName;
    }
    return cardId;
  }

  String _cardFormLabel(BuildContext context, CardDensity density) =>
      switch (density) {
        CardDensity.popup => loc(context).cardFormPopup,
        CardDensity.compact => loc(context).cardFormCompact,
        CardDensity.normal => loc(context).cardFormNormal,
      };
}
