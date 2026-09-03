import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Admin-view entry card for the manual firmware update flow.
///
/// Shows the current firmware version and a CTA into the dedicated update
/// page; full bank details live on the update page itself.
class FirmwareUpdateCard extends ConsumerWidget {
  const FirmwareUpdateCard({super.key});

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
        // E2E arrival anchor for the Administration-page entry into the manual
        // firmware update flow (PrivacyGUI-USP-E2E#85). Naming matches the
        // `firmware-*` convention already used on the update page itself.
        identifier: 'firmware-card',
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).firmwareUpdate),
            AppGap.md(),
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.system_update,
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
                          // Pin the current-version value so E2E can assert it
                          // without a localized text match. AppText carries no
                          // identifier of its own, so the hook goes on a
                          // wrapping Semantics boundary — the shape
                          // usp_statistics_view.dart uses for its tab hooks.
                          Semantics(
                            identifier: 'firmware-card-version',
                            child: AppText.bodyMedium(activeVersion),
                          ),
                      ],
                    ),
                  ),
                  // Hidden while the version is unknown, which is both what the
                  // button means — there is nothing to compare against yet — and
                  // what makes the skeleton readable: the button costs this row
                  // 60–110px depending on locale, and at 320px that is most of what
                  // the caption beside the spinner has to live in (#1380).
                  if (!isLoading)
                    AppButton.text(
                      label: loc(context).update,
                      // The CTA that blocks automation today — the real user
                      // entry into the manual update page (PrivacyGUI-USP-E2E#85).
                      identifier: 'firmware-card-update',
                      onTap: () =>
                          context.pushNamed(RouteNamed.uspFirmwareUpdate),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        // `Update` button out of the row to have room to; see there.
        Expanded(child: AppText.bodyMedium(loc(context).loadingFirmwareInfo)),
      ],
    );
  }
}
