import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';

import 'layout_item_factory.dart';
import 'dashboard_home_provider.dart';

const _sliverDashboardLayoutKey = 'sliver_dashboard_layout';

/// Provider for the Sliver Dashboard Controller.
///
/// Manages the drag-drop grid layout for the custom dashboard.
final sliverDashboardControllerProvider = StateNotifierProvider<
    SliverDashboardControllerNotifier, DashboardController>(
  (ref) => SliverDashboardControllerNotifier(ref),
);

/// Notifier for managing the Sliver Dashboard Controller.
class SliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  final Ref _ref;

  SliverDashboardControllerNotifier(this._ref)
      : super(_createDefaultController()) {
    _initializeLayout();
  }

  /// Creates a spec resolver based on hardware state.
  ///
  /// This follows IoC by creating the resolver at the composition root
  /// and injecting it into the factory.
  WidgetSpecResolver _createSpecResolver({
    required bool hasLanPort,
    required bool isHorizontalLayout,
  }) {
    return (WidgetSpec defaultSpec) {
      // Only Ports widget needs dynamic resolution currently
      if (defaultSpec.id == DashboardWidgetSpecs.ports.id) {
        return DashboardWidgetSpecs.getPortsSpec(
          hasLanPort: hasLanPort,
          isHorizontal: hasLanPort && isHorizontalLayout,
        );
      }
      return defaultSpec;
    };
  }

  /// Gets the current spec resolver based on hardware state.
  WidgetSpecResolver _getCurrentSpecResolver() {
    final dashboardState = _ref.read(dashboardHomeProvider);
    final hasLanPort = dashboardState.lanPortConnections.isNotEmpty;
    final isHorizontalLayout = dashboardState.isHorizontalLayout;

    return _createSpecResolver(
      hasLanPort: hasLanPort,
      isHorizontalLayout: isHorizontalLayout,
    );
  }

  static DashboardController _createDefaultController({
    WidgetSpecResolver? specResolver,
  }) {
    return DashboardController(
      initialSlotCount: 12,
      initialLayout: LayoutItemFactory.createDefaultLayout(
        specResolver: specResolver,
      ),
    );
  }

  /// Initialize layout: load from storage or create with dynamic constraints.
  Future<void> _initializeLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutJson = prefs.getString(_sliverDashboardLayoutKey);

    if (layoutJson != null) {
      // Load saved layout
      try {
        final layoutData = jsonDecode(layoutJson) as List<dynamic>;
        state.importLayout(layoutData);
      } catch (e) {
        debugPrint('Failed to load sliver dashboard layout: $e');
        // On failure, recreate with dynamic constraints
        _recreateWithDynamicConstraints();
      }
    } else {
      // No saved layout - create new with dynamic constraints
      _recreateWithDynamicConstraints();
    }
  }

  /// Recreate controller with dynamic constraints based on current hardware state.
  void _recreateWithDynamicConstraints() {
    state = _createDefaultController(
      specResolver: _getCurrentSpecResolver(),
    );
    // Optimize layout to fill gaps and compact the grid
    state.optimizeLayout();
  }

  /// Save layout to SharedPreferences.
  Future<void> saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = state.exportLayout();
    await prefs.setString(_sliverDashboardLayoutKey, jsonEncode(layoutData));
  }

  /// Reset layout to defaults using current hardware configuration.
  Future<void> resetLayout() async {
    // Get current hardware state
    final dashboardState = _ref.read(dashboardHomeProvider);
    final hasLanPort = dashboardState.lanPortConnections.isNotEmpty;
    final isHorizontalLayout = dashboardState.isHorizontalLayout;

    // Create resolver with current hardware config (IoC)
    final resolver = _createSpecResolver(
      hasLanPort: hasLanPort,
      isHorizontalLayout: isHorizontalLayout,
    );

    state = _createDefaultController(specResolver: resolver);
    // Optimize layout to fill gaps and compact the grid
    state.optimizeLayout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sliverDashboardLayoutKey);
  }

  /// Update item constraints (min/max width) for a specific display mode.
  ///
  /// This is used to sync the controller's internal constraints with the
  /// visual display mode (e.g., when switching to Expanded).
  Future<void> updateItemConstraints(
    String id,
    DisplayMode mode, {
    WidgetGridConstraints? overrideConstraints,
  }) async {
    WidgetGridConstraints? constraints;

    if (overrideConstraints != null) {
      constraints = overrideConstraints;
    } else {
      // Lookup spec from all specs (since no static helper exists)
      WidgetSpec? spec;
      try {
        spec = DashboardWidgetSpecs.all.firstWhere((s) => s.id == id);
        constraints = spec.constraints[mode];
      } catch (_) {
        return;
      }
    }

    if (constraints == null) return;

    // Export current layout, modify the specific item, and re-import
    final currentLayout = state.exportLayout();
    bool changed = false;

    final newLayout = currentLayout.map((item) {
      if (item is Map && item['id'] == id) {
        final mutableItem = Map<String, dynamic>.from(item);
        // Update constraints using camelCase keys (standard package convention)
        mutableItem['minW'] = constraints!.minColumns;
        mutableItem['maxW'] = constraints.maxColumns.toDouble();

        // Also ensure current width respects new min/max
        num w = mutableItem['w'] ?? 1;
        if (w < constraints.minColumns) {
          mutableItem['w'] = constraints.minColumns;
        }
        if (w > constraints.maxColumns) {
          mutableItem['w'] = constraints.maxColumns; // Clamp
        }

        changed = true;
        return mutableItem;
      }
      return item;
    }).toList();

    if (changed) {
      state.importLayout(newLayout);
      await saveLayout();
    }
  }

  /// Force update an item's size (w/h).
  ///
  /// Used to correct invalid sizes after a resize operation (e.g. enforcing minWidth).
  Future<void> updateItemSize(String id, int w, int h) async {
    final currentLayout = state.exportLayout();
    bool changed = false;

    final newLayout = currentLayout.map((item) {
      if (item is Map && item['id'] == id) {
        final mutableItem = Map<String, dynamic>.from(item);
        if (mutableItem['w'] != w || mutableItem['h'] != h) {
          mutableItem['w'] = w;
          mutableItem['h'] = h;
          changed = true;
        }
        return mutableItem;
      }
      return item;
    }).toList();

    if (changed) {
      state.importLayout(newLayout);
      await saveLayout();
    }
  }

  /// Add a widget to the dashboard layout.
  ///
  /// Appends the widget to the bottom of the current layout.
  Future<void> addWidget(String id) async {
    // 1. Check if already exists
    final currentLayout = state.exportLayout();
    if (currentLayout.any((item) => (item as Map)['id'] == id)) {
      return; // Already exists
    }

    // 2. Get spec
    final spec = DashboardWidgetSpecs.getById(id);
    if (spec == null) return;

    // 3. Calculate position (bottom)
    int maxY = 0;
    if (currentLayout.isNotEmpty) {
      for (final item in currentLayout) {
        final map = item as Map;
        final y = map['y'] as int;
        final h = map['h'] as int;
        if (y + h > maxY) {
          maxY = y + h;
        }
      }
    }

    // 4. Create new item
    // Use LayoutItemFactory logic but manually construct map since we are dealing with export/import format
    // Or better, creating a LayoutItem and adding to controller?
    // Controller.add() expects LayoutItem. But we want to persist details like minW/maxW.
    // LayoutItemFactory returns LayoutItem.
    // The exportLayout returns List<dynamic> (Maps).
    // Let's create LayoutItem first to get correct dimensions.

    final item = LayoutItemFactory.fromSpec(
      spec,
      x: 0,
      y: maxY,
      displayMode: DisplayMode.normal, // Default to normal when adding
    );

    // 5. Append via import mechanism
    // Construct map manually to ensure all properties (min/max) are set
    final newItemMap = {
      'id': item.id,
      'x': item.x,
      'y': item.y,
      'w': item.w,
      'h': item.h,
      // Use camelCase for package compatibility if needed, but package usually handles underscores too?
      // Looking at updateItemConstraints, we used 'minW'.
      'minW': item.minW,
      'maxW': item.maxW,
      'minH': item.minH,
      'maxH': item.maxH,
    };

    final newLayout = [...currentLayout, newItemMap];

    state.importLayout(newLayout);
    await saveLayout();
  }

  /// Remove a widget from the dashboard layout.
  Future<void> removeWidget(String id) async {
    final currentLayout = state.exportLayout();
    final newLayout =
        currentLayout.where((item) => (item as Map)['id'] != id).toList();

    if (newLayout.length != currentLayout.length) {
      state.importLayout(newLayout);
      await saveLayout();
    }
  }
}
