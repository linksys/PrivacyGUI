import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_banner_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The dashboard notice that the router has found a newer firmware (REQ-C3).
///
/// **Exactly two actions, and the second one is not a promise.** Update Now opens
/// the OTA page, where the existing check → confirm → install flow lives; Dismiss
/// hides this for the session. A third "Tonight" button was specified and is
/// deliberately absent: the router's own scheduling is a cron tick nobody in this
/// stack can name a time for, so a button offering one would be inventing a
/// commitment the data plane cannot keep. `firmware_update_banner_widget_test.dart`
/// asserts the absence rather than leaving it to review.
///
/// Update Now navigates rather than installing. The install verb belongs to the OTA
/// page's notifier and needs a download target and a confirmation the user has not
/// given yet — a banner button that started a flash from the dashboard would be a
/// second, unconfirmed entry into a reboot.
///
/// Composed from kit atoms rather than a kit component: `ui_kit_library` v3.3.0 has
/// no banner, alert or callout, and the three banners already in this repo
/// ([SseConnectionBanner] among them) are composed the same way. Article XV's stop
/// rule is about *controls*, and the controls here are `AppButton`s.
class FirmwareUpdateAvailableBanner extends ConsumerWidget {
  const FirmwareUpdateAvailableBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firmwareUpdateBannerVisibleProvider)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = colorScheme.onPrimaryContainer;

    return Semantics(
      // E2E arrival anchor. `firmware-update-banner-*` rather than the
      // `firmware-ota-card-*` family the OTA card uses: this is a different
      // surface reached without navigating, and a spec that confused the two
      // would assert the dashboard from Administration and still pass.
      identifier: 'firmware-update-banner',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: colorScheme.primaryContainer,
        // Text above, actions below — always, at every width.
        //
        // Deliberately not a `LayoutBuilder` with a measured stack threshold like
        // `FirmwareOtaCard`'s. That card's row holds one button beside a label;
        // this one holds a full sentence beside two, and the sentence is the
        // widest string #1552 adds (`pl`, 71 characters). Inline, a 320px screen
        // would grant it whatever the two buttons left over, and a
        // `RenderParagraph` handed too little width wraps rather than overflowing
        // — the half of #1549's bug the sweep could not see. Stacking
        // unconditionally removes the class instead of picking a number per
        // locale, and matches what Material's own banner does.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_outlined, size: 20, color: fgColor),
                AppGap.sm(),
                Expanded(
                  child: AppText.bodyMedium(
                    loc(context).firmwareUpdateAvailable,
                    color: fgColor,
                  ),
                ),
              ],
            ),
            AppGap.sm(),
            // `Wrap` rather than a `Row`: two localized button labels can exceed
            // 320px together (`de` asks for "Jetzt aktualisieren" beside
            // "Ausblenden"), and a wrapped second line is readable where a
            // squeezed one is not.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton.text(
                  label: loc(context).dismiss,
                  identifier: 'firmware-update-banner-dismiss',
                  // Records *which* update was waved away, not that one was: the
                  // next version the router finds is a new notice and must
                  // arrive. Reading the offered version here rather than passing
                  // it in keeps this widget's only input the one flag it watches.
                  onTap: () => ref
                      .read(
                          firmwareUpdateBannerDismissedVersionProvider.notifier)
                      .state = ref.read(firmwareUpdateOfferedVersionProvider),
                ),
                AppButton.primary(
                  label: loc(context).updateNow,
                  identifier: 'firmware-update-banner-update',
                  onTap: () => context.pushNamed(RouteNamed.uspFirmwareOta),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
