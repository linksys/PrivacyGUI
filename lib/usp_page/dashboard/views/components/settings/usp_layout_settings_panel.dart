import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing USP dashboard layout.
///
/// Allows users to:
/// - View and re-add hidden widgets.
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

          _buildHiddenWidgets(context, ref),

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

  Widget _buildHiddenWidgets(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final currentLayout = controller.exportLayout();
    final currentIds =
        currentLayout.map((e) => (e as Map)['id'] as String).toSet();

    final hiddenSpecs = UspWidgetSpecs.all.where((spec) {
      return !currentIds.contains(spec.id);
    }).toList();

    if (hiddenSpecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge('Hidden Widgets'),
        AppGap.sm(),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: hiddenSpecs.map((spec) {
              return ListTile(
                title: AppText.bodyMedium(spec.displayName),
                trailing: AppIconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onTap: () async {
                    await ref
                        .read(uspSliverDashboardControllerProvider.notifier)
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
}
