import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspPasswordCard extends StatelessWidget {
  final AdminUserUIModel adminUser;
  final VoidCallback onChangePassword;

  const UspPasswordCard({
    super.key,
    required this.adminUser,
    required this.onChangePassword,
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
            AppText.titleMedium(loc(context).routerPassword),
            AppGap.md(),
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.lock,
                      size: 20, color: colorScheme.onSurfaceVariant),
                  AppGap.md(),
                  Expanded(
                    child: AppText.labelLarge('\u2022' * 12),
                  ),
                  AppButton.text(
                    label: loc(context).change,
                    onTap: onChangePassword,
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
