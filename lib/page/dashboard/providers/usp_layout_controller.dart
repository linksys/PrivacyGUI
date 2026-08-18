import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
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
///
/// ## Geometry is per breakpoint, membership is not
///
/// The dashboard renders on three grids (12 / 8 / 4 columns, following ui_kit's
/// breakpoints) and each keeps its own coordinates: a card made taller on a
/// phone stays that height on the phone only. What is *not* per breakpoint is
/// which cards exist — deleting a card on a phone deletes the card everywhere.
///
/// That split is why the persisted value is a [UspLayoutEnvelope] keyed by slot
/// count instead of the bare list it used to be. `exportLayout()` always returns
/// coordinates in the controller's current slot count, so one unkeyed list meant
/// a save on a phone was read back as a desktop layout of third-width cards
/// whose `minW`/`maxW` had been scaled down with them — permanently, since the
/// caps then blocked widening them again (#1293).
class UspSliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  UspSliverDashboardControllerNotifier() : super(_createDefaultController()) {
    _initializeLayout();
  }

  static const int _desktopSlots = UspLayoutEnvelope.desktopSlotCount;

  static DashboardController _createDefaultController() {
    return DashboardController(
      initialSlotCount: _desktopSlots,
      initialLayout: UspWidgetSpecs.createDefaultLayout(),
    );
  }

  /// Load saved layout from SharedPreferences, or keep the constructor default.
  ///
  /// The constructor already initialises with [UspWidgetSpecs.createDefaultLayout].
  /// This method only replaces the state when a saved layout exists.
  ///
  /// All saved IDs are accepted — unknown IDs may be package widgets whose
  /// specs load asynchronously after dashboard init. The grid renders them
  /// as "Unknown widget" until their template is available.
  ///
  /// In Remote mode, always uses the remote preset layout (no persistence).
  Future<void> _initializeLayout() async {
    // Remote mode: use fixed remote preset layout, skip persistence
    final forcedPreset = GlobalConfig.remote.forcedPreset;
    if (forcedPreset != null) {
      state = DashboardController(
        initialSlotCount: _desktopSlots,
        initialLayout: forcedPreset.createLayout(),
      );
      _seedBreakpoints();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final layoutJson = prefs.getString(pUspSliverDashboardLayout);

    if (layoutJson == null) {
      // No saved layout — persist the constructor's default for next time.
      _seedBreakpoints();
      await saveLayout();
      return;
    }

    final envelope = UspLayoutEnvelope.tryDecode(layoutJson);
    if (envelope == null) {
      debugPrint('Failed to load USP sliver dashboard layout: unreadable');
      // Keep the constructor's default and overwrite the unreadable value.
      _seedBreakpoints();
      await saveLayout();
      return;
    }

    // Accept all saved IDs — unknown IDs may be package widgets whose
    // specs load asynchronously. The grid renders them as "Unknown widget"
    // if their template never loads, which is preferable to resetting
    // the user's entire layout.
    //
    // Create a NEW controller then swap via state= so Riverpod
    // properly notifies listeners (avoids mutating the existing
    // controller in-place which can desync the render tree).
    final desktop = envelope[_desktopSlots];
    final newController = _createDefaultController();
    if (desktop != null) {
      newController.importLayout(desktop);
    }
    state = newController;
    _seedBreakpoints(stored: envelope);

    // A legacy bare list, or an envelope written before we rendered a
    // breakpoint, has nothing stored for the grids we just derived. Write them
    // out now so the first edit made there has a slot of its own to land in.
    final migrated = UspLayoutEnvelope.persistedSlotCounts
        .any((slots) => envelope[slots] == null);
    if (migrated) {
      await saveLayout();
    }
  }

  /// Fills the controller's per-slot-count cache for every breakpoint we render.
  ///
  /// Prefers whatever [stored] holds for a breakpoint — that geometry is the
  /// user's — and derives the rest from the desktop layout by proportional
  /// scaling. Without the seed, the first `setSlotCount` at tablet width falls
  /// back to the package's `correctBounds`, which shifts items left without
  /// scaling their widths, so a `w=6` pair cannot fit in 8 columns and the
  /// two-column layout collapses.
  ///
  /// Must be called with the controller on the desktop grid (the widest one is
  /// the source everything else is derived from); it leaves it there.
  void _seedBreakpoints({UspLayoutEnvelope? stored}) {
    final controller = state;
    final desktopLayout = controller.exportLayout();

    for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
      if (slots == _desktopSlots) continue;

      controller.setSlotCount(slots);
      final storedLayout = stored?[slots];
      controller.importLayout(_normalize(
        storedLayout == null
            ? UspWidgetSpecs.scaleLayout(desktopLayout, _desktopSlots, slots)
            // A stored entry can predate a card the desktop grid has; align it
            // before importing, or `setSlotCount` reads the gap as a deletion
            // and reconciles the card out of every other breakpoint too.
            : UspWidgetSpecs.alignMembership(
                storedLayout,
                desktopLayout,
                fromCols: _desktopSlots,
                toCols: slots,
              ),
        slots,
      ));
    }

    // Returns to the layout cached during the first setSlotCount above.
    controller.setSlotCount(_desktopSlots);
  }

  /// The per-grid policy a layout must satisfy before it is imported or stored.
  ///
  /// Only mobile has one: [UspWidgetSpecs.lockToFullWidth] pins the width so a
  /// 4-column grid is height-and-order only. Wider grids pass through.
  static List<dynamic> _normalize(List<dynamic> layout, int slotCount) =>
      slotCount <= UspLayoutEnvelope.mobileSlotCount
          ? UspWidgetSpecs.lockToFullWidth(layout, slotCount)
          : layout;

  /// Persist the layout of every breakpoint to SharedPreferences.
  Future<void> saveLayout() async {
    final envelope = UspLayoutEnvelope(_exportAllBreakpoints());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pUspSliverDashboardLayout, envelope.encode());
  }

  /// Reads out one layout per breakpoint by visiting each in turn.
  ///
  /// The controller holds a cached layout per slot count and reconciles
  /// membership as it moves between them, so the walk is doing two jobs: it is
  /// how the geometries we are not currently rendering are read, and it is how a
  /// card added or deleted on this grid reaches the others. It ends where it
  /// started, so the grid the user is looking at does not move.
  Map<int, List<dynamic>> _exportAllBreakpoints() {
    final controller = state;
    final origin = controller.slotCount.value;
    final layouts = <int, List<dynamic>>{};

    for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
      controller.setSlotCount(slots);
      layouts[slots] = _normalize(controller.exportLayout(), slots);
    }

    controller.setSlotCount(origin);
    return layouts;
  }

  /// Swaps in a fresh controller carrying [layouts] on every breakpoint.
  ///
  /// Membership changes have to swap the instance rather than mutate in place:
  /// the layout settings panel watches this provider to work out which cards are
  /// still available to add, and `StateNotifier` only notifies listeners when
  /// the instance changes.
  void _replaceController(Map<int, List<dynamic>> layouts) {
    final previous = state;
    final origin = previous.slotCount.value;
    final wasEditing = previous.isEditing.value;

    final controller = _createDefaultController();
    controller.importLayout(layouts[_desktopSlots] ?? const []);
    state = controller;
    _seedBreakpoints(stored: UspLayoutEnvelope(layouts));

    if (origin != _desktopSlots) {
      controller.setSlotCount(origin);
    }
    // Edit mode lives on the controller, so a fresh instance would drop the
    // handles and the trash zone mid-session while dashboardEditModeProvider
    // still believed we were editing.
    if (wasEditing) {
      controller.setEditMode(true);
    }
  }

  /// Reset to default layout and clear persisted data.
  Future<void> resetLayout() async {
    state = _createDefaultController();
    // Re-seed: a controller with an empty breakpoint cache falls back to
    // correctBounds at tablet width, which collapses the two-column grid.
    _seedBreakpoints();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pUspSliverDashboardLayout);
  }

  /// Force update an item's size (used after resize constraint enforcement).
  ///
  /// Geometry only, and only on the grid the user is looking at: the other
  /// breakpoints keep the sizes they were given there.
  Future<void> updateItemSize(String id, int w, int h) async {
    final controller = state;
    final currentLayout = controller.exportLayout();
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
      // In place, so the caches for the other breakpoints survive. The grid
      // rebuilds off the controller's own layout beacon — the same path every
      // drag and resize already uses — so no Riverpod notification is needed.
      controller.importLayout(
        _normalize(newLayout, controller.slotCount.value),
      );
      await saveLayout();
    }
  }

  /// Add a widget to the dashboard layout (appended at the bottom).
  ///
  /// [spec] can be provided for package widgets not in [UspWidgetSpecs].
  Future<void> addWidget(String id, {WidgetSpec? spec}) async {
    final layouts = _exportAllBreakpoints();
    final desktopLayout = layouts[_desktopSlots] ?? const [];
    if (desktopLayout.any((item) => (item as Map)['id'] == id)) {
      return; // Already exists
    }

    final resolvedSpec = spec ?? UspWidgetSpecs.getById(id);
    if (resolvedSpec == null) return;

    // Calculate position at the bottom of the grid
    int maxY = 0;
    for (final item in desktopLayout) {
      final map = item as Map;
      final y = map['y'] as int;
      final h = map['h'] as int;
      if (y + h > maxY) maxY = y + h;
    }

    final item = LayoutItemFactory.fromSpec(
      resolvedSpec,
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

    // Placed on each grid at that grid's own scale. Letting the package
    // reconcile it in instead would carry the current breakpoint's width
    // across, so a card added on a phone would arrive at desktop 4/12 wide.
    _replaceController({
      for (final entry in layouts.entries)
        entry.key: [
          ...entry.value,
          if (entry.key == _desktopSlots)
            newItemMap
          else
            UspWidgetSpecs.scaleLayout(
              [newItemMap],
              _desktopSlots,
              entry.key,
            ).single,
        ],
    });
    await saveLayout();
  }

  /// Apply a preset layout, replacing the current layout entirely.
  ///
  /// Uses the preset's hand-crafted layout (optimised card positions and sizes)
  /// rather than generic 2-column packing.
  Future<void> applyPreset(UspDashboardPreset preset) async {
    final layout = preset.createLayout();
    state = DashboardController(
      initialSlotCount: _desktopSlots,
      initialLayout: layout,
    );
    _seedBreakpoints();
    await saveLayout();
  }

  /// Remove a widget from the dashboard layout.
  ///
  /// Removal is global: which cards the dashboard shows is not a per-breakpoint
  /// choice, so a card deleted on a phone is gone on a laptop too.
  Future<void> removeWidget(String id) async {
    final layouts = _exportAllBreakpoints();
    final desktopLayout = layouts[_desktopSlots] ?? const [];
    if (!desktopLayout.any((item) => (item as Map)['id'] == id)) return;

    _replaceController({
      for (final entry in layouts.entries)
        entry.key:
            entry.value.where((item) => (item as Map)['id'] != id).toList(),
    });
    await saveLayout();
  }
}
