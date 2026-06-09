import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Firmware Update'),
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
                        AppText.labelSmall('Current Version',
                            color: colorScheme.onSurfaceVariant),
                        if (isLoading)
                          const _CardSkeleton()
                        else if (activeVersion == null)
                          AppText.bodyMedium('Not available')
                        else
                          AppText.bodyMedium(activeVersion),
                      ],
                    ),
                  ),
                  AppButton.text(
                    label: 'Update',
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
        AppText.bodyMedium('Loading firmware info…'),
      ],
    );
  }
}
