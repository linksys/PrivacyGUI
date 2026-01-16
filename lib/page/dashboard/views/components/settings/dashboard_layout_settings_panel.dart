import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/sliver_dashboard_controller_provider.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodySmall(
            'Customize your dashboard layout. Enable custom layout to unlock advanced controls.',
          ),
          AppGap.xl(),

          // Custom Layout Toggle
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title:
                  AppText.labelLarge(loc(context).dashboardEnableCustomLayout),
              subtitle: AppText.bodySmall(
                'Unlock full control over widget order, width, and display modes. Defaults to unified flexible grid.',
              ),
              value: preferences.useCustomLayout,
              onChanged: (value) {
                ref
                    .read(dashboardPreferencesProvider.notifier)
                    .toggleCustomLayout(value);

                // When toggling OFF, exit edit mode and close panel
                if (!value) {
                  final controller =
                      ref.read(sliverDashboardControllerProvider);
                  controller.setEditMode(false);

                  if (context.mounted) {
                    Navigator.pop(context, 'toggle_off');
                  }
                }
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

          if (preferences.useCustomLayout) _buildHiddenWidgets(context, ref),

          // Reset Button - Only enabled when custom layout is active
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              label: loc(context).dashboardResetLayout,
              onTap: preferences.useCustomLayout
                  ? () async {
                      // 1. Reset the custom layout positions
                      await ref
                          .read(sliverDashboardControllerProvider.notifier)
                          .resetLayout();

                      // 2. Reset widget display modes to defaults
                      await ref
                          .read(dashboardPreferencesProvider.notifier)
                          .resetWidgetModes();

                      // 3. Close dialog and signal View to exit edit mode
                      if (context.mounted) {
                        Navigator.pop(context, 'reset');

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Layout reset to defaults'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenWidgets(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(sliverDashboardControllerProvider);
    // Use exportLayout() to get current Items since 'items' property might not be directly exposed or up to date in this context
    // Actually, DashboardController usually has 'items'. Let's try to access it.
    // If dynamic, safer to use exportLayout which returns List<Map>.
    final currentLayout = controller.exportLayout();
    final currentIds =
        currentLayout.map((e) => (e as Map)['id'] as String).toSet();

    final hiddenSpecs = DashboardWidgetSpecs.all.where((spec) {
      if (!_checkRequirements(spec)) return false;
      return !currentIds.contains(spec.id);
    }).toList();

    if (hiddenSpecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).dashboardHiddenWidgets),
        AppGap.sm(),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: hiddenSpecs.map((spec) {
              return ListTile(
                title: AppText.bodyMedium(spec.displayName),
                subtitle: spec.description != null
                    ? AppText.bodySmall(
                        spec.description!,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
                trailing: AppIconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onTap: () async {
                    await ref
                        .read(sliverDashboardControllerProvider.notifier)
                        .addWidget(spec.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${spec.displayName}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        AppGap.xl(),
      ],
    );
  }

  bool _checkRequirements(WidgetSpec spec) {
    if (spec.requirements.isEmpty) return true;

    for (final req in spec.requirements) {
      switch (req) {
        case WidgetRequirement.vpnSupported:
          if (!getIt.get<ServiceHelper>().isSupportVPN()) return false;
          break;
        case WidgetRequirement.none:
          break;
      }
    }
    return true;
  }
}
