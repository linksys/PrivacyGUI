import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_preferences_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing dashboard layout.
///
/// Allows users to select display modes for each dashboard widget.
class DashboardLayoutSettingsPanel extends ConsumerWidget {
  const DashboardLayoutSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(dashboardPreferencesProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium('Dashboard Layout'),
          AppGap.xl(),
          AppText.bodySmall('Customize how dashboard widgets are displayed.'),
          AppGap.xxl(),
          ...DashboardWidgetSpecs.all.map((spec) {
            final currentMode = preferences.getMode(spec.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildWidgetModeSelector(
                context,
                ref,
                spec.displayName,
                spec.id,
                currentMode,
              ),
            );
          }),
          AppGap.lg(),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              label: 'Reset to Defaults',
              onTap: () {
                ref
                    .read(dashboardPreferencesProvider.notifier)
                    .resetToDefaults();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetModeSelector(
    BuildContext context,
    WidgetRef ref,
    String label,
    String widgetId,
    DisplayMode currentMode,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppText.labelMedium(label),
        ),
        Expanded(
          flex: 3,
          child: SegmentedButton<DisplayMode>(
            segments: const [
              ButtonSegment(
                value: DisplayMode.compact,
                label: Text('Compact'),
                icon: Icon(Icons.view_compact_rounded, size: 18),
              ),
              ButtonSegment(
                value: DisplayMode.normal,
                label: Text('Normal'),
                icon: Icon(Icons.view_agenda_rounded, size: 18),
              ),
              ButtonSegment(
                value: DisplayMode.expanded,
                label: Text('Expanded'),
                icon: Icon(Icons.view_stream_rounded, size: 18),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (Set<DisplayMode> selection) {
              ref
                  .read(dashboardPreferencesProvider.notifier)
                  .setWidgetMode(widgetId, selection.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                Theme.of(context).textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
