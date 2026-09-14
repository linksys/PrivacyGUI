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
class FirmwareUpdateCard extends StatelessWidget {
  const FirmwareUpdateCard({super.key});

  /// Row width below which the CTA moves onto its own line.
  ///
  /// The same trade [FirmwareOtaCard] documents, on the same row shape, reached
  /// by a different route: what shares this row with an inflexible localized
  /// button is now a whole sentence rather than a version block, and a sentence
  /// wraps happily right up to the point where one of its *words* stops fitting.
  /// Measured at the nine row widths this card is laid out at, the widest word
  /// did not fit in **11 of 26 locales at 238px** — `de` was granted 55.0px for
  /// its 105.7px `Firmware-Image`, `fi` 99.2px for a 146.0px
  /// `laiteohjelmistotiedosto`, and every one of the eleven broke mid-word. No
  /// other row width was red in any locale.
  ///
  /// **None of that is visible to the overflow sweep**, which reports 234 clean
  /// cells for this page: a `RenderParagraph` handed too little width does not
  /// overflow, it wraps, and `Expanded` guarantees it is never handed too much.
  /// So this constant is measured against the words rather than chosen against a
  /// breakpoint, and its companion guard asserts the words rather than counting
  /// red cells.
  ///
  /// 300 rather than 289: the worst locale needs 288.7px inline (20px icon +
  /// 16px + its widest word + 16px + its CTA, `de` again), and the tightest
  /// inline coordinate is 360.5px — the row width at a 480px screen. 300 clears
  /// the first without reaching the second. Deliberately not [FirmwareOtaCard]'s
  /// 400: that card's CTA carries `checkForUpdates`, which is 242.5px in `fr`
  /// against this one's 131px `Aktualisieren`, so copying the number would stack
  /// this row at four widths that render it perfectly well.
  static const _stackBelow = 300.0;

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
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < _stackBelow;
                  final description = Row(
                    children: [
                      Icon(Icons.system_update,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      AppGap.md(),
                      // `Expanded` so the sentence wraps instead of pushing the
                      // row past its box. It is what makes the row *fit*; the
                      // threshold above is what makes what fits readable.
                      Expanded(
                        child: AppText.bodyMedium(loc(context).manualUpdateDesc,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  );
                  final cta = AppButton.text(
                    label: loc(context).update,
                    // The CTA that blocks automation today — the real user
                    // entry into the manual update page (PrivacyGUI-USP-E2E#85).
                    identifier: 'firmware-card-update',
                    onTap: () =>
                        context.pushNamed(RouteNamed.uspFirmwareUpdate),
                  );

                  if (stacked) {
                    // `stretch` so the label gets the whole line rather than
                    // ellipsizing inside ui_kit's `Flexible`, which is what the
                    // sibling card stacks for as well.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        description,
                        AppGap.md(),
                        cta,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: description),
                      AppGap.md(),
                      cta,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
