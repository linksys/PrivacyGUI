import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Admin-view entry card for the over-the-air firmware update flow.
///
/// **Owns "Current Version" for the whole admin page.** #1549 put two firmware
/// cards side by side, and the version could plausibly have gone on either — it
/// goes here because the *other* card disappears in remote assistance. Were the
/// manual card the owner, a support agent would open Administration and be told
/// no firmware version at all, which is the one audience most likely to need it.
/// The check this card starts also compares against that version, so the value
/// and the button that acts on it stay in one place.
class FirmwareOtaCard extends ConsumerWidget {
  const FirmwareOtaCard({super.key});

  /// Row width below which the CTA moves to its own line under the version.
  ///
  /// Measured, not inherited from the sibling card and not taken from a
  /// breakpoint. The row holds three things that cannot give: a 20px icon, a
  /// version block whose label is a localized noun phrase (widest `da`, 112.2px)
  /// over a fixed-width version string (80.5px), and a button whose width is the
  /// localized `checkForUpdates` (widest `fr`, 242.5px at `medium`). That is
  /// **371.8px** in the worst locale, against the **238px** a 320px screen grants
  /// this row — so `Expanded` was being handed a *negative* remainder, clamped to
  /// zero, and the version label wrapped one character per line: `el` rendered
  /// this row **484px tall** inside a 571px card, and `fr` 500px inside 586px.
  ///
  /// **That is the half of the bug the overflow sweep could not see**, and the
  /// reason this constant exists rather than a `Flexible` on the button. The sweep
  /// reported 9 of 234 cells (all at 320px, `fr`/`fr_CA` worst at +37px) — the
  /// button hanging past the row's right edge. The crushed text beside it reported
  /// nothing at all, because a `RenderParagraph` given 0px does not overflow; it
  /// wraps. Anything that made the button shrink instead would have traded the 9
  /// reported cells for 26 unreported ones, which is exactly the trap
  /// `_OtaCheckCard` documents about `Wrap` on the page this card links to.
  ///
  /// 400 rather than 372: the tightest *inline* coordinate this card is laid out
  /// at is 404.5px (a `colWidth(6)` column at a 1441px screen), so the threshold
  /// has to clear 371.8 without reaching 404.5. It is deliberately not 600 like
  /// the page's card — that card is full page width, this one is half of it above
  /// the desktop breakpoint, and copying the number would stack this row at every
  /// width there is.
  static const _stackBelow = 400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final asyncSystemInfo = ref.watch(systemInfoDataProvider);
    final banks = asyncSystemInfo.valueOrNull?.model.firmwareImages ?? const [];
    final isLoading = asyncSystemInfo.isLoading && banks.isEmpty;
    final activeBank = banks.where((b) => b.isActive).firstOrNull;
    final activeVersion =
        activeBank?.version ?? (banks.isEmpty ? null : banks.first.version);
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        // E2E arrival anchor for the Administration-page entry into the OTA
        // flow, named against the `firmware-card-*` family it sits beside so the
        // two entry points are distinguishable structurally rather than by copy.
        identifier: 'firmware-ota-card',
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).otaUpdate),
            AppGap.md(),
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < _stackBelow;
                  final version = Row(
                    children: [
                      Icon(Icons.cloud_download_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.labelSmall(loc(context).currentVersionShort,
                                color: colorScheme.onSurfaceVariant),
                            if (isLoading)
                              const _CardSkeleton()
                            else if (activeVersion == null)
                              AppText.bodyMedium(loc(context).notAvailable)
                            else
                              // Pin the current-version value so E2E can assert
                              // it without a localized text match. AppText
                              // carries no identifier of its own, so the hook
                              // goes on a wrapping Semantics boundary — the
                              // shape usp_statistics_view.dart uses for its tab
                              // hooks.
                              Semantics(
                                identifier: 'firmware-ota-card-version',
                                child: AppText.bodyMedium(activeVersion),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                  // Hidden while the version is unknown, which is both what the
                  // button means — there is nothing to compare against yet — and
                  // what makes the skeleton readable: the button costs this row
                  // 84–243px depending on locale, and at 320px that is more than
                  // the caption beside the spinner has to live in at all (#1380).
                  final cta = isLoading
                      ? null
                      : AppButton.text(
                          label: loc(context).checkForUpdates,
                          // `small` when stacked for the reason the page's own
                          // check card gives: a stretched `medium` spends 24px of
                          // padding a side, and `fr` then asks 242.5px of a 238px
                          // line and is silently ellipsized by ui_kit. `small`
                          // asks 211.4px and fits.
                          size: stacked
                              ? AppButtonSize.small
                              : AppButtonSize.medium,
                          // The user entry into the OTA page. Distinct from
                          // `firmware-check` on the page itself, which is the
                          // button that actually runs a check.
                          identifier: 'firmware-ota-card-check',
                          onTap: () =>
                              context.pushNamed(RouteNamed.uspFirmwareOta),
                        );

                  if (stacked) {
                    // Version first, then the action on it — and `stretch` so the
                    // button's label gets the whole line rather than ellipsizing
                    // inside ui_kit's `Flexible`.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        version,
                        if (cta != null) ...[
                          AppGap.md(),
                          cta,
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: version),
                      if (cta != null) cta,
                    ],
                  );
                },
              ),
            ),
            AppGap.md(),
            const FirmwareAutoUpdateToggleRow(),
          ],
        ),
      ),
    );
  }
}

/// The auto-update switch (REQ-C1).
///
/// Its own widget, and stateful, for one reason: the switch has to show that a
/// write is in flight, and that is UI state with exactly one reader. Putting a
/// `saving` flag on [FirmwareAutoUpdateUIModel] would have added a field to a
/// model whose whole content is otherwise things the router said.
///
/// **Off writes `1`, not `0`** (Austin, 2026-09-14). `autoupdate_flags` has three
/// values and this control has two positions, so which two it writes is a product
/// decision: a router at `0` stops checking, which would silently take the
/// dashboard banner away as well — and "do not install things behind my back" is
/// not the same request as "never look". `0` is still *readable*, and reads as off,
/// because a router can arrive there from the factory or the CLI.
/// Public, unlike the other two parts of this card, and only so the layout gate
/// can name it: the row *hides itself* on a failed read, so `requires:` on the
/// admin page case is the one assertion that a code-side regression has not
/// deleted it from all 234 cells while the sweep reports a clean page.
class FirmwareAutoUpdateToggleRow extends ConsumerStatefulWidget {
  const FirmwareAutoUpdateToggleRow({super.key});

  @override
  ConsumerState<FirmwareAutoUpdateToggleRow> createState() =>
      _AutoUpdateToggleRowState();
}

class _AutoUpdateToggleRowState
    extends ConsumerState<FirmwareAutoUpdateToggleRow> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final asyncPolicy = ref.watch(firmwareAutoUpdateDataProvider);

    // A read that failed leaves nothing honest to render. `off` would say the
    // router is not updating itself when nobody knows, and `on` is the same lie
    // the other way, so the row is absent rather than guessing — the version
    // block above already reports a failed page.
    if (asyncPolicy.hasError) return const SizedBox.shrink();

    final policy = asyncPolicy.valueOrNull;
    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // The sentence wraps here and that is intended: it keeps ~170px of the
          // 238px a 320px screen grants this row, because the control beside it
          // is a ~52px switch rather than a localized button. That is the
          // difference from the version row above, whose CTA asks up to 242.5px
          // and therefore needs a stacking threshold.
          // Excluded from semantics because the switch beside it carries both
          // strings as its own label. `AppSwitch` sets `container: true`, so a
          // visible label left announceable is read once as loose text and again
          // as the control's name, and the *description* — the string that says
          // what OFF does — is announced with no relationship to the control it
          // describes. This is what the kit's own `label:` parameter does
          // (`ExcludeSemantics` around the text it renders); it is spelled out
          // here because that parameter renders one string inside the switch and
          // this row has two, laid out beside it.
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelSmall(loc(context).automaticUpdates,
                      color: colorScheme.onSurfaceVariant),
                  AppText.bodySmall(loc(context).automaticUpdatesDesc),
                ],
              ),
            ),
          ),
          AppGap.md(),
          AppSwitch(
            identifier: 'firmware-ota-card-auto-update',
            // Joined with a newline rather than punctuation: screen readers pause
            // on it, and it needs no sentence separator picked per locale.
            semanticLabel: '${loc(context).automaticUpdates}\n'
                '${loc(context).automaticUpdatesDesc}',
            // `autoInstall` is the only ON position; `notifyOnly` and `off` both
            // read as off, and `unknown` does too — a flag this build does not
            // define is not a router that installs by itself.
            value: policy?.policy == FirmwareAutoUpdatePolicy.autoInstall,
            // Busy while the write is in flight, and while the first read still
            // is: a switch drawn before its value is known is a control showing
            // a value the router never gave.
            isLoading: _saving || policy == null,
            busySemanticLabel: loc(context).processing,
            // Wired unconditionally, including while busy. `isLoading` already
            // drops the tap handler and already reports `enabled: false` to
            // assistive tech; nulling `onChanged` on top of it asks the kit for the
            // *disabled* treatment as well, and the kit is explicit that busy is
            // not disabled. The two happen to render alike at this call site only
            // because no `label:` is passed — that is the one place the disabled
            // path still dims — so the ternary bought nothing and would have
            // turned a momentary busy switch into a permanently broken-looking one
            // the day someone added a label.
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _saving = true);
    try {
      await ref.read(firmwareAutoUpdateDataProvider.notifier).setPolicy(
            value
                ? FirmwareAutoUpdatePolicy.autoInstall
                : FirmwareAutoUpdatePolicy.notifyOnly,
          );
    } catch (e) {
      // The notifier leaves the published policy alone on failure, so clearing
      // the flag is all it takes for the switch to snap back to what the router
      // still holds.
      if (mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16, height: 16, child: AppLoader()),
        AppGap.md(),
        // Expanded for the reason `usp_timezone_card`'s header gives, with one
        // difference worth naming: this row is only on screen while the fetch is
        // in flight, so its overflow — up to +234px at 320px in `de` (#1380) — is
        // one the gate caught in the first frame of a cell rather than at settle.
        // A spinner's caption is still a caption, and it wraps. It needs the
        // check button out of the row to have room to; see there.
        Expanded(child: AppText.bodyMedium(loc(context).loadingFirmwareInfo)),
      ],
    );
  }
}
