import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';
import 'package:privacy_gui/page/dashboard/providers/sliver_dashboard_mode_provider.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../providers/sliver_dashboard_controller_provider.dart';
import 'components/_components.dart';

/// Drag-and-drop dashboard view using sliver_dashboard.
///
/// This replaces CustomDashboardLayoutStrategy when edit mode is active.
class SliverDashboardView extends ConsumerStatefulWidget {
  const SliverDashboardView({super.key});

  @override
  ConsumerState<SliverDashboardView> createState() =>
      _SliverDashboardViewState();
}

class _SliverDashboardViewState extends ConsumerState<SliverDashboardView> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(sliverDashboardControllerProvider);
    final itemModes = ref.watch(sliverDashboardModeProvider);

    // Use UI Kit's currentMaxColumns to stay synchronized with main padding
    // This gets the correct column count accounting for page margins
    final uiKitColumns = context.currentMaxColumns;

    return Column(
      children: [
        // Top padding to match Standard Layout
        const SizedBox(height: 32.0),
        // Edit mode toggle bar
        _buildEditModeBar(context),

        // Dashboard grid
        Expanded(
          child: Dashboard(
            controller: controller,
            // Use a single-point breakpoint map based on UI Kit's calculation
            // This ensures column count matches UI Kit's responsive system
            breakpoints: {0: uiKitColumns},
            slotAspectRatio: 1.0,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridStyle: GridStyle(
              lineColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              lineWidth: 1,
              fillColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, item) {
              final mode = itemModes[item.id] ?? DisplayMode.normal;
              return _buildItemWidget(context, item, mode, _isEditMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditModeBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppText.titleMedium('Dashboard'),
          const Spacer(),
          if (_isEditMode) ...[
            AppButton.text(
              label: 'Reset',
              onTap: () {
                ref
                    .read(sliverDashboardControllerProvider.notifier)
                    .resetLayout();
                ref.read(sliverDashboardModeProvider.notifier).resetModes();
              },
            ),
            AppGap.md(),
          ],
          AppButton(
            label: _isEditMode ? 'Done' : 'Edit',
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onTap: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              final controller = ref.read(sliverDashboardControllerProvider);
              controller.setEditMode(_isEditMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemWidget(BuildContext context, LayoutItem item,
      DisplayMode displayMode, bool isEditMode) {
    // Map layout item ID to actual atomic widget, passing the displayMode
    final widget = switch (item.id) {
      'internet_status' => InternetConnectionWidget(displayMode: displayMode),
      'internet_status_only' => const DashboardInternetStatus(),
      'master_node_info' => const DashboardMasterNodeInfo(),
      'ports' => const DashboardPorts(),
      'speed_test' => const DashboardSpeedTest(),
      'network_stats' => const DashboardNetworkStats(),
      'topology' => DashboardTopology(displayMode: displayMode),
      'wifi_grid' => DashboardWiFiGrid(displayMode: displayMode),
      'quick_panel' => DashboardQuickPanel(
          displayMode: displayMode,
          useAppCard: false,
        ),
      _ => AppCard(
          child: Center(
              child: AppText.bodyMedium(
                  'Unknown: ${item.id}\n${displayMode.name}')),
        ),
    };

    // Wrap in AppCard for visual consistency (except wifi_grid/vpn)
    final Widget displayedWidget;
    if (item.id == 'wifi_grid' || item.id == 'vpn') {
      displayedWidget = widget;
    } else {
      // Atomic widgets have internal padding, so we use zero padding for the wrapper card
      displayedWidget = AppCard(
        padding: EdgeInsets.zero,
        child: widget,
      );
    }

    // If in Edit Mode, overlay a "View Mode" toggle button
    if (isEditMode) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // The widget itself (blocked interactions)
          AbsorbPointer(
            absorbing: true,
            child: displayedWidget,
          ),
          // Toggle Button
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                _cycleDisplayMode(context, item, displayMode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getModeIcon(displayMode),
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    AppGap.xs(),
                    AppText.labelSmall(
                      displayMode.name.toUpperCase(),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Non-edit mode
    return displayedWidget;
  }

  IconData _getModeIcon(DisplayMode mode) {
    return switch (mode) {
      DisplayMode.compact => Icons.view_compact,
      DisplayMode.normal => Icons.view_module,
      DisplayMode.expanded => Icons.view_quilt,
    };
  }

  void _cycleDisplayMode(
      BuildContext context, LayoutItem item, DisplayMode currentMode) {
    // Cycle: Compact -> Normal -> Expanded -> Compact
    final nextIndex = (currentMode.index + 1) % DisplayMode.values.length;
    final nextMode = DisplayMode.values[nextIndex];

    // 1. Update Mode Provider
    ref.read(sliverDashboardModeProvider.notifier).setMode(item.id, nextMode);

    // 2. Get specs to update constraints
    final spec = DashboardWidgetSpecs.getById(item.id);
    if (spec == null) return;

    final constraints = spec.getConstraints(nextMode);

    // Convert HeightStrategy to min/max height
    final (minH, maxH, preferredH) = _getHeightConstraints(constraints);

    // 4. Update the item via Export -> Modify -> Import -> Save
    final controller = ref.read(sliverDashboardControllerProvider);
    // exportLayout returns List<dynamic> where each item is a Map<String, dynamic>
    final List<dynamic> currentLayout = controller.exportLayout();

    final index =
        currentLayout.indexWhere((itemMap) => itemMap['id'] == item.id);
    if (index != -1) {
      // Create modified item map
      final Map<String, dynamic> oldItem =
          Map<String, dynamic>.from(currentLayout[index]);
      final int currentW = oldItem['w'] as int;
      final int currentH = oldItem['h'] as int;

      // Update constraints using BOTH keys ensures coverage
      // Standardize ALL to Int for Grid Units
      oldItem['min_w'] = constraints.minColumns.toInt();
      oldItem['minW'] = constraints.minColumns.toInt();

      oldItem['max_w'] = constraints.maxColumns.toDouble();
      oldItem['maxW'] = constraints.maxColumns.toDouble();

      oldItem['min_h'] = minH.toInt();
      oldItem['minH'] = minH.toInt();

      oldItem['max_h'] = maxH;
      oldItem['maxH'] = maxH;

      // Lock Logic: Topology in Expanded mode is fixed size (can move, cannot resize)
      bool canResize = true;
      if (item.id == 'topology' && nextMode == DisplayMode.expanded) {
        canResize = false;
      }
      oldItem['resizable'] = canResize;
      oldItem['isResizable'] = canResize; // CamelCase fallback
      oldItem['resizeable'] = canResize; // Typo fallback

      // Calculate target dimensions
      int targetW = currentW > constraints.preferredColumns
          ? constraints.preferredColumns
          : currentW;
      int targetH = currentH > preferredH ? preferredH : currentH;

      final newW =
          targetW.clamp(constraints.minColumns, constraints.maxColumns.toInt());
      final newH = targetH.clamp(minH.toInt(), maxH.toInt());

      oldItem['w'] = newW;
      oldItem['h'] = newH;

      // Update list
      currentLayout[index] = oldItem;

      // Apply and Save
      controller.importLayout(currentLayout);
      ref.read(sliverDashboardControllerProvider.notifier).saveLayout();
    }
  }

  (double minH, double maxH, int preferredH) _getHeightConstraints(
      WidgetGridConstraints constraints) {
    final strategy = constraints.heightStrategy;
    int h = 4; // default safety
    double min = constraints.minHeightRows.toDouble();
    double max = 12.0;

    if (strategy is IntrinsicHeightStrategy) {
      h = 6; // Provide ample space for intrinsic items like WiFi Grid by default
    } else if (strategy is ColumnBasedHeightStrategy) {
      // HeightStrategy.strict() maps to this.
      // Based on DashboardWidgetSpecs usage, the multiplier IS the slot count.
      h = strategy.multiplier.ceil();
    } else if (strategy is AspectRatioHeightStrategy) {
      h = (constraints.preferredColumns / strategy.ratio).ceil();
    }

    return (min, max, h);
  }
}
