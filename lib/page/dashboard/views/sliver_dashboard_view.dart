import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/jiggle_shake.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/factories/dashboard_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../providers/sliver_dashboard_controller_provider.dart';

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
  List<dynamic>? _initialLayoutSnapshot;
  DashboardLayoutPreferences? _initialPrefsSnapshot;

  void _enterEditMode() {
    final controller = ref.read(sliverDashboardControllerProvider);
    _initialLayoutSnapshot = controller.exportLayout();
    _initialPrefsSnapshot = ref.read(dashboardPreferencesProvider);

    setState(() {
      _isEditMode = true;
    });
    controller.setEditMode(true);
  }

  void _exitEditMode({bool save = true}) async {
    final controller = ref.read(sliverDashboardControllerProvider);

    if (!save) {
      // Restore initial layout
      if (_initialLayoutSnapshot != null) {
        controller.importLayout(_initialLayoutSnapshot!);
        await ref.read(sliverDashboardControllerProvider.notifier).saveLayout();
      }

      // Restore initial preferences (display modes)
      if (_initialPrefsSnapshot != null) {
        await ref
            .read(dashboardPreferencesProvider.notifier)
            .restoreSnapshot(_initialPrefsSnapshot!);
      }
    }

    setState(() {
      _isEditMode = false;
      _initialLayoutSnapshot = null;
      _initialPrefsSnapshot = null;
    });
    controller.setEditMode(false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(sliverDashboardControllerProvider);
    final preferences = ref.watch(dashboardPreferencesProvider);

    // Use UI Kit's currentMaxColumns to stay synchronized with main padding
    // This gets the correct column count accounting for page margins
    final uiKitColumns = context.currentMaxColumns;

    return Column(
      children: [
        // Top padding to match Standard Layout
        const SizedBox(height: 32.0),

        // Edit Toolbar (visible only in edit mode)
        if (_isEditMode) _buildEditToolbar(context),

        // Fixed Home Title
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: DashboardHomeTitle(
            showSettings: !_isEditMode,
            onEditPressed: _isEditMode ? null : _enterEditMode,
          ),
        ),

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
              final mode = preferences.getMode(item.id);
              return _buildItemWidget(context, item, mode, _isEditMode);
            },
            onItemResizeEnd: (item) {
              _handleResizeEnd(context, item);
            },
          ),
        ),
      ],
    );
  }

  void _handleResizeEnd(BuildContext context, LayoutItem item) {
    // Reactive Constraint Enforcement
    // This fixes the issue where items can be resized smaller than minWidth against grid edges.
    final preferences = ref.read(dashboardPreferencesProvider);
    final mode = preferences.getMode(item.id);

    WidgetSpec? spec;
    try {
      spec = DashboardWidgetSpecs.all.firstWhere((s) => s.id == item.id);
    } catch (_) {
      return;
    }

    final constraints = spec.constraints[mode];
    if (constraints == null) return;

    bool violated = false;
    int newW = item.w;
    int newH = item.h;

    if (item.w < constraints.minColumns) {
      newW = constraints.minColumns;
      violated = true;
    }

    // Enforce Height Constraints
    // For strict/column-based strategies, height is fixed
    if (constraints.heightStrategy is ColumnBasedHeightStrategy) {
      final strictHeight = constraints.getPreferredHeightCells(columns: newW);
      if (item.h != strictHeight) {
        newH = strictHeight;
        violated = true;
      }
    } else {
      // For other strategies, enforce minHeightRows
      if (item.h < constraints.minHeightRows) {
        newH = constraints.minHeightRows;
        violated = true;
      }
    }

    if (violated) {
      ref
          .read(sliverDashboardControllerProvider.notifier)
          .updateItemSize(item.id, newW, newH);
    } else {
      // Save layout on normal resize end
      ref.read(sliverDashboardControllerProvider.notifier).saveLayout();
    }
  }
// ... (rest of class)

  Widget _buildEditToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppText.labelLarge(
              'Edit Layout',
              color: Theme.of(context).colorScheme.primary,
            ),
            const Spacer(),
            AppIconButton(
              icon: const Icon(Icons.tune),
              onTap: () => _openLayoutSettings(context),
            ),
            AppGap.sm(),
            // Cancel Button
            AppIconButton(
              icon: const Icon(Icons.close),
              onTap: () => _exitEditMode(save: false),
            ),
            AppGap.sm(),
            // Save/Done Button
            AppIconButton(
              icon: const Icon(Icons.check),
              onTap: () => _exitEditMode(save: true),
            ),
          ],
        ),
      ),
    );
  }

  void _openLayoutSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: AppText.titleMedium('Dashboard Settings'),
        content: const DashboardLayoutSettingsPanel(),
        actions: [
          AppButton(
            label: 'Close',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildItemWidget(BuildContext context, LayoutItem item,
      DisplayMode displayMode, bool isEditMode) {
    // Use factory to build widget
    final widget = DashboardWidgetFactory.buildAtomicWidget(
      item.id,
      displayMode: displayMode,
    );

    // Handle unknown widget
    if (widget == null) {
      return AppCard(
        child: Center(
          child: AppText.bodyMedium('Unknown: ${item.id}'),
        ),
      );
    }

    // Wrap in AppCard based on factory rules
    final Widget displayedWidget;
    if (!DashboardWidgetFactory.shouldWrapInCard(item.id)) {
      displayedWidget = widget;
    } else {
      displayedWidget = AppCard(
        padding: EdgeInsets.zero,
        child: widget,
      );
    }

    // If in Edit Mode, overlay a "View Mode" toggle button
    if (isEditMode) {
      return JiggleShake(
        active: true,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // The widget itself (blocked interactions)
            AbsorbPointer(
              absorbing: true,
              child: displayedWidget,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Theme(
                data: Theme.of(context).copyWith(
                  // Use dark surface for menu contrast if needed, or default
                  popupMenuTheme: PopupMenuThemeData(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: PopupMenuButton<DisplayMode>(
                  initialValue: displayMode,
                  tooltip: 'Change View Mode',
                  onSelected: (mode) => _updateDisplayMode(context, item, mode),
                  offset: const Offset(0, 32),
                  itemBuilder: (context) => DisplayMode.values.map((mode) {
                    final isSelected = mode == displayMode;
                    return PopupMenuItem<DisplayMode>(
                      value: mode,
                      height: 40,
                      child: Row(
                        children: [
                          Icon(
                            _getModeIcon(mode),
                            size: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          AppGap.sm(),
                          Text(
                            mode.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      // Shadow removed from prev step
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getModeIcon(displayMode),
                          size: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        AppGap.xs(),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Remove Button (Top-Left) - Only if canHide is true
            if (DashboardWidgetSpecs.getById(item.id)?.canHide ?? true)
              Positioned(
                left: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(sliverDashboardControllerProvider.notifier)
                        .removeWidget(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed ${item.id}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

  void _updateDisplayMode(
      BuildContext context, LayoutItem item, DisplayMode nextMode) {
    // 1. Update preferences provider (unified state)
    ref
        .read(dashboardPreferencesProvider.notifier)
        .setWidgetMode(item.id, nextMode);

    // 2. Get specs to update constraints
    final spec = DashboardWidgetSpecs.getById(item.id);
    if (spec == null) return;

    final constraints = spec.getConstraints(nextMode);

    // Use unified height calculation
    final preferredW = constraints.preferredColumns;
    final preferredH = constraints.getPreferredHeightCells(columns: preferredW);
    final (minH, maxH) = constraints.getHeightRange();

    // 3. Update the item via Export -> Modify -> Import -> Save
    final controller = ref.read(sliverDashboardControllerProvider);
    final List<dynamic> currentLayout = controller.exportLayout();

    final index =
        currentLayout.indexWhere((itemMap) => itemMap['id'] == item.id);
    if (index != -1) {
      // Create modified item map
      final Map<String, dynamic> oldItem =
          Map<String, dynamic>.from(currentLayout[index]);

      // FIX: Reset size to preferred dimensions for the new mode
      // This ensures the item starts in a valid state (w >= minW)
      oldItem['w'] = preferredW;
      oldItem['h'] = preferredH;

      // Update constraints using BOTH keys ensures coverage
      oldItem['min_w'] = constraints.minColumns.toInt();
      oldItem['minW'] = constraints.minColumns.toInt();

      oldItem['max_w'] = constraints.maxColumns.toDouble();
      oldItem['maxW'] = constraints.maxColumns.toDouble();

      oldItem['min_h'] = minH.toInt();
      oldItem['minH'] = minH.toInt();

      oldItem['max_h'] = maxH;
      oldItem['maxH'] = maxH;

      // Lock Logic (Removed): MinWidth is now enforced via onItemResizeEnd hook
      // Topology is now resizable but constrained.
      bool canResize = true;
      oldItem['resizable'] = canResize;
      oldItem['isResizable'] = canResize;
      oldItem['resizeable'] = canResize;

      // Update list
      currentLayout[index] = oldItem;

      // Apply and Save
      controller.importLayout(currentLayout);
      ref.read(sliverDashboardControllerProvider.notifier).saveLayout();
    }
  }
}
