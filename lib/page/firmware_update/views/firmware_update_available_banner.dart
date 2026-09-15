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
/// page's notifier and needs a confirmation the user has not given yet — a banner
/// button that started a flash from the dashboard would be a second, unconfirmed
/// entry into a reboot.
///
/// ## A card, not a bar
///
/// This shipped first as a full-bleed `Container(color: primaryContainer)`, which
/// made it the fourth stacked bar above the grid — SSE banner, assistance banner,
/// top bar, then this — and read as browser chrome for something that is *content*:
/// a fact about the router, ranked above the cards but of the same kind. Measured on
/// that shape: 92px of flat height from 601px all the way to 1920px for one sentence
/// and two buttons, and `primaryContainer` at the same loudness the SSE banner uses
/// for a dropped session.
///
/// So it is an [AppCard] inset to `context.pageMargin`, which is the same inset the
/// dashboard grid and [UspSliverDashboardView]'s own offline banner use — the notice
/// lines up with the cards under it instead of floating beside them. Going through
/// `AppCard` rather than a `Container` is what makes it theme-aware: `AppSurface`
/// resolves radius, border, shadow, blur, texture and the design language's
/// signature effect from `AppDesignTheme`, scales its padding by `spacingFactor`,
/// animates on the theme's own duration and curve, and cascades `contentColor` into
/// the children through `IconTheme` and `DefaultTextStyle`. A `Container(color:)`
/// bypasses every one of those, which is why the old shape looked identical under all
/// eight design languages.
///
/// The colour treatment is the kit's own recipe for a standard informational notice,
/// read out of `ToastColorResolver` (`standard` + `info`): an untinted
/// `theme.surfaceElevated`, content at the surface's normal `contentColor`, and a
/// single accent-coloured icon — and that accent is `colorScheme.primary`, *not*
/// `semanticInfo`. `semanticInfo` is a saturated status colour paired with hardcoded
/// white text; using it here would have been louder than the slab it replaced.
///
/// `surfaceElevated` rather than the `surfaceBase` an `AppCard` defaults to, for the
/// same reason the toast resolver picks it: this sits above a grid of `surfaceBase`
/// cards and has to be distinguishable from them without being tinted.
///
/// Composed from kit atoms rather than a kit component. The one component that comes
/// close is [AppToast], and it is the wrong shape twice over: it is an overlay with a
/// lifetime, and it has no action slot at all — `onDismiss` is the only affordance it
/// takes, so Update Now could not live in one.
class FirmwareUpdateAvailableBanner extends ConsumerWidget {
  const FirmwareUpdateAvailableBanner({super.key});

  /// Content width at or above which the notice is a single row.
  ///
  /// Measured, not a breakpoint. The row holds five things that cannot give: a 20px
  /// icon, gaps of 8 + 12 + 8, a `small` Dismiss whose label is localized (widest
  /// `de`, 107.6px) and a `small` Update Now beside it (widest `de`, 150.7px). That
  /// is **306.3px** of fixed demand, and the sentence beside them asks up to
  /// **455.9px** (`fr`) — **762.2px** together, rounded up to 780 for headroom.
  ///
  /// The threshold covers the *whole sentence* rather than a readable minimum,
  /// because anything less buys nothing: at 466px the text column gets 160px, `fr`
  /// wraps to three lines, and the row is then 79px tall against the 72px the
  /// stacked arm costs at the same width. A `RenderParagraph` handed too little
  /// width does not overflow, it wraps — the half of #1549's bug the overflow sweep
  /// could not see — so the choice is which layout is shorter, and below 780 it is
  /// always the stacked one.
  ///
  /// In practice this is a single row from a 868px window up, and stacked below.
  static const _stackBelow = 780.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firmwareUpdateBannerVisibleProvider)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    // Null in a test that pumps this widget without the extension, in which case
    // `AppCard` falls back to a plain container and `style: null` is the right
    // thing to hand it.
    final designTheme = Theme.of(context).extension<AppDesignTheme>();
    final version = ref.watch(firmwareUpdateOfferedVersionProvider);

    final dismiss = AppButton.text(
      label: loc(context).dismiss,
      size: AppButtonSize.small,
      identifier: 'firmware-update-banner-dismiss',
      // Records *which* update was waved away, not that one was: the next version
      // the router finds is a new notice and must arrive. Reading the offered
      // version here rather than passing it in keeps this widget's only input the
      // one flag it watches.
      onTap: () => ref
          .read(firmwareUpdateBannerDismissedVersionProvider.notifier)
          .state = ref.read(firmwareUpdateOfferedVersionProvider),
    );

    final update = AppButton.primary(
      label: loc(context).updateNow,
      // `small` in both arms. A `medium` spends 24px of padding a side, and ui_kit
      // ellipsizes a label that then does not fit rather than letting it overflow
      // where the sweep could see it — the measurement the OTA card's stacked arm
      // records.
      size: AppButtonSize.small,
      identifier: 'firmware-update-banner-update',
      onTap: () => context.pushNamed(RouteNamed.uspFirmwareOta),
    );

    return AppCard(
      // E2E arrival anchor. `firmware-update-banner-*` rather than the
      // `firmware-ota-card-*` family the OTA card uses: this is a different
      // surface reached without navigating, and a spec that confused the two
      // would assert the dashboard from Administration and still pass.
      identifier: 'firmware-update-banner',
      style: designTheme?.surfaceElevated,
      margin: EdgeInsets.symmetric(
        horizontal: context.pageMargin,
        vertical: AppSpacing.xs,
      ),
      // Tighter than the `AppSpacing.lg` an `AppCard` defaults to, and tighter
      // vertically than horizontally: the row's height is set by the 48px buttons
      // inside it, so vertical padding is pure addition. `md`/`sm` puts the single
      // row at 72px against the 92px slab it replaces.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < _stackBelow;

          final notice = Row(
            children: [
              AppIcon.font(
                Icons.system_update_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
              AppGap.sm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(loc(context).firmwareUpdateAvailable),
                    // Only in the single-row arm, where it is free: the column is
                    // then 39px against the 48px the buttons beside it already
                    // cost. Stacked, it is a whole extra line on the widths where
                    // the sentence above it is already wrapping — and the version
                    // is on the OTA page this banner's own button opens.
                    //
                    // Dropped rather than rendered empty when the router reports
                    // no version: some builds publish `Available=true` with an
                    // empty `Version`, and "Available: " with nothing after it is
                    // worse than no line. Same rule the wizard's install card
                    // follows.
                    if (!stacked && version != null && version.isNotEmpty) ...[
                      AppGap.xxs(),
                      // Smaller rather than a different colour. `AppText` inherits
                      // the surface's `contentColor` through the `DefaultTextStyle`
                      // that `AppSurface` cascades, so size carries the hierarchy
                      // and no design language can end up with a low-contrast
                      // second line.
                      AppText.bodySmall(
                          loc(context).availableVersionLabel(version)),
                    ],
                  ],
                ),
              ),
            ],
          );

          if (!stacked) {
            return Row(
              children: [
                Expanded(child: notice),
                AppGap.md(),
                dismiss,
                AppGap.sm(),
                update,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              notice,
              AppGap.sm(),
              // `Wrap` rather than a `Row`: two localized button labels can exceed
              // a 320px screen together (`de` asks 266.3px of the 236px such a
              // screen grants this card), and a wrapped second line is readable
              // where a squeezed one is not.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [dismiss, update],
              ),
            ],
          );
        },
      ),
    );
  }
}
