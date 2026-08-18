import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/usp_dashboard_preset.dart';
import '../models/usp_widget_specs.dart';

/// Provider for the USP Sliver Dashboard Controller.
final uspSliverDashboardControllerProvider = StateNotifierProvider<
    UspSliverDashboardControllerNotifier, DashboardController>(
  (ref) => UspSliverDashboardControllerNotifier(ref),
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
///
/// ## Two rules constrain the geometry, and they are both applied here
///
/// [_normalize] is the single funnel every layout passes through on its way into
/// the controller or into the pref. It applies, in order:
///
/// 1. the form each card was picked into (#1299) — pinning a popup tile, raising
///    a compact card's floor, restoring the spec bounds for normal;
/// 2. the mobile full-width lock (#1293) — pinning `x`/`w` on the 4-column grid.
///
/// Each rule owns one axis on a phone: the forms rule abstains from `x`/`w` at 4
/// columns and the lock only ever touches those, so a popup card there is a short
/// full-width bar rather than a 2-column tile. That abstention is what makes the
/// order of the two *not* load-bearing — swapping them produces the same layout,
/// which is deliberate rather than lucky, and is why neither has to know it runs
/// second.
class UspSliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  UspSliverDashboardControllerNotifier(this._ref)
      : super(_createDefaultController()) {
    _armWidthLock();
    _armSelectionMirror();
    _initializeLayout();
  }

  static const int _desktopSlots = UspLayoutEnvelope.desktopSlotCount;

  /// Publishes the picked forms to [cardFormsProvider] for the render side.
  final Ref _ref;

  /// Cancels the current controller's width-lock subscription.
  VoidCallback? _widthLockGuard;

  /// Cancels the current controller's selection subscription.
  VoidCallback? _selectionGuard;

  /// The form each card was picked into, per breakpoint (#1299).
  ///
  /// The authoritative copy, not a cache of one. Reading it back out of
  /// [cardFormsProvider] would be synchronous and would look like one field less,
  /// but that provider is this notifier's *published mirror*: a test or a scope
  /// that overrode it would then be silently changing which geometry [_normalize]
  /// derives, rather than only what the cards render. Reading the pref instead is
  /// not open either — [_normalize] runs on paths that cannot await, the width-lock
  /// callback and the seeding walk among them.
  CardForms _forms = CardForms.empty;

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
      _swapController(DashboardController(
        initialSlotCount: _desktopSlots,
        initialLayout: forcedPreset.createLayout(),
      ));
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
    // Before the seed, so the walk derives the geometry these picks imply
    // instead of the geometry the pref happened to hold (#1299).
    _setForms(envelope.forms);

    final desktop = envelope[_desktopSlots];
    final newController = _createDefaultController();
    if (desktop != null) {
      newController.importLayout(desktop);
    }
    _swapController(newController);
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

    // Desktop is normalised here rather than by its caller because every path
    // into this method imports the desktop layout first and then relies on this
    // walk for the rest. It used to be skipped, which was invisible while
    // [_normalize] was mobile-only and identity at 12 columns; with card forms it
    // would mean the one grid the user starts on is the one grid the picks miss.
    var desktopLayout = controller.exportLayout();
    final normalizedDesktop = _normalize(desktopLayout, _desktopSlots);
    if (!identical(normalizedDesktop, desktopLayout)) {
      controller.importLayout(normalizedDesktop);
      desktopLayout = controller.exportLayout();
    }

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
  /// Two rules, in this order:
  ///
  /// 1. [UspWidgetSpecs.applyCardForms] derives the geometry implied by the form
  ///    each card was picked into on this grid (#1299). Derived rather than
  ///    stored, so the pick is the only thing persisted and the sizes it justifies
  ///    cannot drift away from it.
  /// 2. [UspWidgetSpecs.lockToFullWidth] pins `x`/`w` on the 4-column grid, so a
  ///    phone is height-and-order only (#1293). Wider grids skip it.
  ///
  /// The order is not load-bearing — the forms rule abstains from `x`/`w` on the
  /// phone grid precisely so the two cannot contradict each other — but it is
  /// written this way round because the lock is the older and blunter of the two,
  /// and reading it last matches how it is described in #1293.
  ///
  /// Both rules are idempotent, which is what lets this run on every import
  /// rather than only on the edit that caused it.
  List<dynamic> _normalize(List<dynamic> layout, int slotCount) {
    final formed = UspWidgetSpecs.applyCardForms(
      layout,
      slotCount,
      _forms.at(slotCount),
    );
    return slotCount <= UspLayoutEnvelope.mobileSlotCount
        ? UspWidgetSpecs.lockToFullWidth(formed, slotCount)
        : formed;
  }

  /// Records [forms] and publishes them to the render side.
  ///
  /// Kept together because a pick that reaches only one of the two shows up as a
  /// card whose box was constrained but whose content was not reduced, or the
  /// reverse.
  void _setForms(CardForms forms) {
    _forms = forms;
    _ref.read(cardFormsProvider.notifier).state = forms;
  }

  /// Swaps in [controller] and re-arms the width lock on it.
  ///
  /// The lock belongs to the instance it watches, so a swap that forgets to
  /// re-arm leaves the phone grid horizontally editable again.
  void _swapController(DashboardController controller) {
    state = controller;
    _armWidthLock();
    _armSelectionMirror();
  }

  /// Mirrors the current controller's grid selection into
  /// [selectedCardIdProvider] (#1299).
  ///
  /// The toolbar's form picker acts on the selected card, and the selection is a
  /// beacon on the controller rather than Riverpod state — see
  /// [selectedCardIdProvider] for why it is bridged instead of watched directly.
  ///
  /// Re-armed on every swap, like the width lock: the subscription belongs to the
  /// instance it watches, and the new instance starts with nothing selected. The
  /// default `startNow: true` is what pushes that fresh state through, so a swap
  /// cannot leave the toolbar naming a card the grid no longer highlights.
  ///
  /// Subscribing from the constructor is safe even though it publishes: beacons
  /// flush their subscriptions on a microtask, so the first callback lands after
  /// this provider has finished building. A guard against writing during the build
  /// was written here first and then dropped — mutation-tested, no test could tell
  /// the two apart, because the write it was protecting against cannot happen.
  void _armSelectionMirror() {
    _selectionGuard?.call();
    _selectionGuard = state.selectedItemIds.subscribe(_publishSelection);
  }

  /// Publishes [ids] as a single selected card, or null when it is not exactly
  /// one — see [selectedCardIdProvider].
  void _publishSelection(Set<String> ids) {
    _ref.read(selectedCardIdProvider.notifier).state =
        ids.length == 1 ? ids.first : null;
  }

  /// Watches the current controller's layout so a horizontal change made on the
  /// phone grid is undone before it is drawn.
  ///
  /// [_normalize] is applied when a layout is imported and when it is stored,
  /// which covers everything except the case in between: a gesture writes
  /// straight to the controller's layout beacon, and on mobile the left-hand
  /// resize handles get past the width caps by moving `x` — see
  /// [UspWidgetSpecs.lockItemsToFullWidth]. Nothing else re-reads the live
  /// layout after a resize, so without this the card stays where the drag left
  /// it until the next import.
  ///
  /// Subscribing is what makes the drag look inert rather than rubber-banding:
  /// the correction is queued alongside the rebuild the same write triggers, and
  /// runs first because this subscription is registered before any widget starts
  /// watching. `startNow: false` because the layout as it stands has already
  /// been normalised by whoever imported it.
  void _armWidthLock() {
    _widthLockGuard?.call();
    final controller = state;
    _widthLockGuard = controller.layout.subscribe(
      (items) => _enforceWidthLock(controller, items),
      startNow: false,
    );
  }

  /// Restores the full-width geometry of [items] if a gesture broke it.
  ///
  /// Takes the controller it was armed on rather than reading [state]: a swap
  /// can land between the write and this callback, and the layout being
  /// corrected belongs to the old instance.
  void _enforceWidthLock(
    DashboardController controller,
    List<LayoutItem> items,
  ) {
    final slotCount = controller.slotCount.value;
    if (slotCount > UspLayoutEnvelope.mobileSlotCount) return;

    final locked = UspWidgetSpecs.lockItemsToFullWidth(items, slotCount);
    if (locked == null) return;

    // Straight to the beacon rather than through importLayout: that would
    // compact the whole grid mid-gesture, closing gaps the user is in the
    // middle of making.
    controller.layout.value = locked;
  }

  @override
  void dispose() {
    _widthLockGuard?.call();
    _selectionGuard?.call();
    super.dispose();
  }

  /// Persist the layout of every breakpoint to SharedPreferences.
  Future<void> saveLayout() async {
    final envelope = UspLayoutEnvelope(
      _exportAllBreakpoints(),
      forms: _forms,
    );
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
    _swapController(controller);
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
    // Before the swap and the seed: a pick is a constraint on the geometry, so a
    // reset that kept the picks would hand back a "default" layout with cards
    // still pinned and still missing their handles.
    _setForms(CardForms.empty);
    _swapController(_createDefaultController());
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

  /// Put [cardId] into [density] on the grid the user is looking at (#1299).
  ///
  /// The inverse of #1232: instead of the width choosing the form, the form
  /// chooses which widths are legal. [UspWidgetSpecs.applyCardForms] holds that
  /// arithmetic; this method's job is the part that cannot be re-derived — which
  /// form was picked, and the box to give back when a popup is expanded again.
  ///
  /// ## Only this breakpoint
  ///
  /// A pick is per grid, like the geometry it constrains. That is the point of it
  /// on a phone: there the user has no influence over width at all (the 4-column
  /// grid pins `x: 0, w: cols`, and #1293's left-edge lock forbids horizontal
  /// resize outright), so picking the form is the only control they have — and
  /// wanting a card reduced in that one column says nothing about wanting it
  /// reduced on a laptop.
  ///
  /// ## `normal` is not a pin
  ///
  /// It clears the constraint rather than adding one: the spec's bounds come back
  /// and #1232 decides the form from the width again. Pinning it would let a card
  /// be parked at 191px in its full form, which is the overflow #1183 exists to
  /// prevent — the framework guarantees the layout by constraining the geometry,
  /// and it cannot do that while also honouring a pick that asks for the opposite.
  ///
  /// Picks the card does not offer are ignored, so a stale menu cannot ask for a
  /// compact form that was never built.
  Future<void> setCardForm(String cardId, CardDensity density) async {
    if (!UspWidgetSpecs.selectableForms(cardId).contains(density)) return;

    final controller = state;
    final slots = controller.slotCount.value;
    final layout = controller.exportLayout();
    final item = _findItem(layout, cardId);
    if (item == null) return;

    final previous = _forms.choiceFor(slots, cardId);
    final wasPopup = previous?.density == CardDensity.popup;
    List<dynamic> next = layout;
    final CardFormChoice choice;

    if (density == CardDensity.popup) {
      // Written down before the collapse, not after: once the handles are gone
      // there is no gesture that could recover the size, so if we do not
      // remember it here nothing else will. Re-entering popup keeps the box
      // recorded the first time rather than overwriting it with 2x1.
      choice = wasPopup
          ? previous!
          : CardFormChoice(
              density: density,
              restoreW: item['w'] as int?,
              restoreH: item['h'] as int?,
            );
    } else {
      choice = CardFormChoice(density: density);
      if (wasPopup && previous!.hasRestore) {
        next = _withSize(layout, cardId, previous.restoreW, previous.restoreH);
      }
    }

    _setForms(_forms.withChoice(slots, cardId, choice));
    // In place, and on this grid only: the caches for the other breakpoints are
    // what keeps their picks and geometry theirs. The grid rebuilds off the
    // controller's own layout beacon, the path every drag already uses.
    controller.importLayout(_normalize(next, slots));
    await saveLayout();
  }

  /// Puts the picks and the geometry back to what they were, as one step.
  ///
  /// Cancelling edit mode reverts what was done in it, and since #1299 that
  /// includes the forms cards were picked into. The two have to move together:
  /// reverting the geometry alone leaves a card the user picked popup for sitting
  /// in its old box with no handles, and reverting the pick alone leaves a 2x1
  /// tile that is resizable again. Both are states no sequence of gestures could
  /// have produced.
  ///
  /// [layout] is re-normalised rather than trusted, so a snapshot taken before
  /// this ticket existed — or one carried across a reload — still lands as a
  /// layout the current rules agree with.
  Future<void> restoreSnapshot(List<dynamic> layout, CardForms forms) async {
    _setForms(forms);
    final controller = state;
    controller.importLayout(_normalize(layout, controller.slotCount.value));
    await saveLayout();
  }

  static Map<String, Object?>? _findItem(List<dynamic> layout, String id) {
    for (final item in layout) {
      if (item is Map && item['id'] == id) return item.cast<String, Object?>();
    }
    return null;
  }

  /// Returns [layout] with [id] resized, leaving every other card untouched.
  static List<dynamic> _withSize(
    List<dynamic> layout,
    String id,
    int? w,
    int? h,
  ) =>
      layout.map((item) {
        if ((item as Map)['id'] != id) return item;
        return {
          ...item.cast<String, dynamic>(),
          if (w != null) 'w': w,
          if (h != null) 'h': h,
        };
      }).toList();

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
    _swapController(DashboardController(
      initialSlotCount: _desktopSlots,
      initialLayout: layout,
    ));
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

    // A pick outliving the card it was made for would silently reapply itself if
    // the card were added back, arriving pre-collapsed for no visible reason.
    _setForms(_forms.withoutCard(id));

    _replaceController({
      for (final entry in layouts.entries)
        entry.key:
            entry.value.where((item) => (item as Map)['id'] != id).toList(),
    });
    await saveLayout();
  }
}
