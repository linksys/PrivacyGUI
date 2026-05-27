import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final asyncSystemInfo = ref.watch(systemInfoDataProvider);
    final banks = asyncSystemInfo.valueOrNull?.model.firmwareImages ?? const [];
    final isLoading = asyncSystemInfo.isLoading && banks.isEmpty;
    final activeBank = banks.where((b) => b.isActive).firstOrNull;
    final activeVersion =
        activeBank?.version ?? (banks.isEmpty ? null : banks.first.version);
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('Firmware Update'),
            AppGap.md(),
            if (isLoading)
              const _CardSkeleton()
            else if (activeVersion == null)
              AppText.bodyMedium('No firmware information available')
            else
              AppText.bodyMedium('Current version: $activeVersion'),
            AppGap.xl(),
            AppButton.primaryOutline(
              label: 'Update Firmware',
              onTap: () => context.pushNamed(RouteNamed.uspFirmwareUpdate),
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
