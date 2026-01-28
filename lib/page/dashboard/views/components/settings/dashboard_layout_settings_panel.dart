import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_preferences_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing dashboard layout.
///
/// Allows users to:
/// - Reorder widgets via drag-and-drop
/// - Toggle widget visibility
/// - Adjust column span (1-12)
/// - Select display mode (compact/normal/expanded)
class DashboardLayoutSettingsPanel extends ConsumerWidget {
  const DashboardLayoutSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(dashboardPreferencesProvider);
    final orderedWidgets = preferences.allWidgetsOrdered;

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

            // Legacy Mode Warning
            if (!preferences.useCustomLayout)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      AppGap.md(),
                      Expanded(
                        child: AppText.bodySmall(
                          'You are currently using the optimized standard layout. Enable Custom Layout above to customize.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls - Disabled opacity if not custom
            Opacity(
              opacity: preferences.useCustomLayout ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !preferences.useCustomLayout,
                child: Column(
                  children: [
                    ...orderedWidgets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final config = entry.value;
                      final spec =
                          DashboardWidgetSpecs.getById(config.widgetId);
                      if (spec == null) {
                        return const SizedBox.shrink();
                      }
                      return _WidgetConfigTile(
                        key: ValueKey(config.widgetId),
                        index: index,
                        totalCount: orderedWidgets.length,
                        spec: spec,
                        config: config,
                      );
                    }),
                  ],
                ),
              ),
            ),

            AppGap.xl(),

            // Allow Reset even in legacy mode? Or only custom?
            // Reset clears custom prefs, so it's fine.
            if (preferences.useCustomLayout)
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
      ),
    );
  }
}

/// Individual widget configuration tile with all controls.
class _WidgetConfigTile extends ConsumerWidget {
  const _WidgetConfigTile({
    super.key,
    required this.index,
    required this.totalCount,
    required this.spec,
    required this.config,
  });

  final int index;
  final int totalCount;
  final WidgetSpec spec;
  final GridWidgetConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Calculate constraints
    final constraints = spec.getConstraints(config.displayMode);
    final minColumns = constraints.minColumns;
    final defaultColumns = constraints.preferredColumns;

    // 2. Ensure current value respects min constraint (clamp)
    // If user saved a value lower than min (e.g. from a different mode), we clamp it for display/logic
    final effectiveColumnSpan = config.columnSpan ?? defaultColumns;
    final currentColumns = effectiveColumnSpan.clamp(minColumns, 12);

    // 3. Calculate divisions for slider (steps between min and max)
    final divisions = 12 - minColumns;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Move buttons + Name + Visibility
            Row(
              children: [
                // Up button
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: index > 0
                      ? () {
                          ref
                              .read(dashboardPreferencesProvider.notifier)
                              .reorder(index, index - 1);
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                // Down button
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: index < totalCount - 1
                      ? () {
                          ref
                              .read(dashboardPreferencesProvider.notifier)
                              .reorder(index, index + 1);
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                AppGap.sm(),
                Expanded(
                  child: AppText.labelLarge(spec.displayName),
                ),
                AppSwitch(
                  value: config.visible,
                  onChanged: (visible) {
                    ref
                        .read(dashboardPreferencesProvider.notifier)
                        .setVisibility(spec.id, visible);
                  },
                ),
              ],
            ),
            // Controls - only show if visible
            if (config.visible) ...[
              AppGap.lg(),
              // Display Mode
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: AppText.bodySmall('Mode:'),
                  ),
                  Expanded(
                    child: SegmentedButton<DisplayMode>(
                      segments: const [
                        ButtonSegment(
                          value: DisplayMode.compact,
                          label: Text('Compact'),
                        ),
                        ButtonSegment(
                          value: DisplayMode.normal,
                          label: Text('Normal'),
                        ),
                        ButtonSegment(
                          value: DisplayMode.expanded,
                          label: Text('Expanded'),
                        ),
                      ],
                      selected: {config.displayMode},
                      onSelectionChanged: (selection) {
                        ref
                            .read(dashboardPreferencesProvider.notifier)
                            .setWidgetMode(spec.id, selection.first);
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
              AppGap.md(),
              // Column Width Slider
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: AppText.bodySmall('Width:'),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentColumns.toDouble(),
                      min: minColumns.toDouble(),
                      max: 12,
                      divisions: divisions > 0 ? divisions : 1,
                      label: '$currentColumns',
                      onChanged: (value) {
                        final newValue = value.round();
                        // Only set if different from default
                        // Note: If newValue == default, we set to null to track "auto".
                        final columnSpan =
                            newValue == defaultColumns ? null : newValue;
                        ref
                            .read(dashboardPreferencesProvider.notifier)
                            .setColumnSpan(spec.id, columnSpan);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: AppText.labelMedium(
                      '$currentColumns/12',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
