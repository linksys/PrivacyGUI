import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 2.x's barrel opens with `export 'package:state_beacon/state_beacon.dart'`,
// which brings `lite_ref` and `state_beacon_core` with it — so five Riverpod
// names arrive from a package three hops away. `Ref` and `AsyncValue` are the two
// that collided on the bump; the other three are hidden because they only collide
// at the point of *use*, and the compiler names the file rather than the cause.
import 'package:sliver_dashboard/sliver_dashboard.dart'
    hide Ref, AsyncValue, AsyncData, AsyncError, AsyncLoading;

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
///
/// ## An edit is stored by the grid that made it, not by the button that ends it
///
/// Reordering is the one edit that never passes through a method here: the
/// pointer overlay and the a11y keyboard flow both move cards by talking to the
/// controller, so for two tickets' worth of dashboards a dragged card came back
/// on reload (#1393). Every controller this provider publishes is therefore built
/// with [_handleLayoutChanged], which the package calls once a mutation has
/// settled — after the drop, not during the drag.
///
/// That makes the controller the authority on what is stored, and the two
/// consequences are worth stating. Committing edit mode writes nothing, because
/// there is nothing left to write. And an interaction that never ended has
/// nothing to store: the layout the arrows produced is uncompacted, so storing it
/// would mean handing the load path a layout it does not agree with, and the
/// cards would settle somewhere else on the next reload.
class UspSliverDashboardControllerNotifier
    extends StateNotifier<DashboardController> {
  /// The controller handed to [super] is a bootstrap that is immediately thrown
  /// away, because the one the app gets has to carry [_handleLayoutChanged] and
  /// an initializer list cannot reach `this`. Swapping rather than wiring it
  /// later is what makes "every controller this provider publishes reports its
  /// edits" true without exception — two branches of [_initializeLayout] keep the
  /// controller they were given, so a hook armed only on the replacements would
  /// miss the sessions that start without a stored layout (#1393).
  ///
  /// [_swapController] arms the width lock and the selection mirror, which is
  /// what this constructor used to do by hand. The bootstrap is dropped without
  /// disposing, like every other controller this class replaces.
  ///
  /// It still carries the input policy, through [_applyInputPolicy] and the one
  /// history argument, even though it is replaced on the next line. This is the
  /// one controller no test can reach — anything that reads the provider reads the
  /// replacement — so it is the one that has to be right by construction (#1395).
  UspSliverDashboardControllerNotifier(this._ref)
      : super(_applyInputPolicy(DashboardController(
          initialSlotCount: _desktopSlots,
          initialLayout: UspWidgetSpecs.createDefaultLayout(),
          maxHistoryLength: 0,
        ))) {
    _swapController(_createDefaultController());
    // Synchronously, before [_initializeLayout]'s first `await` — see the method's
    // own doc for why the seed cannot wait for the pref (#1395).
    _seedBreakpoints();
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

  /// True while this notifier is putting a layout *into* the controller, as
  /// opposed to the grid reporting one the user made — see [_importQuietly].
  bool _suppressAutoPersist = false;

  /// Orders the writes [_enqueue] hands out, oldest first.
  Future<void> _writeQueue = Future.value();

  /// The card ids the breakpoint caches were last seeded with.
  ///
  /// Only used by the assertion in [_exportAllBreakpoints], and only in the
  /// addition direction: a card the live layout gained without going through
  /// [_seedBreakpoints] is one the other grids' caches have never seen, which is
  /// the single input that makes the walk hang. A card *removed* straight from the
  /// controller leaves this set stale in the harmless direction — the walk
  /// reconciles deletions safely, which is the asymmetry the walk documents.
  Set<String> _seededIds = const {};

  /// The keyboard and modifier set the grid is given, narrower than the
  /// package's default.
  ///
  /// Held as one shared instance rather than built per controller: every card
  /// caches the intent maps it derives from this and rebuilds them whenever the
  /// config is not `identical` to the cached one
  /// (`dashboard_item_widget.dart:449`), so a fresh config per controller would
  /// re-key all 18 caches on every preset and every membership change.
  ///
  /// What is dropped, and why (#1395). None of these existed at 0.9.1, so each
  /// entry keeps today's behaviour rather than taking one away:
  ///
  /// - `delete` (Delete / Backspace) removes the focused card, or the whole
  ///   selection when the focused card is in it, with no confirmation. Removal is
  ///   the one edit here that loses information, the history is off (see
  ///   [_createController]), and Cancel does not fully restore a deletion
  ///   (#1396) — so a stray Backspace, which is a browser Back reflex, costs the
  ///   user their arrangement. Deleting from the keyboard is worth having; it
  ///   wants `DashboardOverlay.onWillDelete` in front of it, which is its own
  ///   decision because the trash zone has no confirmation either.
  /// - `selectAll` (Ctrl / Cmd + A) selects every card at once. Nothing here
  ///   consumes a multi-selection: [selectedCardIdProvider] reads two or more as
  ///   none, so the form toolbar drops back to its prompt with nothing to say
  ///   why. Shift- and Ctrl-click reach the same dead end and are deliberately
  ///   left alone — they predate the bump (0.9.1 `dashboard_overlay.dart:665`),
  ///   and one card at a time is a gesture a user can see the result of.
  /// - `undo` / `redo` (Ctrl / Cmd + Z, Ctrl + Y, Cmd + Shift + Z) are bound by
  ///   the package whether or not there is a history to travel. Left bound they
  ///   would be swallowed by the grid's `Actions` and do nothing at all; empty,
  ///   the chords fall through to whatever encloses the dashboard. The history
  ///   itself is switched off in [_createController], and this is the same
  ///   decision written where the keys are.
  /// - `swapModeModifier` (Shift, held during a drag) inverts `dragMode`, so a
  ///   Shift-drag exchanges two cards outright instead of pushing neighbours
  ///   aside (`getEffectiveDragMode`). Our geometry rules are written against
  ///   push-neighbours, and Shift is a key the user is already holding to
  ///   multi-select, so the same drag would land differently depending on a key
  ///   that means something else. An empty list removes the toggle and leaves
  ///   `dragMode` in sole control, which is the field's own documented opt-out.
  ///
  /// Everything else is left at the package default. Grab / arrows / drop /
  /// Escape is the only way to reorder a card without a pointer and is kept for
  /// that reason; `duplicate` is inert while no `onCloneRequested` is registered.
  static const _shortcuts = DashboardShortcuts(
    delete: {},
    selectAll: {},
    undo: {},
    redo: {},
    swapModeModifier: [],
  );

  /// Applies the input policy [_shortcuts] belongs to.
  ///
  /// Static because the bootstrap controller in the constructor's initializer
  /// list cannot reach `this` and is therefore the one instance no test can
  /// observe — see the class doc. Configuring it here rather than in
  /// [_createController] is what makes the policy hold by construction instead of
  /// by an assertion nothing can make.
  static DashboardController _applyInputPolicy(
          DashboardController controller) =>
      controller
        ..lassoStyle = LassoStyle.off
        ..shortcuts = _shortcuts;

  /// A controller carrying [layout] that reports its own edits back here.
  ///
  /// Every construction goes through this, so there is one place where the
  /// auto-persist hook can be forgotten rather than three.
  ///
  /// It is also where the interaction surfaces `sliver_dashboard` 2.x switches on
  /// by default are switched back off (#1395) — a bump is not the place to start
  /// shipping gestures. Two live here and two more in [_shortcuts]:
  ///
  /// - `maxHistoryLength: 0` disables undo/redo, and this one is a defect rather
  ///   than a preference. [_importQuietly] suppresses this notifier's persist
  ///   hook, not the package's bookkeeping: `importLayout` records a history entry
  ///   (`dashboard_controller_impl.dart:1030`), so [_seedBreakpoints]' walk pushes
  ///   the 8- and 4-column layouts onto the stack before the user has touched
  ///   anything. A Ctrl+Z then re-projects one of those onto the grid the user is
  ///   looking at — measured on 2.6.0: `canUndo` was already true on a first run
  ///   and the first undo narrowed `stats_panel` from 12 slots to 8 on the desktop
  ///   grid — and [_handleLayoutChanged] persists it. Turning the history on means
  ///   first calling `clearHistory()` at the end of every internal import, so the
  ///   stack holds the user's operations and only those.
  /// - `LassoStyle.off` keeps an empty-space drag doing what it did before: the
  ///   grid shares its scroll view with other slivers, and a rubberband only
  ///   makes a multi-selection easier to reach, which nothing here consumes but
  ///   the trash drag. `LassoSelectionMode.modifierRequired` is the upgrade path
  ///   upstream recommends for a grid like this one.
  DashboardController _createController(List<LayoutItem> layout) {
    return _applyInputPolicy(DashboardController(
      initialSlotCount: _desktopSlots,
      initialLayout: layout,
      onLayoutChanged: _handleLayoutChanged,
      maxHistoryLength: 0,
    ));
  }

  DashboardController _createDefaultController() =>
      _createController(UspWidgetSpecs.createDefaultLayout());

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
      // Read the live breakpoint at the swap, not before an await: the pref read
      // below means this method can land several frames after the page was first
      // laid out — on a phone, several frames after the view moved the outgoing
      // controller off desktop.
      final live = state.slotCount.value;
      _swapController(_createController(forcedPreset.createLayout()));
      _seedBreakpoints(live: live);
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
      // `w`, not `d`: this discards a layout the user arranged and reseeds the
      // default, and `debugPrint` compiles out of a release build — so in the
      // field the only user-visible evidence was their dashboard resetting.
      logger.w('[USP][Layout]: saved layout is unreadable — reseeding default');
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
      _importQuietly(newController, desktop);
    }
    final live = state.slotCount.value;
    _swapController(newController);
    _seedBreakpoints(stored: envelope, live: live);

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
  /// the source everything else is derived from). It ends the walk there too, and
  /// then puts the controller back on the grid the page is rendering: [live], or
  /// the one it found the controller on. A caller that has just swapped the
  /// instance has to pass it, because a fresh controller starts on desktop
  /// whatever width it is about to be shown at — and the view withholds the grid
  /// for any frame the two disagree, so getting this wrong is a blank flash
  /// rather than a wrong layout (#1395).
  ///
  /// ## And it cannot wait for the pref (#1395)
  ///
  /// The constructor seeds too, off the default layout, before
  /// [_initializeLayout] has awaited anything. That looks redundant — every path
  /// through [_initializeLayout] seeds again a moment later, and with better
  /// input — but the moment is a frame, and the grid lays out in it.
  ///
  /// An unseeded breakpoint is not a missing layout, it is a wrong one: the
  /// package answers `setSlotCount` from `correctBounds`, which clamps `w` to the
  /// column count but leaves the item's own `minW` alone, so the desktop grid's
  /// half-width cards arrive on the phone four columns wide while still declaring
  /// `minW: 6`. 0.9.1 shipped that contradiction silently; 2.x asserts against it
  /// (`layout_engine.dart:963`, `'currentL.minW <= cols'`), which turns it into a
  /// thrown `FlutterError` on any debug boot into a window narrower than the
  /// desktop breakpoint. Reproduced with no code of ours involved: a bare
  /// `DashboardController(initialSlotCount: 12, initialLayout: <the default>)`
  /// throws on `setSlotCount(4)`, naming `stats_panel`'s `minW: 6`.
  ///
  /// Seeding is the fix rather than a workaround because a seeded breakpoint gets
  /// its layout from [_normalize], which scales the constraints along with the
  /// geometry — which is also what the rest of this class already relies on.
  ///
  /// The cost is one extra walk per session — three `setSlotCount` calls and two
  /// imports, in memory, persisting nothing.
  void _seedBreakpoints({UspLayoutEnvelope? stored, int? live}) {
    final controller = state;
    final liveSlots = live ?? controller.slotCount.value;

    // Desktop is normalised here rather than by its caller because every path
    // into this method imports the desktop layout first and then relies on this
    // walk for the rest. It used to be skipped, which was invisible while
    // [_normalize] was mobile-only and identity at 12 columns; with card forms it
    // would mean the one grid the user starts on is the one grid the picks miss.
    var desktopLayout = controller.exportLayout();
    final normalizedDesktop = _normalize(desktopLayout, _desktopSlots);
    if (!identical(normalizedDesktop, desktopLayout)) {
      _importQuietly(controller, normalizedDesktop);
      desktopLayout = controller.exportLayout();
    }

    for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
      if (slots == _desktopSlots) continue;

      controller.setSlotCount(slots);
      final storedLayout = stored?[slots];
      _importQuietly(
        controller,
        _normalize(
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
        ),
      );
    }

    // Returns to the layout cached during the first setSlotCount above.
    controller.setSlotCount(_desktopSlots);

    // Every grid's cache now holds the same membership — see [_seededIds]. Read
    // on the desktop grid because that is the one this walk normalised first;
    // after the seed every breakpoint agrees, so which one is read is arbitrary.
    _seededIds = {
      for (final item in controller.exportLayout()) item['id'] as String,
    };

    // And back to the grid the page is actually rendering.
    if (liveSlots != _desktopSlots) {
      controller.setSlotCount(liveSlots);
    }
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

  /// Stores an edit the grid made to itself (#1393).
  ///
  /// `sliver_dashboard` calls this after every mutation that leaves the layout
  /// settled — a drag or a keyboard grab that was dropped, a resize, a delete, an
  /// optimise — and never mid-gesture, which is the line persistence has to be
  /// drawn on: by the time it arrives the layout has been compacted, so what is
  /// stored is a layout the load path reproduces rather than one it would shuffle.
  ///
  /// Before this hook, only edits that went through a method on this notifier were
  /// written out, and reordering is not one of them: both the pointer overlay and
  /// the a11y keyboard flow move cards by talking to the controller directly. A
  /// card dragged to a new position was back where it started on the next reload.
  ///
  /// Fire-and-forget, because the caller is a synchronous gesture handler that
  /// cannot wait for a pref write and must not fail with it.
  ///
  /// Both arguments are ignored, and unnamed so that nothing suggests otherwise:
  /// the package hands over the one layout that changed, while what gets stored is
  /// every breakpoint, which [saveLayout] reads for itself.
  void _handleLayoutChanged(List<LayoutItem> _, int __) {
    if (_suppressAutoPersist) return;

    saveLayout().onError((error, stackTrace) => logger.e(
          '[USP][Layout]: could not store a layout change',
          error: error,
          stackTrace: stackTrace,
        ));
  }

  /// Imports [layout] into [controller] without arming [_handleLayoutChanged].
  ///
  /// Every import in this class is this notifier putting back a layout it already
  /// knows about — the stored one on load, a derived one per breakpoint, a
  /// snapshot on cancel, a normalisation after a resize — and the ones that belong
  /// in the pref call [saveLayout] themselves. Letting them trigger the hook would
  /// have the load path write back what it just read, one breakpoint at a time,
  /// before the user has touched anything.
  ///
  /// Restores the previous value rather than clearing the flag, so a caller that
  /// mutes a wider region cannot be un-muted by an import inside it.
  void _importQuietly(DashboardController controller, List<dynamic> layout) {
    final wasSuppressed = _suppressAutoPersist;
    _suppressAutoPersist = true;
    try {
      controller.importLayout(layout);
    } finally {
      _suppressAutoPersist = wasSuppressed;
    }
  }

  /// Persist the layout of every breakpoint to SharedPreferences.
  ///
  /// The controller is read here, synchronously, rather than when the queued write
  /// gets its turn. A write that waits still has to read a live controller: this
  /// notifier is not `autoDispose`, so the only thing that disposes it is the
  /// container going away, and a queued write that reached for `state` after that
  /// found a `StateNotifier` that throws on access — losing the drop that queued
  /// it, and only in debug, where the assertion behind `state` is compiled in.
  /// Capturing it keeps the write correct in both build modes. Ordering is
  /// unaffected: every mutation enqueues after it has mutated, so the last write in
  /// the queue is still the one holding the newest controller.
  Future<void> saveLayout() {
    final controller = state;
    _assertMembershipAligned(controller);
    return _enqueue(() => _writeLayout(controller));
  }

  /// Fails in debug if [controller]'s layout is not safe for the walk to visit.
  ///
  /// Called from the two places a walk is *asked for* — [saveLayout] and
  /// [exportAllBreakpoints] — rather than from inside [_exportAllBreakpoints]
  /// itself, so that it fires on the caller's stack. [saveLayout]'s own walk runs
  /// behind the write queue, where an assertion failure is caught by
  /// [_handleLayoutChanged]'s error handler and logged instead of pointing at the
  /// mutation that caused it.
  void _assertMembershipAligned(DashboardController controller) {
    assert(
      _membershipIsAligned(controller),
      'A card wider than the narrowest grid reached the live layout without '
      'being aligned into the others — add it through addWidget or applyPreset, '
      'not straight to the controller. See _exportAllBreakpoints (#1393).',
    );
  }

  /// Whether [_exportAllBreakpoints] can safely walk [controller]'s layout.
  ///
  /// A card only the live grid's cache holds is placed into the narrower grids at
  /// the width it has here, and the placement does not clamp it, so the walk
  /// stores a card wider than the grid it sits in. Nothing throws: that breakpoint
  /// simply renders over-wide until a reload pulls it back in, which is a defect
  /// with no stack trace attached. Only the addition direction is checked — a
  /// delete reconciles safely, which is the asymmetry [_exportAllBreakpoints]
  /// documents.
  bool _membershipIsAligned(DashboardController controller) =>
      !controller.exportLayout().any((item) =>
          !_seededIds.contains(item['id'] as String) &&
          (item['w'] as int) > UspLayoutEnvelope.mobileSlotCount);

  /// Runs [write] after the writes already queued, and returns its result.
  ///
  /// Persistence is serialised because two writes can now be in flight at once: a
  /// resize fires [_handleLayoutChanged] with the geometry the gesture produced,
  /// and then [updateItemSize] saves again with the geometry the constraints
  /// allow. Ordering them means the last one to land is the newest state rather
  /// than whichever export happened to be captured first — and each reads the
  /// layout as it stands when its turn comes, so a write that waited is not a
  /// write that went stale.
  Future<void> _enqueue(Future<void> Function() write) {
    final queued = _writeQueue.then((_) => write());
    // A failed write must not stall the ones behind it. The caller still sees the
    // error; the queue only needs to know the slot is free again.
    _writeQueue = queued.then((_) {}, onError: (_, __) {});
    return queued;
  }

  Future<void> _writeLayout(DashboardController controller) async {
    final envelope = UspLayoutEnvelope(
      _exportAllBreakpoints(controller),
      forms: _forms,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pUspSliverDashboardLayout, envelope.encode());
  }

  /// One layout per breakpoint, for a caller that has to put all of them back
  /// later.
  ///
  /// This is the entry snapshot of edit mode, and the reason [restoreSnapshot]
  /// can be a plain restore instead of a scale (#1396). It is the same walk
  /// [_writeLayout] runs after every mutation, so it costs a session nothing new,
  /// and it ends on the breakpoint it started on — the page does not move under
  /// the user when they press "Edit".
  ///
  /// Guarded like [saveLayout], and for the same reason: the walk this hands out
  /// is the walk that writes, so an unaligned membership reaching it produces a
  /// snapshot with an over-wide card in the narrow grids — which a cancel would
  /// then restore *and* store.
  Map<int, List<dynamic>> exportAllBreakpoints() {
    final controller = state;
    _assertMembershipAligned(controller);
    return _exportAllBreakpoints(controller);
  }

  /// Reads out one layout per breakpoint by visiting each in turn.
  ///
  /// The controller holds a cached layout per slot count and reconciles
  /// membership as it moves between them, so the walk is doing two jobs: it is
  /// how the geometries we are not currently rendering are read, and it is how a
  /// card *deleted* on this grid reaches the others. It ends where it started, so
  /// the grid the user is looking at does not move.
  ///
  /// Deleted, not added: the reconciliation is only safe in that direction, and
  /// the asymmetry constrains every caller. A card the live layout has and the
  /// target grid's cache does not is placed by the package at the width it has
  /// here, and the placement never narrows it: `placeNewItems(cols: 8)` given a
  /// `w: 12` item appends it below the others, still 12 wide. `stats_panel` is
  /// `w: 12`, so one full-width card coming back on the desktop grid is stored
  /// over-wide on the two narrower ones (#1393).
  ///
  /// So an addition has to be in every breakpoint at a width that grid can hold
  /// before it reaches the live layout — which is what [_replaceController] is
  /// for, and why [restoreSnapshot] goes through it rather than importing into the
  /// controller it is handed. Where that width comes from is the caller's
  /// business: [addWidget] derives it, [restoreSnapshot] has it on record.
  ///
  /// [_membershipIsAligned] is what a comment cannot do. Now that the hook runs
  /// this walk after *every* controller mutation, a future caller reaching for
  /// `controller.addItem` instead of [addWidget] persists that over-wide geometry
  /// silently — nothing in `lib/` does today, and the fixture in
  /// `card_form_toolbar_test.dart` adds at a width every grid can hold because of
  /// it. Failing loudly in debug is the whole defence.
  Map<int, List<dynamic>> _exportAllBreakpoints(
      DashboardController controller) {
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
    _importQuietly(controller, layouts[_desktopSlots] ?? const []);
    _swapController(controller);
    // `live: origin` is what keeps a delete made on a phone from handing the page
    // a desktop grid — the seed leaves the controller where the outgoing one was.
    _seedBreakpoints(stored: UspLayoutEnvelope(layouts), live: origin);

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
    final live = state.slotCount.value;
    _swapController(_createDefaultController());
    // Re-seed: a controller with an empty breakpoint cache falls back to
    // correctBounds at tablet width, which collapses the two-column grid.
    _seedBreakpoints(live: live);

    // Through the queue, so a save started by the drag before the reset cannot
    // land after the removal and leave the pref holding a layout again.
    await _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pUspSliverDashboardLayout);
    });
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
      _importQuietly(
        controller,
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
    _importQuietly(controller, _normalize(next, slots));
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
  /// [forms] is restored *before* the geometry, and the order is load-bearing:
  /// every grid the swap below imports goes through [_normalize] on the way in,
  /// and [_normalize] derives geometry *from* the picks. Restoring the picks
  /// second would normalise the pre-session grids against the session's picks —
  /// a card put back in its old box while still carrying the form the user chose
  /// and then cancelled.
  ///
  /// A revert can bring back a card the session deleted, which makes it a
  /// membership change, and those go in the way [addWidget] and [removeWidget]
  /// put theirs in: swapped in as a fresh instance carrying every breakpoint at
  /// once. Importing the snapshot into the live controller instead left the other
  /// grids without the card and let the package place it there itself, which for
  /// a full-width card does not terminate — see [_exportAllBreakpoints].
  /// Dragging a full-width card to the trash and pressing "Cancel" froze the tab
  /// (#1393).
  ///
  /// ## Why every grid is a snapshot and none is derived (#1396)
  ///
  /// This used to take one grid — the one the user was looking at — and rebuild
  /// the other two from it with `UspWidgetSpecs.alignMembership`, on the grounds
  /// that membership was the only part of them edit mode could change. That is
  /// true of *membership* and false of everything the scale touches on the way:
  /// aligning a 4-column grid up to 12 multiplies the coordinates, so a phone
  /// card pinned to `x: 0, w: 4` by `lockToFullWidth` came back full-width on the
  /// desktop — and `minW: 4` came back as `minW: 12`, which is a constraint the
  /// 8-column grid cannot hold at all (`layout_engine.dart`'s
  /// `assert(currentL.minW <= cols)`). Cancelling a phone-side delete either
  /// rewrote the desktop layout or crashed, depending on the card.
  ///
  /// A grid the user never opened has nothing to derive from. [enterEditMode]
  /// captures all three, and putting all three back is both simpler and the only
  /// answer that is right by construction. `alignMembership` stays where a
  /// derivation is genuinely all there is: [_seedBreakpoints], for a breakpoint
  /// that was never stored.
  ///
  /// A snapshot missing a grid is a caller bug, and the assert is the whole
  /// defence — [exportAllBreakpoints] is the only way to make one, and it always
  /// fills all three. What release does without it is worth knowing rather than
  /// guarding: [_replaceController] falls back to `const []` for the desktop key
  /// only, so a missing 8- or 4-column grid is *derived* from desktop by
  /// [_seedBreakpoints] — exactly the behaviour this ticket replaced — while a
  /// missing desktop grid wipes the dashboard. A fallback here could only make one
  /// of those two cases better, and would be a branch no test can reach.
  Future<void> restoreSnapshot(
      Map<int, List<dynamic>> layouts, CardForms forms) async {
    assert(
      UspLayoutEnvelope.persistedSlotCounts
          .every((slots) => layouts[slots] != null),
      'restoreSnapshot needs one layout per persisted breakpoint. '
      'Capture with exportAllBreakpoints().',
    );
    _setForms(forms);
    // Not normalised here: every grid handed to [_replaceController] is imported
    // through [_seedBreakpoints], which normalises each one against the picks
    // restored above.
    _replaceController(layouts);
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
    final layouts = _exportAllBreakpoints(state);
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
    final live = state.slotCount.value;
    _swapController(_createController(layout));
    _seedBreakpoints(live: live);
    await saveLayout();
  }

  /// Remove a widget from the dashboard layout.
  ///
  /// Removal is global: which cards the dashboard shows is not a per-breakpoint
  /// choice, so a card deleted on a phone is gone on a laptop too.
  Future<void> removeWidget(String id) async {
    final layouts = _exportAllBreakpoints(state);
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
