import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

import 'layout_item_factory.dart';

const _sliverDashboardLayoutKey = 'sliver_dashboard_layout';

/// Provider for the Sliver Dashboard Controller.
///
/// Manages the drag-drop grid layout for the custom dashboard.
final sliverDashboardControllerProvider = StateNotifierProvider<
    SliverDashboardControllerNotifier, DashboardController>(
  (ref) => SliverDashboardControllerNotifier(),
);

/// Notifier for managing the Sliver Dashboard Controller.
class SliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  SliverDashboardControllerNotifier() : super(_createDefaultController()) {
    _loadLayout();
  }

  static DashboardController _createDefaultController() {
    return DashboardController(
      initialSlotCount: 12,
      initialLayout: LayoutItemFactory.createDefaultLayout(),
    );
  }

  /// Load layout from SharedPreferences.
  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutJson = prefs.getString(_sliverDashboardLayoutKey);
    if (layoutJson != null) {
      try {
        final layoutData = jsonDecode(layoutJson) as List<dynamic>;
        state.importLayout(layoutData);
      } catch (e) {
        debugPrint('Failed to load sliver dashboard layout: $e');
      }
    }
  }

  /// Save layout to SharedPreferences.
  Future<void> saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = state.exportLayout();
    await prefs.setString(_sliverDashboardLayoutKey, jsonEncode(layoutData));
  }

  /// Reset layout to defaults.
  Future<void> resetLayout() async {
    state = _createDefaultController();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sliverDashboardLayoutKey);
  }

  /// Update item constraints (min/max width) for a specific display mode.
  ///
  /// This is used to sync the controller's internal constraints with the
  /// visual display mode (e.g., when switching to Expanded).
  Future<void> updateItemConstraints(String id, DisplayMode mode) async {
    // Lookup spec from all specs (since no static helper exists)
    WidgetSpec? spec;
    try {
      spec = DashboardWidgetSpecs.all.firstWhere((s) => s.id == id);
    } catch (_) {
      return;
    }

    final constraints = spec.constraints[mode];
    if (constraints == null) return;

    // Export current layout, modify the specific item, and re-import
    final currentLayout = state.exportLayout();
    bool changed = false;

    final newLayout = currentLayout.map((item) {
      if (item is Map && item['id'] == id) {
        final mutableItem = Map<String, dynamic>.from(item);
        // Update constraints using camelCase keys (standard package convention)
        mutableItem['minW'] = constraints.minColumns;
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
}
