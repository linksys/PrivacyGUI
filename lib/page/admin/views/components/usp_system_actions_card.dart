import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspSystemActionsCard extends StatelessWidget {
  final VoidCallback onReboot;
  final VoidCallback onFactoryReset;

  const UspSystemActionsCard({
    super.key,
    required this.onReboot,
    required this.onFactoryReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).systemActions),
            AppGap.md(),
            Row(
              children: [
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Icon(Icons.restart_alt,
                            size: 40, color: colorScheme.primary),
                        AppGap.md(),
                        AppButton.primaryOutline(
                          identifier: 'admin-reboot',
                          label: loc(context).reboot,
                          onTap: onReboot,
                        ),
                      ],
                    ),
                  ),
                ),
                AppGap.sm(),
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Icon(Icons.settings_backup_restore,
                            size: 40, color: colorScheme.error),
                        AppGap.md(),
                        AppButton.primaryOutline(
                          identifier: 'admin-factory-reset',
                          label: loc(context).factoryReset,
                          onTap: onFactoryReset,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
