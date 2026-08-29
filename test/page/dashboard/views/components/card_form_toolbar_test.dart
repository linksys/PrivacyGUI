@Tags(['layout-gate'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/card_grid_geometry.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/card_form_toolbar.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// #1299 AC 4 — the control that makes a form selectable, where the user is
/// looking when they need it.
///
/// The toolbar appears over the card the grid has selected, and offers that
/// card's forms. Three placements were tried before it:
///
/// * On the card. A spike result, not a taste call —
///   `test/page/dashboard/views/density_control_gesture_spike_test.dart` shows
///   that edit mode's `AbsorbPointer` swallows anything drawn inside a card, and
///   that hoisting a control above it arms a drag on desktop which
///   `cancelInteraction()` does not stop.
/// * In the layout settings dialog, which is where it first shipped. It asked the
///   user to find the card they were looking at in a list of every card's name, in
///   a dialog covering the grid they were looking at it in.
/// * As a row between the page header and the grid, which is what replaced the
///   dialog. Reviewed on screen and rejected: it reads as part of the dashboard's
///   chrome rather than as a control over the card that was just tapped.
///
/// This placement is not the on-card one that the spike ruled out. The toolbar is
/// a [Stack] sibling *above* `DashboardOverlay` — outside its gesture region,
/// drawn over the card rather than inside it — which is why the last group here
/// re-asks the spike's deciding question against the shape that shipped.
///
/// "Edit mode only" needs no assertion here and no guard in the widget: the layer
/// is built inside `if (!isEditMode) return grid` in
/// `usp_sliver_dashboard_view.dart`. What is asserted here is what can silently
/// drift: **which selection produces a toolbar**, **where it lands**, **that it is
/// glyphs on a frameless surface**, whether picking a form reaches the controller,
/// and whether the press that picks it can disturb the grid.
///
/// The mirror that carries the grid's selection into [selectedCardIdProvider] is
/// asserted in
/// `test/page/dashboard/providers/usp_layout_controller_selection_test.dart`; this
/// file drives the real controller, so the two meet at the real beacon rather than
/// at a stub.
///
/// ## Why the assertions name forms through the accessible label
///
/// The chips draw no text — each form is a glyph, and its name is carried in
/// [ChipItem.semanticLabel]. So "which form is this chip" is asked of
/// `semanticLabel` throughout, which is also the name a screen reader reads: an
/// assertion that passes here is an assertion that the chip is nameable at all.
/// The glyphs themselves are asserted once, in the group that owns them, and used
/// as the tap target everywhere else via `formIcons`.
///
/// ## Why the harness mounts a real grid
///
/// [CardFormToolbarLayer] takes the grid as its child, so the ordering the
/// placement depends on — toolbar painted after the overlay, therefore hit-tested
/// before it — is inside the widget under test rather than in the view. The
/// harness below mirrors `_buildSliverDashboard`'s wiring around it (the same
/// overlay, scroll view, sliver, spacings and page margin) with a stand-in card
/// widget, so the geometry assertions compare this ticket's arithmetic against
/// the rect the real `sliver_dashboard` gave the real card.
///
/// ## Mutation table
///
/// Each row is one edit to the real source, run against this file. One row sits
/// in `usp_layout_controller.dart` rather than in the toolbar: what "the
/// selection" is is decided there, and this file is where the consequence shows.
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | card_form_toolbar | drop the `options.isEmpty` guard | stats_panel gets a one-chip toolbar |
/// | 2 | card_form_toolbar | `context.currentMaxColumns` → a hard-coded 12 | the mobile-breakpoint pick reads as normal |
/// | 3 | card_form_toolbar | `selectedIndices` → always `{0}` | picking popup, and the pick it shows |
/// | 4 | card_form_toolbar | `Listener(behavior: opaque)` → `HitTestBehavior.deferToChild` | a press on the pill's rounded corner drags the card underneath |
/// | 5 | card_form_toolbar | drop the `cell.bottom <= 0` visibility check | the toolbar for a scrolled-away card stays on screen |
/// | 6 | card_form_toolbar | `_AboveTheCard._clamp` → the raw value | the toolbar leaves the layer at both edges |
/// | 7 | card_form_toolbar | drop the `controller.layout` subscription | the toolbar stays on the cell the card left |
/// | 8 | card_grid_geometry | `cellRect` ignores `scrollOffset` | the toolbar does not follow a scroll |
/// | 8b | card_grid_geometry | `dashboardRowsToHeight` drops the inter-row gap (4 rows → 480px, not 528) | a card of h rows is dashboardRowsToHeight(h) tall |
/// | 9 | usp_layout_controller | `_publishSelection` takes the first of the set instead of requiring one | two cards selected shows a toolbar |
/// | 10 | card_form_toolbar | `onSelectionChanged` drops the `option == picked` early return | **survived** — equivalent, see below |
/// | 11 | card_form_toolbar | `ChipItem.label: ''` → the form's name | the pill draws text, and stops being one width in every locale |
/// | 12 | card_form_toolbar | swap the popup and compact glyphs | the glyph the ladder puts under each form |
/// | 13 | card_form_toolbar | drop `showBorder: false` | the frameless assertion — a parameter read, see below |
/// | 14 | card_form_toolbar | drop `enhancedEffect: none` | the same assertion's other half — glass's shimmer border comes back |
///
/// ### Row 10, the equivalent mutation
///
/// Re-picking the form a card is already in is refused twice: here, and inside
/// `setCardForm`, which keeps the box it recorded on the way into popup rather
/// than overwriting it with the 2x1 tile. Removing *this* guard changes nothing
/// observable — the second call produces the same layout — so the row is an
/// equivalent mutation, and the guard is a saved pref write rather than the thing
/// protecting the restore. That invariant is stated where it is decided, in
/// `usp_card_form_persistence_test.dart` ("picking popup twice still restores the
/// first box, not the tile").
///
/// ### Rows 13 and 14, the assertions that read parameters
///
/// The frameless test asserts `AppSurface.showBorder` and `enhancedEffect` rather
/// than that no border is painted, which is weaker, and deliberately so. This
/// file's theme is `flat`, whose elevated surface has `borderWidth: 0` and a
/// transparent border colour — so under this theme the border was invisible either
/// way, and a paint assertion would pass with both parameters gone. The frame the
/// user saw belongs to `glass`, the demo's default, which draws one two ways:
/// `showBorder` gates the standard and gradient borders, and the animated shimmer
/// border is its *enhanced* effect, applied on the theme's shimmer bit alone
/// whatever `showBorder` says. Asserting the two parameters is asserting the
/// thing that carries into the themes where it is visible.
///
/// The chips are asserted the other way round — that they *are* still framed. The
/// kit builds their surfaces itself and offers no way to say otherwise, so the
/// test records the gap and fails when the kit closes it.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Desktop, so `context.currentMaxColumns` is 12 — the slot count a fresh
/// controller starts on, which is what makes a pick made here readable here.
const _desktopSurface = Size(1280, 900);

/// Mobile: `currentMaxColumns` 4, matching [UspLayoutEnvelope.mobileSlotCount].
const _mobileSurface = Size(500, 900);

/// Mirrors `UspSliverDashboardView._buildSliverDashboard` in edit mode, with a
/// stand-in for the card content.
///
/// The real `itemBuilder` reaches for every domain provider on the dashboard.
/// What this file needs from a card is its cell — so each one is a keyed box that
/// fills the cell, wrapped in the same `AbsorbPointer` production wraps it in.
class _GridHarness extends StatefulWidget {
  const _GridHarness({required this.controller, this.onItemDragStart});

  final DashboardController controller;

  /// Reports the id of any card the overlay arms a drag on.
  ///
  /// The overlay's own hook, which is the evidence the gesture group needs:
  /// "the layout is unchanged" also holds when a drag was armed and the pointer
  /// happened to end where it started, and on the desktop regime the spike
  /// measured, arming is the damage.
  final void Function(String cardId)? onItemDragStart;

  /// The key of the cell rendering [cardId], so a test can measure it.
  static Key cellKey(String cardId) => ValueKey('cell-$cardId');

  @override
  State<_GridHarness> createState() => _GridHarnessState();
}

class _GridHarnessState extends State<_GridHarness> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _itemBuilder(BuildContext context, LayoutItem item) => AbsorbPointer(
        child: SizedBox.expand(
          child: ColoredBox(
            key: _GridHarness.cellKey(item.id),
            color: Colors.blue.shade100,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final columns = context.currentMaxColumns;
    return LayoutBuilder(builder: (context, constraints) {
      final pageMargin = context.pageMargin;
      final availableWidth = constraints.maxWidth - pageMargin * 2;
      final slotWidth =
          (availableWidth - (columns - 1) * AppSpacing.lg) / columns;

      return CardFormToolbarLayer(
        geometry: CardGridGeometry(
          slotWidth: slotWidth,
          slotHeight: UspSliverDashboardView.slotHeight,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          padding: EdgeInsets.symmetric(horizontal: pageMargin),
        ),
        child: DashboardOverlay(
          controller: widget.controller,
          scrollController: _scrollController,
          itemBuilder: _itemBuilder,
          onItemDragStart: widget.onItemDragStart == null
              ? null
              : (item) => widget.onItemDragStart!(item.id),
          slotAspectRatio: slotWidth / UspSliverDashboardView.slotHeight,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          padding: EdgeInsets.symmetric(horizontal: pageMargin),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pageMargin),
                sliver: SliverDashboard(
                  itemBuilder: _itemBuilder,
                  slotAspectRatio:
                      slotWidth / UspSliverDashboardView.slotHeight,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.lg,
                  breakpoints: {0: columns},
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the toolbar over a real layout controller and a real grid.
  ///
  /// [allWidgetSpecsProvider] is overridden with the built-in specs so the
  /// package-widget loader — which reaches for `apps.json` over HTTP — is never
  /// constructed. It contributes nothing to this ticket: a package widget has no
  /// `WidgetSpec` in [UspWidgetSpecs], so `selectableForms` returns nothing for it
  /// and it is never offered a form.
  Future<ProviderContainer> pumpGrid(
    WidgetTester tester, {
    Size surface = _desktopSurface,
    void Function(String cardId)? onItemDragStart,
    Locale? locale,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      allWidgetSpecsProvider.overrideWithValue(UspWidgetSpecs.all),
    ]);
    addTearDown(container.dispose);

    final controller = container.read(uspSliverDashboardControllerProvider);
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    controller.setEditMode(true);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _testTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: _GridHarness(
            controller: controller,
            onItemDragStart: onItemDragStart,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  DashboardController controllerOf(ProviderContainer container) =>
      container.read(uspSliverDashboardControllerProvider);

  /// Selects [cardId] the way a tap on the card does, then lets the mirror land.
  Future<void> select(
    WidgetTester tester,
    ProviderContainer container,
    String cardId, {
    bool multi = false,
  }) async {
    controllerOf(container).toggleSelection(cardId, multi: multi);
    await tester.pumpAndSettle();
  }

  /// The toolbar's chips, which are what the toolbar *is*: with nothing to pick
  /// there is nothing drawn.
  final toolbar = find.byType(AppChipGroup);

  AppChipGroup readToolbar(WidgetTester tester) =>
      tester.widget<AppChipGroup>(toolbar);

  /// The forms on offer, read off the chips rather than off the source list, so
  /// the assertion sees what the user is offered.
  ///
  /// The chips are icon-only, so the name is the accessible label — which is the
  /// only place the form is named at all, and therefore the thing to read.
  List<String?> chipForms(WidgetTester tester) =>
      readToolbar(tester).chips.map((chip) => chip.semanticLabel).toList();

  /// The form the toolbar shows the card as being in.
  String? pickedForm(WidgetTester tester) {
    final widget = readToolbar(tester);
    return widget.chips[widget.selectedIndices.single].semanticLabel;
  }

  /// The glyph each form is offered as.
  ///
  /// A second copy of the production mapping, deliberately: these tests tap what
  /// the user taps, so a glyph that moves to another form has to be an edit here
  /// too rather than a silent re-labelling of the three chips.
  const formIcons = {
    CardDensity.normal: Icons.density_small,
    CardDensity.compact: Icons.density_medium,
    CardDensity.popup: Icons.density_large,
  };

  /// The floating pill itself — the surface, not the chips inside its padding.
  ///
  /// What the layout delegate positions is the surface, so that is what the
  /// position assertions have to read: the chip group sits `AppSpacing.xs` inside
  /// it, and measuring the chips would report the pill as 4px lower and narrower
  /// than it is. `.first` is the innermost ancestor, which is the pill's own
  /// surface rather than any the page wraps it in.
  final pill =
      find.ancestor(of: toolbar, matching: find.byType(AppSurface)).first;

  Rect pillRect(WidgetTester tester) => tester.getRect(pill);

  /// Taps the chip offering [form] — a real press on the real glyph, because
  /// whether that press reaches the chip at all is half of what this file
  /// asserts.
  Future<void> tapForm(WidgetTester tester, CardDensity form) async {
    await tester.tap(
      find.descendant(of: toolbar, matching: find.byIcon(formIcons[form]!)),
    );
    await tester.pumpAndSettle();
  }

  /// The layout item for [cardId], straight off the controller.
  Map readItem(ProviderContainer container, String cardId) => controllerOf(
        container,
      ).exportLayout().firstWhere((e) => (e as Map)['id'] == cardId) as Map;

  /// Coordinates per id, sorted by id — the spike's comparison, for the same
  /// reason: `exportLayout()` reorders on a drag while coordinates do not, and
  /// `moved` and friends flip on compaction.
  List<String> geometry(DashboardController controller) => (controller
          .exportLayout()
          .map((item) => '${item['id']}@${item['x']},${item['y']}'
              ' ${item['w']}x${item['h']}')
          .toList()
        ..sort())
      .toList();

  /// Runs [body] with [platform] in force, and clears the override before the
  /// body returns.
  ///
  /// Not `addTearDown`: `_verifyInvariants` runs at the end of the test body,
  /// *before* teardowns, and asserts every foundation debug variable is unset.
  Future<void> withPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('which selection produces a toolbar', () {
    testWidgets('nothing selected draws nothing', (tester) async {
      await pumpGrid(tester);

      expect(toolbar, findsNothing,
          reason: 'The toolbar answers "what can I do with this card", so it '
              'has nothing to say until there is one. It also cannot be drawn '
              'anywhere honest: its position is a card\'s position.');
    });

    testWidgets('selecting a card offers its forms', (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      expect(chipForms(tester), ['Normal', 'Compact', 'Popup'],
          reason: 'device_info declares normalAbove: 262, so it has a compact '
              'form.');
    });

    testWidgets('the forms offered are the ones the card actually built',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'topology');

      expect(chipForms(tester), ['Normal', 'Popup'],
          reason: 'topology declares no threshold, so no compact form was ever '
              'built for it. #1299 is explicit that building the other eleven '
              'is out of scope — so the toolbar must not offer a form that does '
              'not exist.');
    });

    testWidgets('two cards selected reads as no selection', (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');
      await select(tester, container, 'lan_info', multi: true);

      expect(controllerOf(container).selectedItemIds.value, hasLength(2));
      expect(toolbar, findsNothing,
          reason: 'A form is picked per card, so "the selection" has to be one '
              'card. Anchoring the toolbar to whichever card happens to be '
              'first in the set would be a guess at which one the user meant, '
              'and this placement makes the guess visible.');
    });

    testWidgets('a card with one form gets no toolbar', (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'stats_panel');

      expect(controllerOf(container).selectedItemIds.value, {'stats_panel'});
      expect(toolbar, findsNothing,
          reason:
              'stats_panel is the one card excluded from the popup form (it '
              'is the full-width hero row, which has no icon-and-one-value '
              'reading) and it declares no compact threshold. An empty surface '
              'floating over it would read as a control that does not work.');
    });

    testWidgets('a card removed while still selected takes the toolbar with it',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'lan_info');
      expect(toolbar, findsOneWidget);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .removeWidget('lan_info');
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing,
          reason:
              'A pick for a card that is not placed anywhere has nothing to '
              'apply to — `removeWidget` drops the stored pick for the same '
              'reason. What makes it hold is the package: `removeItems` clears '
              'the selection, so the mirror publishes null.');
    });
  });

  group('where the toolbar lands', () {
    /// A layout tall enough to scroll, with every card in the left half so that
    /// nothing floats: vertical compaction pulls a card up into any gap above it,
    /// so "row 4" only stays row 4 with a card directly underneath the top one.
    ///
    /// Imported rather than derived from the default layout, because these tests
    /// are about which row a card is in — top row (the clamped case) versus any
    /// other (the gap case) — and reading that out of the default layout would
    /// make them fail the day a card is added to it.
    Future<void> importTallColumn(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      controllerOf(container).importLayout([
        {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 4},
        {'id': 'lan_info', 'x': 0, 'y': 4, 'w': 6, 'h': 4},
        {'id': 'topology', 'x': 0, 'y': 8, 'w': 6, 'h': 4},
      ]);
      await tester.pumpAndSettle();
    }

    /// The rect the real grid gave [cardId].
    Rect cellRect(WidgetTester tester, String cardId) =>
        tester.getRect(find.byKey(_GridHarness.cellKey(cardId)));

    /// Scrolls the grid from a point the cards do not cover, so the gesture is a
    /// scroll rather than a card drag or a press on the toolbar.
    Future<void> scrollGrid(WidgetTester tester, double by) async {
      await tester.dragFrom(const Offset(1200, 450), Offset(0, by));
      await tester.pumpAndSettle();
    }

    testWidgets('it sits in the gap above its own card', (tester) async {
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);
      await select(tester, container, 'lan_info');

      final cell = cellRect(tester, 'lan_info');
      final bar = pillRect(tester);

      expect(bar.bottom, lessThanOrEqualTo(cell.top),
          reason: 'Above the card, not over it: the card is what the user is '
              'looking at while they pick, and the toolbar is only there '
              'because they selected it.');
      expect(bar.bottom, greaterThan(cell.top - 60),
          reason: 'And close enough to read as attached to it.');
      expect((bar.center.dx - cell.center.dx).abs(), lessThan(1),
          reason: 'Centred on the card it belongs to. This is the arithmetic '
              'that has no other check: the toolbar computes the cell itself '
              'from the layout coordinates, and here it is compared against the '
              'rect the grid actually laid the card out in.');
    });

    testWidgets('and a card of h rows is dashboardRowsToHeight(h) tall',
        (tester) async {
      // Not about the toolbar, but this is where a real grid is standing: the
      // popup form's presentation sizes itself to a *declared* row count
      // converted to pixels (#1299), and nothing else measures that conversion.
      // The overflow sweep does not — it stays green with the inter-row gap
      // dropped, because 480px is still room enough for every card's fixed
      // chrome. So the conversion is compared here against the box the grid
      // actually gives a 4-row card, the same way `cellRect` is.
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);

      expect(
        cellRect(tester, 'device_info').height,
        closeTo(dashboardRowsToHeight(4), 0.5),
        reason:
            'four slots plus the three gaps between them. A card asking for '
            'four rows and being handed three rows worth of pixels is the '
            'overflow this arithmetic feeds a fix for',
      );
    });

    testWidgets('a top-row card gets it inside the grid, not off the top',
        (tester) async {
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);
      await select(tester, container, 'device_info');

      final layer = tester.getRect(find.byType(CardFormToolbarLayer));
      final cell = cellRect(tester, 'device_info');
      final bar = pillRect(tester);

      expect(bar.top, closeTo(layer.top, 0.5),
          reason: 'device_info is in the top row, so the position the toolbar '
              'wants is off the top of the grid. Clamped, it rests on the card '
              'instead — where a flip would have put it anyway, and in edit mode '
              'the card underneath is inert.');
      expect(bar.bottom, greaterThan(cell.top),
          reason:
              'And resting *on* that card rather than in a strip of its own '
              'above it: the top row starts at the layer edge, so there is no '
              'gap left to sit in, and the toolbar has to overlap the card it '
              'belongs to instead of pointing at nothing.');
    });

    testWidgets('it stays inside the grid at the left and right edges',
        (tester) async {
      // The toolbar is wider than a narrow card, so a card at either edge is the
      // case where the position it wants is outside the layer.
      final container = await pumpGrid(tester);
      controllerOf(container).importLayout([
        {'id': 'device_info', 'x': 0, 'y': 0, 'w': 2, 'h': 2},
        {'id': 'lan_info', 'x': 10, 'y': 0, 'w': 2, 'h': 2},
      ]);
      await tester.pumpAndSettle();
      final layer = tester.getRect(find.byType(CardFormToolbarLayer));

      await select(tester, container, 'device_info');
      final atTheLeft = pillRect(tester);
      expect(
          atTheLeft.width, greaterThan(cellRect(tester, 'device_info').width),
          reason: 'The premise: a 2-column card really is narrower than the '
              'toolbar. Without this the next assertion could pass on a toolbar '
              'that never needed clamping.');
      expect(atTheLeft.left, greaterThanOrEqualTo(layer.left - 0.5),
          reason:
              'Centring a wider toolbar on a card at x: 0 would put part of '
              'it off the left of the page.');

      await select(tester, container, 'device_info'); // deselect
      await select(tester, container, 'lan_info');

      expect(pillRect(tester).right, lessThanOrEqualTo(layer.right + 0.5),
          reason: 'And the same at the other end, where the overflow would be '
              'clipped rather than merely ugly.');
    });

    testWidgets('it follows the card as the grid scrolls', (tester) async {
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);
      await select(tester, container, 'lan_info');
      final barBefore = pillRect(tester);
      final cellBefore = cellRect(tester, 'lan_info');

      await scrollGrid(tester, -80);

      final cellAfter = cellRect(tester, 'lan_info');
      expect(cellAfter.top, lessThan(cellBefore.top),
          reason: 'The grid has to have scrolled for the rest of this to mean '
              'anything.');
      expect(
        pillRect(tester).top - barBefore.top,
        closeTo(cellAfter.top - cellBefore.top, 1),
        reason:
            'The toolbar is positioned in the layer, which does not scroll, '
            'so following its card is the scroll offset arriving through the '
            'notification. Without it the toolbar stays put and ends up hanging '
            'over whatever card scrolls under it.',
      );
    });

    testWidgets('it follows its card when the layout moves underneath it',
        (tester) async {
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);
      await select(tester, container, 'lan_info');
      final before = pillRect(tester);

      // A card inserted above the selected one, which pushes it down a row. The
      // point is what does *not* change: the same card is selected, in the same
      // form, on the same breakpoint, at the same scroll offset — so nothing the
      // toolbar watches through Riverpod fires, and the layout beacon it
      // subscribes to is the only way it can hear about the move. A drag, a
      // resize or a preset swap reach it the same way.
      //
      // `w: 4`, so the card fits the narrowest grid as it stands. Adding straight
      // to the controller skips the alignment
      // `UspSliverDashboardControllerNotifier` does for every breakpoint, and
      // since #1393 that reaches the walk which stores the result: the package
      // places a card the other grids have not seen at the width it has here, and
      // never narrows it to fit. No production path adds this way — the settings
      // panel goes through `addWidget`, which is what the notifier now asserts. A
      // wider card here fails on that assertion; before it existed, it hung the
      // run instead (upstream fixed the non-termination in 2.3.0, brought in by
      // #1395 — the assertion is what still catches this).
      controllerOf(container)
          .addItem(const LayoutItem(id: 'stats_panel', x: 0, y: 0, w: 4, h: 2));
      await tester.pumpAndSettle();

      final cell = cellRect(tester, 'lan_info');
      expect(pillRect(tester).top, greaterThan(before.top),
          reason: 'The card moved down, so the toolbar has to move down with '
              'it.');
      expect(pillRect(tester).bottom, lessThanOrEqualTo(cell.top),
          reason:
              'And it is above the card it belongs to, at the cell the card '
              'now occupies, rather than merely somewhere lower.');
    });

    testWidgets('it goes away when its card scrolls out of view',
        (tester) async {
      final container = await pumpGrid(tester);
      await importTallColumn(tester, container);
      await select(tester, container, 'device_info');
      expect(toolbar, findsOneWidget);

      await scrollGrid(tester, -2000);

      expect(find.byKey(_GridHarness.cellKey('device_info')), findsNothing,
          reason: 'The card is far enough off the top of the viewport that the '
              'sliver has stopped building it at all.');
      expect(toolbar, findsNothing,
          reason:
              'A control clamped to the top edge instead would float over a '
              "different card — pointing at a selection the user can't see.");
    });
  });

  group('the pill is glyphs on a frameless surface', () {
    testWidgets('each form is a glyph, and no form is drawn as text',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      for (final chip in readToolbar(tester).chips) {
        expect(chip.icon, isNotNull);
        expect(chip.label, isEmpty,
            reason: 'An empty label is how `AppChipGroup` is asked for an '
                'icon-only chip: it skips the gap and the text.');
        expect(chip.semanticLabel, isNotNull,
            reason: 'The name has to survive the glyph, or the form is '
                'unnameable to a screen reader — the label is the only place it '
                'is still written down.');
      }
      expect(
        find.descendant(
            of: toolbar, matching: find.byIcon(Icons.density_small)),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<Text>(find.descendant(
              of: toolbar,
              matching: find.byType(Text),
            ))
            .every((text) => (text.data ?? '').isEmpty),
        isTrue,
        reason: 'And nothing is drawn: the chips still build a Text for their '
            'empty label, so the check is that none of them has anything in it.',
      );
    });

    testWidgets('the pill is the same width in every locale', (tester) async {
      // 480px is the narrowest width the loc snapshots are generated at
      // (`run_generate_loc_snapshots.sh`), and Polish is the longest of the 26
      // locales across the three form names — "Wyskakujące okno" for popup
      // alone. Labelled, that was the case where the pill either overflowed or
      // pushed itself off the page; as glyphs it is the case that proves there
      // is no longest locale left to check.
      final polish = await pumpGrid(
        tester,
        surface: const Size(480, 900),
        locale: const Locale('pl'),
      );
      await select(tester, polish, 'device_info');
      expect(chipForms(tester), hasLength(3),
          reason: 'The premise: `device_info` is the three-form case, so this '
              'is the widest the pill ever gets.');
      final inPolish = pillRect(tester);
      final layer = tester.getRect(find.byType(CardFormToolbarLayer));
      expect(inPolish.width, lessThanOrEqualTo(layer.width),
          reason: 'A pill wider than the page cannot be clamped into it — the '
              'delegate can only choose where it starts.');

      final english = await pumpGrid(
        tester,
        surface: const Size(480, 900),
        locale: const Locale('en'),
      );
      await select(tester, english, 'device_info');

      expect(pillRect(tester).width, closeTo(inPolish.width, 0.5));
    });

    testWidgets('the pill draws no border, by either route', (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      // Read off the widget rather than off the painted decoration, which is the
      // honest place for it: the borders that were loud are the ones a *style*
      // draws, and this file themes with flat, whose elevated surface has
      // `borderWidth: 0`. A decoration-level assertion would pass here either
      // way and pin nothing.
      //
      // Both parameters, because a style has two ways to draw a frame and each
      // has its own switch. `showBorder` stops the standard and gradient
      // borders; glass's shimmer border is its enhanced effect, which
      // `AppSurface` applies on the theme's shimmer bit alone — so it is the
      // intensity that has to be off. Dropping either one puts the frame back
      // under the style the demo actually runs.
      final surface = tester.widget<AppSurface>(pill);
      expect(surface.showBorder, isFalse);
      expect(surface.enhancedEffect, EnhancedEffectIntensity.none);
    });

    testWidgets('the chips are still framed, which is the kit\'s to fix',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      // Not an endorsement — a record. `AppChipGroup` builds each chip's
      // `AppSurface` itself with `showBorder` at its default, and offers nothing
      // to reach it with, so the three chips keep frames the pill has dropped.
      // Asserted so the day the kit exposes the passthrough this fails and says
      // where to use it, rather than the inconsistency quietly outliving the fix.
      final chipSurfaces = tester
          .widgetList<AppSurface>(
            find.descendant(of: toolbar, matching: find.byType(AppSurface)),
          )
          .toList();
      expect(chipSurfaces, hasLength(3), reason: 'one surface per chip');
      expect(
        chipSurfaces.every((surface) => surface.showBorder),
        isTrue,
        reason: 'if this fails, the kit grew a way to say otherwise — use it',
      );
    });
  });

  group('the toolbar reflects and writes the pick', () {
    testWidgets('with no pick stored it reads normal', (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      expect(pickedForm(tester), 'Normal',
          reason: 'Normal is the absence of a pick rather than a stored value, '
              'so an untouched card and a card explicitly set back to normal '
              'have to read the same.');
    });

    testWidgets('tapping popup collapses the card and locks it',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');
      final before = readItem(container, 'device_info');
      expect(before['w'], greaterThan(UspWidgetSpecs.popupColumns));

      await tapForm(tester, CardDensity.popup);

      expect(
        container
            .read(cardFormsProvider)
            .densityFor(UspLayoutEnvelope.desktopSlotCount, 'device_info'),
        CardDensity.popup,
      );
      final after = readItem(container, 'device_info');
      expect(after['w'], UspWidgetSpecs.popupColumns);
      expect(after['isResizable'], isFalse);
      expect(pickedForm(tester), 'Popup',
          reason: 'The toolbar rebuilds off cardFormsProvider, so it has to '
              'show the pick it just made.');
    });

    testWidgets('going back to normal restores the box it collapsed',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');
      final originalW = readItem(container, 'device_info')['w'];

      await tapForm(tester, CardDensity.popup);
      await tapForm(tester, CardDensity.normal);

      expect(readItem(container, 'device_info')['w'], originalW,
          reason: 'AC 9. The size is recorded on the way into popup, because '
              'once the handles are gone no gesture could recover it.');
      expect(readItem(container, 'device_info')['isResizable'], isNot(isFalse));
    });

    testWidgets('re-tapping the form the card is already in does nothing',
        (tester) async {
      final container = await pumpGrid(tester);
      await select(tester, container, 'device_info');

      await tapForm(tester, CardDensity.popup);
      final afterFirst = readItem(container, 'device_info');

      // What this pins is the *outcome*: a second pick of the same form leaves
      // the card byte-identical. It does not pin the toolbar's early return —
      // measured, that guard is an equivalent mutation, because `setCardForm` is
      // idempotent on its own (mutation table, row 10).
      await tapForm(tester, CardDensity.popup);

      expect(readItem(container, 'device_info'), afterFirst);
    });

    testWidgets('the pick it shows is the one for the breakpoint on screen',
        (tester) async {
      final container = await pumpGrid(tester, surface: _mobileSurface);
      controllerOf(container).setSlotCount(UspLayoutEnvelope.mobileSlotCount);
      await tester.pumpAndSettle();

      // A pick stored on mobile only — the desktop grid has none.
      container.read(cardFormsProvider.notifier).state =
          CardForms.empty.withChoice(
        UspLayoutEnvelope.mobileSlotCount,
        'device_info',
        const CardFormChoice(density: CardDensity.popup),
      );
      await select(tester, container, 'device_info');

      expect(pickedForm(tester), 'Popup',
          reason: 'Picks are per breakpoint (#1294 keeps each breakpoint\'s '
              'layout to itself, and a form is part of that layout). Reading '
              'the desktop slot count here would show normal on a phone that '
              'is rendering a popup.');
    });
  });

  // ---------------------------------------------------------------------------
  // The spike's question, re-asked against the shape that shipped.
  // ---------------------------------------------------------------------------
  group('the press that picks a form cannot disturb the grid', () {
    /// A press that travels far enough to carry a card clear of its own column
    /// span, then lifts — the spike's `acrossTheGrid`.
    Future<void> pressWithTravel(WidgetTester tester, Offset target) async {
      final gesture =
          await tester.startGesture(target, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    /// Two cards stacked, the lower one selected, so the toolbar sits in the gap
    /// above it and overlaps the card above.
    ///
    /// That overlap is what lets these tests fail: a press the toolbar does not
    /// absorb has to land on a card for the overlay to do anything with it, and
    /// the card above is the one the toolbar floats over.
    Future<ProviderContainer> pumpTwoStacked(
      WidgetTester tester,
      void Function(String cardId) onItemDragStart,
    ) async {
      final container =
          await pumpGrid(tester, onItemDragStart: onItemDragStart);
      controllerOf(container).importLayout([
        {'id': 'device_info', 'x': 0, 'y': 0, 'w': 6, 'h': 4},
        {'id': 'lan_info', 'x': 0, 'y': 4, 'w': 6, 'h': 4},
      ]);
      await tester.pumpAndSettle();
      await select(tester, container, 'lan_info');
      return container;
    }

    testWidgets('a press on the toolbar arms no drag on desktop',
        (tester) async {
      // macOS, because the spike showed the two gesture regimes differ and this
      // is the dangerous one: there the overlay arms a drag on pointer-down,
      // with no slop, and `cancelInteraction()` does not undo it.
      await withPlatform(TargetPlatform.macOS, () async {
        final dragStarts = <String>[];
        final container = await pumpTwoStacked(tester, dragStarts.add);
        final before = geometry(controllerOf(container));

        // The pill's own corner, half a pixel inside its box — measured, not
        // arbitrary. `AppSurface` paints a rounded `BoxDecoration`, and
        // `RenderDecoratedBox.hitTestSelf` asks the decoration, which says no
        // outside the radius; so the surface absorbs its whole interior by
        // itself, and the corners it rounds off are the only part
        // `HitTestBehavior.opaque` is holding. A press there with the behaviour
        // dropped reaches the card underneath and drags it.
        final pill = pillRect(tester);
        await pressWithTravel(tester, pill.topLeft + const Offset(0.5, 0.5));

        expect(dragStarts, isEmpty,
            reason: 'THE ASSERTION THIS PLACEMENT RESTS ON. The toolbar is a '
                'Stack sibling above DashboardOverlay, and RenderStack '
                'hit-tests children in reverse paint order and stops at the '
                'first hit — so a toolbar that absorbs the press means the '
                'overlay never sees it. The spike measured the alternative, and '
                "it is why the card was ruled out: a control inside the "
                "overlay's region is hit-tested *past*, to the item render box, "
                'and the card is displaced.');
        expect(geometry(controllerOf(container)), before);
        expect(container.read(selectedCardIdProvider), 'lan_info',
            reason: 'And the selection survives. A press that reaches the '
                'overlay clears the selection when no card is under it, which '
                'takes the toolbar away mid-interaction.');
      });
    });

    testWidgets('the same press on a card does displace it', (tester) async {
      // Without this the test above proves nothing: "no drag" would be
      // indistinguishable from "this harness cannot start one".
      await withPlatform(TargetPlatform.macOS, () async {
        final dragStarts = <String>[];
        final container = await pumpTwoStacked(tester, dragStarts.add);
        final before = geometry(controllerOf(container));

        // The very card the toolbar overlaps, pressed where the toolbar is not:
        // the same gesture, and clear of the 20px resize-handle band so this is a
        // drag rather than a resize.
        final cell = tester.getRect(find.byKey(
          _GridHarness.cellKey('device_info'),
        ));
        await pressWithTravel(tester, cell.center);

        expect(dragStarts, ['device_info']);
        expect(geometry(controllerOf(container)), isNot(before),
            reason:
                'The positive control. A pointer that travels this far over '
                'a card moves it, so the previous test is an answer rather than '
                'an inert rig.');
      });
    });

    testWidgets('a tap on a chip picks the form and starts no drag',
        (tester) async {
      await withPlatform(TargetPlatform.macOS, () async {
        final dragStarts = <String>[];
        final container = await pumpTwoStacked(tester, dragStarts.add);

        await tapForm(tester, CardDensity.popup);

        expect(pickedForm(tester), 'Popup',
            reason: 'The chip has to win its own tap through the opaque '
                'Listener above it — which carries no callbacks and so never '
                'enters the gesture arena.');
        expect(dragStarts, isEmpty);
        expect(container.read(selectedCardIdProvider), 'lan_info',
            reason: 'Picking a form is not deselecting the card: the pick is '
                'meant to be visibly applied to a card that is still selected.');
      });
    });
  });
}
