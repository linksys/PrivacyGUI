import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 2 — Advanced WiFi settings.
///
/// Advanced settings (Band Steering, Node Steering, DFS, MLO, IPTV,
/// Airtime Fairness) are Linksys-proprietary vendor extensions that do not
/// have standard TR-181 paths.  These will be implemented in a future
/// iteration once vendor extension paths are confirmed.
class UspWifiAdvancedTab extends StatelessWidget {
  const UspWifiAdvancedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon.font(
                  Icons.construction_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                AppGap.md(),
                AppText.labelLarge('Advanced Settings'),
              ],
            ),
            AppGap.md(),
            AppText.bodyMedium(
              'Advanced WiFi settings (Band Steering, Node Steering, DFS, MLO, '
              'IPTV, Airtime Fairness) require Linksys vendor-specific TR-181 '
              'extensions and will be available in a future update.',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
