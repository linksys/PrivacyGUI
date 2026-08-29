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
/// ## The picks travel on the items, so there is one store and not two
///
/// A card's form — popup, compact, normal — is a pick the user makes and the
/// geometry it justifies cannot be re-derived from (#1299). It is written into the
/// grid item it shaped, under `extra`, which `exportLayout`/`importLayout`
/// round-trip and which `setSlotCount` keeps per grid (#1400). So the pick and its
/// geometry reach the pref, the edit-mode snapshot and any future undo history as
/// one value: [restoreSnapshot] takes one argument, [removeWidget] deletes the
/// pick by deleting the card, and there is no second store for either to fall out
/// of step with.
///
/// [UspWidgetSpecs.withCardForm] is the only writer, and it runs at the pick.
/// [UspWidgetSpecs.applyPickedForms] re-derives that geometry only where a grid is
/// *created* rather than restored — the scale in [_seedBreakpoints], and the
/// one-time migration in [_initializeLayout].
///
/// [_normalize] is what survives of the funnel every layout used to pass through:
/// the mobile full-width lock (#1293), pinning `x`/`w` on the 4-column grid.
/// Popup abstains from those two fields at 4 columns precisely so the lock can own
/// them, which is why a popup card on a phone is a short full-width bar rather
/// than a 2-column tile.
///
/// That lock used to need a second mechanism behind it: a subscription on the
/// controller's layout beacon that rewrote whatever a left-hand resize handle had
/// got past the caps, because 0.9.1 clamped the new width but let `x` move. 2.6.0
/// clamps `x` against the same caps, so the subscription was deleted and the pin
/// is now the whole of the rule (#1399) — an illegal width is never produced
/// rather than corrected a frame later.
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
  /// [_swapController] arms the selection mirror, which is what this constructor
  /// used to do by hand. The bootstrap is dropped without disposing, like every
  /// other controller this class replaces.
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

  /// Cancels the current controller's selection subscription.
  VoidCallback? _selectionGuard;

  /// Cancels the current controller's card-forms subscription.
  VoidCallback? _formsGuard;

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
  ///
  /// ## `delete` is the one that came back (#1398)
  ///
  /// It was cleared here at first, and for a reason that has since been dealt
  /// with rather than reconsidered: Delete / Backspace removes the focused card —
  /// or the whole selection, when the focused card is in it — and removal is the
  /// one edit that loses information. The history is off (see [_createController])
  /// and #1393's hook persists the deletion on the frame it happens, so a stray
  /// Backspace, which is a browser Back reflex, cost the user their arrangement
  /// with nothing to press to get it back.
  ///
  /// What restores the binding is `UspSliverDashboardView`'s `onWillDelete`, an
  /// async veto the *keyboard* path reads too — `DashboardDeleteItemIntent` looks
  /// it up on `DashboardOverlayProvider` and only calls its `executeDeletion`
  /// when the answer is true (`dashboard_item_widget.dart:354-362`). So the
  /// confirmation is not a second mechanism bolted onto the shortcut; it is the
  /// same dialog the trash drop goes through, and there is no arrangement of this
  /// page where one path is guarded and the other is not. That is also why the two
  /// changes are ordered: un-clearing this without the dialog in place would be
  /// shipping exactly the keypress #1395 cleared this binding to refuse.
  ///
  /// Both default activators are taken back, Backspace included. A confirmation
  /// is what makes the reflex affordable — the mis-press now costs a dialog rather
  /// than a card — and dropping one of the two would leave a shortcut whose
  /// behaviour depends on which key the user reached for.
  static const _shortcuts = DashboardShortcuts(
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
  ///
  /// ## Why there is no `..policy` here (#1399)
  ///
  /// 2.2.0 added `DashboardPolicy`, and this is the line it would go on. Both
  /// geometry rules this page has were considered for it and neither fits, so the
  /// field is deliberately left unset:
  ///
  /// - **The phone width lock.** The hooks are four booleans and none of them
  ///   takes a width. `canResize(item)` is asked once at `onResizeStart` with no
  ///   handle, so it can only refuse *every* resize — which would take the height
  ///   with it, and the height is the one dimension a phone user still chooses.
  ///   `canMoveTo` is handed the *raw* rounded pointer target before any clamping,
  ///   so a rule shaped like "x is not yours" refuses the whole event including
  ///   its vertical component: a diagonal drag would freeze instead of sliding up
  ///   and down. The caps on the items express it exactly, and 2.6.0's resolver
  ///   clamps `x` against them — see [UspWidgetSpecs.lockToFullWidth].
  /// - **Per-card min/max from `WidgetSpec`.** Already per item, which is where
  ///   the resolver reads them. A boolean veto could only re-derive the arithmetic
  ///   and then refuse, which stops a card dead at its cap instead of letting it
  ///   come to rest on it.
  ///
  /// A policy that repeated either rule would be a second copy of an invariant
  /// that already holds — the shape of thing #1399 removed, not added.
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

    final decoded = UspLayoutEnvelope.tryDecode(layoutJson);
    if (decoded == null) {
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
    //
    // A v3 payload kept its card-form picks in a map beside the layouts;
    // `tryDecode` has moved them onto the items they describe, and this is where
    // the geometry those picks imply is re-derived (#1400). It has to be derived
    // rather than trusted: in v3 the stored geometry was recomputed from that map
    // on every import, so it was never what the grid actually rendered, and a
    // migration that kept it would preserve bytes the writing build did not
    // believe either. Once per install — the re-save at the end of this method is
    // what makes the next boot an ordinary one.
    final envelope = decoded.migratedPicks
        ? decoded.mapLayouts(
            (slots, layout) => UspWidgetSpecs.applyPickedForms(layout, slots))
        : decoded;

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
    //
    // The second disjunct is what makes a v3 migration cost one boot rather than
    // every boot: a payload that already holds all three breakpoints is complete,
    // so nothing else here would write the folded picks back.
    final incomplete = UspLayoutEnvelope.persistedSlotCounts
        .any((slots) => envelope[slots] == null);
    if (incomplete || envelope.migratedPicks) {
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

    // The desktop layout is taken as it stands. #1299 normalised it here first,
    // because [_normalize] then re-derived the card-form geometry and the desktop
    // grid would otherwise have been the one grid the picks missed. #1400 moved
    // that derivation to where the geometry is written, leaving [_normalize] the
    // mobile width lock again — identity at 12 columns — so normalising here is a
    // no-op the next reader would have to re-derive the deadness of.
    final desktopLayout = controller.exportLayout();

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
  /// One rule now: [UspWidgetSpecs.lockToFullWidth] pins `x`, `w` and both width
  /// caps on the 4-column grid, so a phone is height-and-order only (#1293). Wider
  /// grids skip it, which makes this identity for two of the three breakpoints. The
  /// caps are named here because since `sliver_dashboard` 2.6.0 they are the entire
  /// enforcement: this call is the last thing that touches the width before the
  /// layout is imported, and nothing watches it afterwards (#1399).
  ///
  /// It used to derive the card-form geometry here as well, from a sibling map, on
  /// every import (#1299). It no longer has to: the pick rides on the item and the
  /// geometry it justifies was written beside it at the pick (#1400), so a layout
  /// arriving from the pref, a snapshot or another grid's cache already carries
  /// both. The derivation moved to the two places a grid is *created* — see
  /// [UspWidgetSpecs.applyPickedForms].
  ///
  /// Idempotent, which is what lets this run on every import rather than only on
  /// the edit that caused it.
  List<dynamic> _normalize(List<dynamic> layout, int slotCount) =>
      slotCount <= UspLayoutEnvelope.mobileSlotCount
          ? UspWidgetSpecs.lockToFullWidth(layout, slotCount)
          : layout;

  /// Swaps in [controller] and re-arms everything that watches the instance.
  ///
  /// Each subscription belongs to the instance it watches, so a swap that forgets
  /// to re-arm leaves the toolbar naming a card the grid no longer highlights, or
  /// the cards rendering the forms of a layout nobody is looking at.
  ///
  /// There used to be a third, and it is the one that made this rule visible: the
  /// width lock was re-armed here too, and forgetting it left the phone grid
  /// horizontally editable again. The rule it enforced is now carried by the items
  /// themselves (see [_normalize]), so a swap cannot mislay it (#1399).
  void _swapController(DashboardController controller) {
    state = controller;
    _armSelectionMirror();
    _armFormsMirror();
  }

  /// Mirrors the picks carried by the current controller's live grid into
  /// [cardFormsProvider] (#1400).
  ///
  /// The render side needs the pick keyed by card id — [CardDensityHost] for the
  /// form a card draws itself in, the edit-mode toolbar for the chip it shows as
  /// selected — and neither can walk the layout for it. So the projection is
  /// published from the beacon that holds the layout, which means every way a pick
  /// can change is already covered: a pick made through [setCardForm], a
  /// breakpoint change that swaps in another grid's cache, an import from the pref,
  /// a cancel that puts back a snapshot, a delete that takes the pick with the
  /// card. None of them has to remember to publish.
  ///
  /// That is the whole of why this is a mirror and not a store. Before #1400 this
  /// notifier held the authoritative copy and pushed it here, and the geometry was
  /// re-derived from it on import — so an override of this provider silently
  /// changed which sizes were legal. Now the layout is the authority and this is a
  /// read of it: an override changes what the cards render and nothing else.
  ///
  /// `startNow` is left at its default, so a swap publishes the incoming grid's
  /// picks immediately rather than at its first mutation. Safe from the
  /// constructor for the reason [_armSelectionMirror] documents: beacons flush
  /// their subscriptions on a microtask.
  void _armFormsMirror() {
    _formsGuard?.call();
    _formsGuard = state.layout.subscribe(_publishForms);
  }

  /// Publishes the picks [items] carry — see [CardForms].
  ///
  /// Writes on every layout change, including each leg of the walk in
  /// [_exportAllBreakpoints], which briefly puts another breakpoint's items on the
  /// beacon. Those publishes are what [CardForms]'s value equality is for: the
  /// walk returns to the live grid, so the last write is the right one and the
  /// equal ones in between rebuild nothing.
  void _publishForms(List<LayoutItem> items) {
    _ref.read(cardFormsProvider.notifier).state =
        CardForms.of(items.map((item) => (item.id, item.extra)));
  }

  /// Mirrors the current controller's grid selection into
  /// [selectedCardIdProvider] (#1299).
  ///
  /// The toolbar's form picker acts on the selected card, and the selection is a
  /// beacon on the controller rather than Riverpod state — see
  /// [selectedCardIdProvider] for why it is bridged instead of watched directly.
  ///
  /// Re-armed on every swap — the subscription belongs to the instance it
  /// watches, and the new instance starts with nothing selected. The
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

  @override
  void dispose() {
    _selectionGuard?.call();
    _formsGuard?.call();
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
    final envelope = UspLayoutEnvelope(_exportAllBreakpoints(controller));
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
  ///
  /// The picks go with it and no line here says so (#1400): they were on the items
  /// the default layout replaces, so "reset the geometry" and "clear the picks"
  /// are the same act rather than two that have to agree.
  Future<void> resetLayout() async {
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
  ///
  /// The size is floored by the item's own `minW`/`minH` (#1400). This is the one
  /// writer that can go under them: a resize *gesture* is clamped to
  /// `[minW, maxW]` by the package, but this method is handed a size computed from
  /// the card's spec (`UspWidgetSpecs.correctedSize`), and a spec knows nothing
  /// about a floor a picked compact form raised. The floors used to be re-imposed
  /// on the way in, back when [_normalize] re-derived the card-form geometry from a
  /// sibling map on every import; now that the geometry *is* the stored value, the
  /// guard belongs at the write that could break it rather than on every read.
  ///
  /// The floor only. The ceiling is the spec's, and this method's caller is
  /// precisely the one that exists to pull a card back inside it.
  Future<void> updateItemSize(String id, int w, int h) async {
    final controller = state;
    final currentLayout = controller.exportLayout();
    bool changed = false;

    final newLayout = currentLayout.map((item) {
      if (item['id'] == id) {
        final mutableItem = Map<String, dynamic>.from(item);
        final minW = mutableItem['minW'];
        final minH = mutableItem['minH'];
        final nextW = minW is int && w < minW ? minW : w;
        final nextH = minH is int && h < minH ? minH : h;
        if (mutableItem['w'] != nextW || mutableItem['h'] != nextH) {
          mutableItem['w'] = nextW;
          mutableItem['h'] = nextH;
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
  /// chooses which widths are legal. [UspWidgetSpecs.withCardForm] holds that
  /// arithmetic and writes the pick onto the item in the same copy of the same
  /// map (#1400); this method's job is the part that cannot be re-derived — which
  /// form was picked, and the box to give back when a popup is expanded again.
  ///
  /// ## Only this breakpoint
  ///
  /// A pick is per grid, like the geometry it constrains. That is the point of it
  /// on a phone: there the user has no influence over width at all (the 4-column
  /// grid pins `x`, `w`, `minW` and `maxW` alike, which is now the whole of the
  /// lock — see [UspWidgetSpecs.lockToFullWidth]), so picking the form is the only
  /// control they have — and wanting a card reduced in that one column says
  /// nothing about wanting it reduced on a laptop.
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

    // The previous pick comes off the item rather than out of a map keyed by this
    // grid's slot count (#1400). Same answer, one fewer way to ask the wrong grid.
    final previous = CardFormChoice.readFrom(item['extra']);
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

    // In place, and on this grid only: the caches for the other breakpoints are
    // what keeps their picks and geometry theirs. The grid rebuilds off the
    // controller's own layout beacon, the path every drag already uses — and that
    // beacon is also what republishes [cardFormsProvider], so the pick reaches the
    // render side by the same write that reaches the pref.
    _importQuietly(
      controller,
      _normalize(
        UspWidgetSpecs.withCardForm(next, cardId, choice, cols: slots),
        slots,
      ),
    );
    await saveLayout();
  }

  /// Puts every breakpoint's geometry back to what it was.
  ///
  /// Cancelling edit mode reverts what was done in it, and since #1299 that
  /// includes the forms cards were picked into. It takes one argument to do both
  /// (#1400): the pick is on the item, so the pair the revert has to keep together
  /// is one value it cannot take apart. Two arguments in the wrong order used to
  /// mean a card put back in its old box while still carrying the form the user
  /// chose and then cancelled, or a 2x1 tile that was resizable again — states no
  /// sequence of gestures could have produced.
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
  Future<void> restoreSnapshot(Map<int, List<dynamic>> layouts) async {
    assert(
      UspLayoutEnvelope.persistedSlotCounts
          .every((slots) => layouts[slots] != null),
      'restoreSnapshot needs one layout per persisted breakpoint. '
      'Capture with exportAllBreakpoints().',
    );
    // Not normalised here: every grid handed to [_replaceController] is imported
    // through [_seedBreakpoints], which normalises each one.
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
  ///
  /// The card's form pick goes with it on every grid, because it is on the item
  /// being filtered out of each one (#1400). It used to take a second call to a
  /// second store, whose absence would have left the pick to reapply itself if the
  /// card were ever added back — arriving pre-collapsed for no visible reason.
  Future<void> removeWidget(String id) async {
    final layouts = _exportAllBreakpoints(state);
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
