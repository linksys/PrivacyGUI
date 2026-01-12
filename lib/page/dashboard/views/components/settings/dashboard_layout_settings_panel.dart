import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/sliver_dashboard_controller_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing dashboard layout.
///
/// Allows users to:
/// - Toggle between Standard (Adaptive) and Custom (Drag & Drop) layouts.
/// - Reset layout to defaults.
class DashboardLayoutSettingsPanel extends ConsumerWidget {
  const DashboardLayoutSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(dashboardPreferencesProvider);

    return SingleChildScrollView(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleMedium('Dashboard Layout'),
            AppGap.md(),
            AppText.bodySmall(
              'Customize your dashboard layout. Enable custom layout to unlock advanced controls.',
            ),
            AppGap.xl(),

            // Custom Layout Toggle
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: AppText.labelLarge('Enable Custom Layout'),
                subtitle: AppText.bodySmall(
                  'Unlock full control over widget order, width, and display modes. Defaults to unified flexible grid.',
                ),
                value: preferences.useCustomLayout,
                onChanged: (value) {
                  ref
                      .read(dashboardPreferencesProvider.notifier)
                      .toggleCustomLayout(value);
                },
              ),
            ),
            AppGap.lg(),

            // Info Message
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary),
                    AppGap.md(),
                    Expanded(
                      child: AppText.bodySmall(
                        preferences.useCustomLayout
                            ? 'You are using the customizable dashboard. Tap the "Edit" button on the dashboard to move and resize widgets.'
                            : 'Standard layout automatically optimizes widget placement based on your screen size.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppGap.xl(),

            // Reset Button
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: 'Reset Layout',
                onTap: () async {
                  // If custom layout is active, reset the sliver controller
                  if (preferences.useCustomLayout) {
                    await ref
                        .read(sliverDashboardControllerProvider.notifier)
                        .resetLayout();
                  }

                  // Reset general preferences
                  ref
                      .read(dashboardPreferencesProvider.notifier)
                      .resetToDefaults();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Layout reset to defaults'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
