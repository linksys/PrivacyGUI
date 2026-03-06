import 'package:flutter/material.dart';
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
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium('System Actions'),
            AppGap.xl(),
            Row(
              children: [
                Expanded(
                  child: AppButton.primaryOutline(
                    label: 'Reboot',
                    onTap: onReboot,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: AppButton.primaryOutline(
                    label: 'Factory Reset',
                    onTap: onFactoryReset,
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
