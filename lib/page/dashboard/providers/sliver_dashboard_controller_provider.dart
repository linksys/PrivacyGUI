import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

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
}
