import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Admin-view entry card for the manual firmware update flow.
///
/// A CTA into the dedicated update page, and nothing else. It used to show the
/// current firmware version too; #1549 moved that to [FirmwareOtaCard], because
/// this card is hidden in remote assistance and the version must not be — see
/// that card for the whole argument.
///
/// What is left is genuinely only an entry point, which is what lets the admin
/// view gate it through `firmwareManualEntry` without gating anything a support
/// agent still needs to read. Being stateless is the visible half of that: with
/// the version gone there is no router data on this card to fetch.
///
/// **The block navigates; it does not update.** This card used to carry an
/// `AppButton.text(update)` that only pushed the manual update page (Austin,
/// 2026-09-16, aligning it with [FirmwareOtaCard]). That label was the more
/// misleading of the two the admin page shipped: `checkForUpdates` promised a
/// read, `Update` promises a flash and a reboot — so it misled the person who
/// tapped it *and* deterred the person who would not, who then never saw the file
/// picker the page actually opens with. The whole description row is the
/// affordance now, with the chevron every other navigation row in this app uses.
///
/// **The E2E hook keeps the `-update` name, and that is measured rather than
/// stylistic.** `tests/F06-firmware-journey.spec.ts` item 1 resolves
/// `IDS.firmwareCardUpdate`, asserts `toHaveCount(1)` and clicks it; it asserts
/// neither the label nor the role, and `byIdentifier` selects on
/// `flt-semantics-identifier`, which a tappable `LayoutBlock` emits exactly as an
/// `AppButton` did. So the id stays where the spec can find it. [FirmwareOtaCard]
/// renamed its equivalent hook to `-open` because that one had zero references
/// across the E2E repo; this one has a live caller, and a spec that has to change
/// is a cost this card's copy does not need to buy.
///
/// **No localized button belongs back in this row.** What shares it is a whole
/// sentence, and a sentence wraps happily right up to the point where one of its
/// *words* stops fitting. With the button here, measured at the nine row widths
/// this card is laid out at, the widest word did not fit in **11 of 26 locales at
/// 238px** — `de` was granted 55.0px for its 105.7px `Firmware-Image`, `fi`
/// 99.2px for a 146.0px `laiteohjelmistotiedosto`, and every one of the eleven
/// broke mid-word. That needed a `_stackBelow = 300.0` reflow to fix, and the
/// reflow is deleted with the button, because a fixed 20px chevron cannot
/// reproduce the problem in any locale.
///
/// **None of that was ever visible to the overflow sweep**, which reports 234
/// clean cells for this page either way: a `RenderParagraph` handed too little
/// width does not overflow, it wraps, and `Expanded` guarantees it is never handed
/// too much. Its companion guard therefore asserts the words rather than counting
/// red cells — and it still does, because a future row that puts anything
/// localized back beside this sentence brings the defect back without bringing
/// back the threshold.
class FirmwareUpdateCard extends StatelessWidget {
  const FirmwareUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        // E2E arrival anchor for the Administration-page entry into the manual
        // firmware update flow (PrivacyGUI-USP-E2E#85). Naming matches the
        // `firmware-*` convention already used on the update page itself.
        identifier: 'firmware-card',
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).manualUpdate),
            AppGap.md(),
            // Whole-block tap, the shape Advanced Settings / Local Network /
            // Support use for every row that opens a page. `LayoutBlock` supplies
            // the ink and marks itself `button` to assistive tech, so the chevron
            // is the only thing this call site adds.
            LayoutBlock(
              identifier: 'firmware-card-update',
              onTap: () => context.pushNamed(RouteNamed.uspFirmwareUpdate),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.system_update,
                      size: 20, color: colorScheme.onSurfaceVariant),
                  AppGap.md(),
                  // `Expanded` so the sentence wraps instead of pushing the row
                  // past its box. With the button gone that is the whole of the
                  // width story: what is left beside it is 20px of chevron in
                  // every locale.
                  Expanded(
                    child: AppText.bodyMedium(loc(context).manualUpdateDesc,
                        color: colorScheme.onSurfaceVariant),
                  ),
                  AppGap.md(),
                  AppIcon.font(AppFontIcons.chevronRight, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
