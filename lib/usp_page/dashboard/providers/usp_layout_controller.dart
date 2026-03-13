import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/usp_dashboard_preset.dart';
import '../models/usp_widget_specs.dart';

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
  ///
  /// Validation: reject layouts that reference **unknown** widget IDs (removed
  /// from specs). Layouts with **fewer** cards than the full spec are valid —
  /// they come from presets or user customisation.
  Future<void> _initializeLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutJson = prefs.getString(pUspSliverDashboardLayout);

    if (layoutJson == null) {
      // No saved layout — persist the constructor's default for next time.
      await saveLayout();
      _preSeedBreakpoints();
      return;
    }

    try {
      final layoutData = jsonDecode(layoutJson) as List<dynamic>;

      // Validate: reject layouts with unknown IDs (widget was removed from specs).
      // Layouts with fewer cards than specs are fine (preset / user customisation).
      final savedIds = layoutData
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toSet();
      final knownIds = UspWidgetSpecs.all.map((s) => s.id).toSet();
      final unknownIds = savedIds.difference(knownIds);

      if (unknownIds.isNotEmpty) {
        debugPrint('USP layout has unknown widgets: $unknownIds — resetting');
        await saveLayout();
        _preSeedBreakpoints();
        return;
      }

      // Create a NEW controller then swap via state= so Riverpod
      // properly notifies listeners (avoids mutating the existing
      // controller in-place which can desync the render tree).
      final newController = _createDefaultController();
      newController.importLayout(layoutData);
      state = newController;
      _preSeedBreakpoints();
    } catch (e) {
      debugPrint('Failed to load USP sliver dashboard layout: $e');
      // Keep the constructor's default — no state change needed.
      await saveLayout();
      _preSeedBreakpoints();
    }
  }

  /// Pre-seeds the controller's internal per-slot-count layout cache with
  /// proportionally scaled layouts for tablet (8) and mobile (4) breakpoints.
  ///
  /// Without this, `DashboardController.setSlotCount` falls back to
  /// `correctBounds` which only shifts items left without scaling widths,
  /// breaking the two-column layout at tablet widths (w=6 can't pair in 8).
  void _preSeedBreakpoints() {
    final controller = state;
    final layout12 = controller.exportLayout();

    // --- Seed 8-column (tablet) cache ---
    controller.setSlotCount(8);
    controller.importLayout(
      UspWidgetSpecs.scaleLayout(layout12, 12, 8),
    );

    // --- Seed 4-column (mobile) cache ---
    controller.setSlotCount(4);
    controller.importLayout(
      UspWidgetSpecs.scaleLayout(layout12, 12, 4),
    );

    // --- Return to 12-column (desktop) ---
    // This finds the cached layout12 saved during the first setSlotCount(8).
    controller.setSlotCount(12);
  }

  /// Persist current layout to SharedPreferences.
  Future<void> saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = state.exportLayout();
    await prefs.setString(pUspSliverDashboardLayout, jsonEncode(layoutData));
  }

  /// Reset to default layout and clear persisted data.
  Future<void> resetLayout() async {
    state = _createDefaultController();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pUspSliverDashboardLayout);
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

  /// Apply a preset layout, replacing the current layout entirely.
  ///
  /// Uses the preset's hand-crafted layout (optimised card positions and sizes)
  /// rather than generic 2-column packing.
  Future<void> applyPreset(UspDashboardPreset preset) async {
    final layout = preset.createLayout();
    state = DashboardController(
      initialSlotCount: 12,
      initialLayout: layout,
    );
    _preSeedBreakpoints();
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
