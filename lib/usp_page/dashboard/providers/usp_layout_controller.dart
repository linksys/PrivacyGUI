import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/usp_widget_specs.dart';

const _uspLayoutKey = 'usp_sliver_dashboard_layout';

/// Provider for the USP Sliver Dashboard Controller.
final uspSliverDashboardControllerProvider = StateNotifierProvider<
    UspSliverDashboardControllerNotifier, DashboardController>(
  (ref) => UspSliverDashboardControllerNotifier(),
);

/// Manages the drag-drop grid layout for the USP custom dashboard.
///
/// Simplified from the regular dashboard version:
/// - No A2UI widget registry
/// - No dynamic hardware-dependent constraints
/// - Uses [UspWidgetSpecs] exclusively
class UspSliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  UspSliverDashboardControllerNotifier() : super(_createDefaultController()) {
    _initializeLayout();
  }

  static DashboardController _createDefaultController() {
    return DashboardController(
      initialSlotCount: 12,
      initialLayout: UspWidgetSpecs.createDefaultLayout(),
    );
  }

  /// Load saved layout from SharedPreferences, or keep the constructor default.
  ///
  /// The constructor already initialises with [UspWidgetSpecs.createDefaultLayout].
  /// This method only replaces the state when a **valid** saved layout exists.
  /// If the saved layout is stale (missing widget IDs from new cards), it is
  /// discarded and the default layout is persisted instead.
  Future<void> _initializeLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutJson = prefs.getString(_uspLayoutKey);

    if (layoutJson == null) {
      // No saved layout — persist the constructor's default for next time.
      await saveLayout();
      return;
    }

    try {
      final layoutData = jsonDecode(layoutJson) as List<dynamic>;

      // Validate: saved layout must include every widget in the current spec
      final savedIds = layoutData
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toSet();
      final requiredIds = UspWidgetSpecs.all.map((s) => s.id).toSet();
      final missingIds = requiredIds.difference(savedIds);

      if (missingIds.isNotEmpty) {
        debugPrint(
            'USP layout missing widgets: $missingIds — keeping default');
        // Discard stale layout, persist the constructor's default.
        await saveLayout();
        return;
      }

      // Create a NEW controller then swap via state= so Riverpod
      // properly notifies listeners (avoids mutating the existing
      // controller in-place which can desync the render tree).
      final newController = _createDefaultController();
      newController.importLayout(layoutData);
      state = newController;
    } catch (e) {
      debugPrint('Failed to load USP sliver dashboard layout: $e');
      // Keep the constructor's default — no state change needed.
      await saveLayout();
    }
  }

  /// Persist current layout to SharedPreferences.
  Future<void> saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = state.exportLayout();
    await prefs.setString(_uspLayoutKey, jsonEncode(layoutData));
  }

  /// Reset to default layout and clear persisted data.
  Future<void> resetLayout() async {
    state = _createDefaultController();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uspLayoutKey);
  }

  /// Force update an item's size (used after resize constraint enforcement).
  Future<void> updateItemSize(String id, int w, int h) async {
    final currentLayout = state.exportLayout();
    bool changed = false;

    final newLayout = currentLayout.map((item) {
      if (item['id'] == id) {
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
      final newController = _createDefaultController();
      newController.importLayout(newLayout);
      state = newController;
      await saveLayout();
    }
  }

  /// Add a widget to the dashboard layout (appended at the bottom).
  Future<void> addWidget(String id) async {
    final currentLayout = state.exportLayout();
    if (currentLayout.any((item) => (item as Map)['id'] == id)) {
      return; // Already exists
    }

    final WidgetSpec? spec = UspWidgetSpecs.getById(id);
    if (spec == null) return;

    // Calculate position at the bottom of the grid
    int maxY = 0;
    for (final item in currentLayout) {
      final map = item as Map;
      final y = map['y'] as int;
      final h = map['h'] as int;
      if (y + h > maxY) maxY = y + h;
    }

    final item = LayoutItemFactory.fromSpec(
      spec,
      x: 0,
      y: maxY,
      displayMode: DisplayMode.normal,
    );

    final newItemMap = {
      'id': item.id,
      'x': item.x,
      'y': item.y,
      'w': item.w,
      'h': item.h,
      'minW': item.minW,
      'maxW': item.maxW,
      'minH': item.minH,
      'maxH': item.maxH,
    };

    final newLayout = [...currentLayout, newItemMap];
    final newController = _createDefaultController();
    newController.importLayout(newLayout);
    state = newController;
    await saveLayout();
  }

  /// Remove a widget from the dashboard layout.
  Future<void> removeWidget(String id) async {
    final currentLayout = state.exportLayout();
    final newLayout =
        currentLayout.where((item) => (item as Map)['id'] != id).toList();

    if (newLayout.length != currentLayout.length) {
      final newController = _createDefaultController();
      newController.importLayout(newLayout);
      state = newController;
      await saveLayout();
    }
  }
}
