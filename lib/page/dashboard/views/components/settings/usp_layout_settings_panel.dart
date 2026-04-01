import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing USP dashboard layout.
///
/// Allows users to:
/// - View and re-add available widgets (built-in and app widgets).
/// - Reset layout to defaults.
class UspLayoutSettingsPanel extends ConsumerWidget {
  const UspLayoutSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                AppGap.md(),
                Expanded(
                  child: AppText.bodySmall(
                    'Drag and drop widgets to reorder. Use the resize handles to adjust size. '
                    'Remove widgets with the close button — re-add them here.',
                  ),
                ),
              ],
            ),
          ),
          AppGap.xl(),

          _buildPresetSection(context, ref),

          _buildAvailableWidgets(context, ref),

          // Reset Button
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              label: 'Reset Layout',
              onTap: () async {
                await ref
                    .read(uspLayoutPreferencesProvider.notifier)
                    .resetToDefaults();

                if (context.mounted) {
                  Navigator.pop(context, 'reset');

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
    );
  }

  Widget _buildPresetSection(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uspLayoutPreferencesProvider);
    final currentPreset = prefs.selectedPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge('Dashboard Style'),
        AppGap.sm(),
        AppCard(
          child: Row(
            children: [
              if (currentPreset != null) ...[
                Icon(currentPreset.icon, size: 20),
                AppGap.sm(),
                Expanded(
                  child: AppText.bodyMedium(currentPreset.displayName),
                ),
              ] else
                Expanded(
                  child: AppText.bodyMedium('No preset selected'),
                ),
              AppButton.text(
                label: 'Change',
                onTap: () async {
                  final result = await showPresetSelectionDialog(
                    context,
                    currentPreset: currentPreset,
                  );
                  if (result != null && context.mounted) {
                    await ref
                        .read(uspLayoutPreferencesProvider.notifier)
                        .selectPreset(result);
                    if (context.mounted) {
                      Navigator.pop(context, 'preset_changed');
                    }
                  }
                },
              ),
            ],
          ),
        ),
        AppGap.xl(),
      ],
    );
  }

  Widget _buildAvailableWidgets(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final currentLayout = controller.exportLayout();
    final currentIds =
        currentLayout.map((e) => (e as Map)['id'] as String).toSet();

    final allSpecs = ref.watch(allWidgetSpecsProvider);

    // Separate built-in and app widgets
    final availableSpecs = allSpecs.where((spec) {
      return !currentIds.contains(spec.id);
    }).toList();

    final builtInSpecs = availableSpecs.where((spec) {
      return UspWidgetSpecs.all.any((builtIn) => builtIn.id == spec.id);
    }).toList();

    final appWidgetSpecs = availableSpecs.where((spec) {
      return !UspWidgetSpecs.all.any((builtIn) => builtIn.id == spec.id);
    }).toList();

    if (availableSpecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge('Available Widgets'),
        AppGap.sm(),

        // Built-in Widgets Section
        if (builtInSpecs.isNotEmpty) ...[
          _buildWidgetSection(
            context,
            ref,
            title: 'Built-in Widgets',
            specs: builtInSpecs,
          ),
          AppGap.md(),
        ],

        // App Widget Cards Section
        if (appWidgetSpecs.isNotEmpty) ...[
          _buildWidgetSection(
            context,
            ref,
            title: 'App Widget Cards',
            specs: appWidgetSpecs,
          ),
        ],

        AppGap.xl(),
      ],
    );
  }

  Widget _buildWidgetSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<WidgetSpec> specs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AppText.bodySmall(title),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: specs.map((spec) {
              return ListTile(
                title: AppText.bodyMedium(spec.displayName),
                trailing: AppIconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onTap: () async {
                    await ref
                        .read(uspSliverDashboardControllerProvider.notifier)
                        .addWidget(spec.id, spec: spec);

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
      ],
    );
  }
}
