import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The persistence half of #1299, at the address #1400 moved it to: a picked form
/// is stored on the item it shaped, in the same copy of the same map as the
/// geometry it justifies.
///
/// ## What is being inverted
///
/// #1232 runs width → form: a card measures the box it was given and picks the
/// densest form that fits. This ticket adds the other direction — the user picks
/// the form and the form decides which sizes are legal:
///
/// | pick    | the size rule                                    |
/// |---------|--------------------------------------------------|
/// | popup   | pinned; no handles at all                         |
/// | compact | can be enlarged, cannot be shrunk below its floor |
/// | normal  | the spec's own bounds, and #1232 decides the form  |
///
/// `normal` is deliberately **not** a pin. Pinning it would let the user park a
/// 191px card in its full form, which is the overflow the parent epic (#1183)
/// exists to prevent — §2.1's guarantee only survives if the framework never
/// hands the user the job of avoiding it. So `normal` means "no constraint from
/// me": the spec bounds come back and the width decides the form again.
///
/// ## Where the pick lives (#1400)
///
/// On the item it describes, under `LayoutItem.extra`, inside the same `layouts`
/// entry as the geometry. #1299 kept it in a sibling `forms` map keyed by
/// `(slotCount, cardId)` and re-derived the geometry from it on every import,
/// because `LayoutItem` had a closed field set at the time and `exportLayout()`
/// dropped anything else — a claim this paragraph used to make and
/// `sliver_dashboard` 1.2.0 falsified. With `extra`,
/// `exportLayout`/`importLayout` round-trip the pick, `setSlotCount` keeps it per
/// grid, and a snapshot carries it whether or not the code that took the snapshot
/// remembered to.
///
/// Still per breakpoint, and now by construction rather than by a key: each slot
/// count has its own cached list of items, so "compact on a phone, normal on a
/// laptop" — the case this exists for — is two items carrying two picks rather
/// than one map that has to name the grid it means. A pref that was *not* keyed by
/// breakpoint is exactly the #1293 trap; a pref with no key to get wrong is one
/// step better.
///
/// ### What that costs: an import re-derives nothing
///
/// In v3 the stored geometry was never authoritative — every import recomputed it
/// from the `forms` map — so a payload whose geometry disagreed with its pick
/// healed itself on the next boot, and so did every stored layout on the day
/// [UspWidgetSpecs.popupColumns] or `compactMinColumns` changed. Now the two are
/// written together and read back as written, so a change to those constants
/// applies to picks made after it and leaves stored ones alone.
///
/// That is the trade this ticket makes on purpose: the pair can no longer
/// disagree, which is worth more than healing a disagreement that can no longer
/// arise. Re-deriving stored grids again would be a migration — the shape the v3
/// fold below already has — rather than a bug fix.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_layout_controller.dart`, applied to the real file
/// and run against this file and `card_form_choice_test.dart`; see that file for
/// the `usp_widget_specs.dart` half. Counts are from the run, not predicted.
///
/// Five rows are retired rather than deleted. Each of them is a mutation #1400
/// made *unwritable* — the code it edited no longer exists, and the property it
/// was measuring now holds by construction — so the row is the measurement of the
/// deletion, and dropping it would lose the only record that the guarantee used to
/// cost something. Rows 4-6 are #1299's measurement and were not re-taken; rows 1,
/// 8 and 11 were rewritten for the new seams and 13 is new, and those four were
/// measured against this revision.
///
/// Rows 13 and 14 both came out of the review of this ticket, and 14 is the more
/// interesting kind of gap: the code was right and untested. Every v3 fixture here
/// stored the desktop grid only, so all of them were *also* incomplete and reached
/// the re-save through the other disjunct — the migration's own reason to write was
/// never exercised until a fixture stored all three breakpoints.
///
/// Row 13 is the one guard #1400 *added*. The compact floor used to be re-imposed
/// on every import, as a side effect of re-deriving the geometry from the `forms`
/// map, so nothing had to hold it at the write; now [UspLayoutController.updateItemSize]
/// floors the size it is handed. It is the only writer that can go under a floor —
/// a resize gesture is clamped by the package, and that clamp is what
/// `card_form_control_test.dart` row 8 measures, on a pumped grid, because this
/// file cannot see it.
///
/// |  # | mutation                                          | killed by |
/// |----|---------------------------------------------------|-----------|
/// |  1 | `withCardForm` writes the pick but drops the `_applyCardForm` call | 12 — every geometry assertion here, and both AC 6 tests |
/// |  2 | ~~`_seedBreakpoints` drops the desktop pass~~ *retired by #1400* — `_normalize` is the mobile width lock again, so the desktop pass is identity at 12 columns. What made it load-bearing was the per-import form derivation, which is gone. |
/// |  3 | ~~`setCardForm` writes the pick to every breakpoint~~ *retired by #1400* — there is no per-breakpoint key left to write wrongly. The property is still asserted below; it just costs nothing to hold. |
/// |  4 | `setCardForm` never records `restoreW`/`restoreH`  | 3 — all three restore tests |
/// |  5 | `setCardForm` rebuilds the choice on re-entry, so popup twice records the tile | picking popup twice still restores the first box |
/// |  6 | `setCardForm` skips the `selectableForms` guard    | popup / compact is refused on a card that has no such form |
/// |  7 | ~~`saveLayout` drops `forms` from the envelope~~ *retired by #1400* — there is no `forms` key to drop; the pick is inside the item `saveLayout` already writes. That this mutation cannot be written is what AC 6 asks for. |
/// |  8 | `_initializeLayout` skips the `migratedPicks` re-derivation | 2 — the geometry a folded pick implies, and the migration is paid once |
/// |  9 | ~~`removeWidget` keeps the deleted card's pick~~ *retired by #1400* — the pick is on the item, so removing the item removes it. |
/// | 10 | ~~`resetLayout` keeps the picks~~ *retired by #1400* — same reason: the default layout carries no `extra`. |
/// | 11 | `_armFormsMirror` never subscribes, so the read model is never published | 3 — both read-model tests and the AC 6 import |
/// | 12 | ~~`UspLayoutEnvelope.version` keys on `forms.isEmpty`~~ *moved* — the stamp is computed by walking the items now, so the mutation and its unit test live in `usp_layout_envelope_test.dart`. The end-to-end rollback case stays here. |
/// | 13 | `updateItemSize` writes the size it is handed without flooring it | shrinking below the floor is refused |
/// | 14 | `_initializeLayout` re-saves on `incomplete` only, dropping the `migratedPicks` disjunct | a v3 payload that stored every breakpoint is migrated too |
///
/// Row 5 was added after the fact: the panel's "re-picking the same form does
/// nothing" guard turned out to be an *equivalent* mutation (see that file's
/// ledger), which is what exposed that the invariant it looked like it was
/// protecting had no test where the invariant actually lives.
///
/// ### One survivor, and why it is left alive
///
/// Swapping the two rules where they still meet — `lockToFullWidth` first, forms
/// second, inside [UspWidgetSpecs.scaleLayout] — survives, and is supposed to:
/// each rule abstains from the other's axis on the phone grid, so the two orders
/// produce the same layout by construction. A test that pinned the order would be
/// testing an implementation detail we deliberately made irrelevant. What *is*
/// tested is the consequence: popup on a phone keeps the full width and takes only
/// the height.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Wait for the notifier's async init/save chains to settle.
  Future<void> pumpAsync() => Future.delayed(const Duration(milliseconds: 100));

  Future<ProviderContainer> boot({Map<String, Object>? initialValues}) async {
    if (initialValues != null) {
      SharedPreferences.setMockInitialValues(initialValues);
    }
    final container = ProviderContainer();
    container.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return container;
  }

  /// Reboots against whatever is already in the mock pref store.
  Future<ProviderContainer> reboot() async {
    final container = ProviderContainer();
    container.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return container;
  }

  Future<String> storedRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(pUspSliverDashboardLayout);
    expect(raw, isNotNull, reason: 'Nothing was persisted.');
    return raw!;
  }

  Future<UspLayoutEnvelope> storedEnvelope() async {
    final envelope = UspLayoutEnvelope.tryDecode(await storedRaw());
    expect(envelope, isNotNull, reason: 'Persisted value is unreadable.');
    return envelope!;
  }

  Map<String, Object?> itemNamed(List<dynamic> layout, String id) =>
      (layout.firstWhere((item) => (item as Map)['id'] == id) as Map)
          .cast<String, Object?>();

  /// The pick the persisted payload carries for [id] on the [slots]-column grid,
  /// read off the item the way every consumer reads it (#1400).
  Future<CardFormChoice?> storedPick(int slots, String id) async {
    final layout = (await storedEnvelope())[slots];
    if (layout == null) return null;
    for (final item in layout) {
      if ((item as Map)['id'] == id) {
        return CardFormChoice.readFrom(item['extra']);
      }
    }
    return null;
  }

  /// The card as the grid currently holds it, on [slots] columns.
  Map<String, Object?> live(
    ProviderContainer container,
    String id, {
    int slots = 12,
  }) {
    final controller = container.read(uspSliverDashboardControllerProvider);
    controller.setSlotCount(slots);
    return itemNamed(controller.exportLayout(), id);
  }

  Future<void> pick(
    ProviderContainer container,
    String id,
    CardDensity density, {
    int? slots,
  }) async {
    if (slots != null) {
      container.read(uspSliverDashboardControllerProvider).setSlotCount(slots);
    }
    await container
        .read(uspSliverDashboardControllerProvider.notifier)
        .setCardForm(id, density);
  }

  /// A v3 payload: geometry in `layouts`, picks in the sibling map #1400 deleted.
  ///
  /// Hand-built rather than produced by an older build, so the shape is stated
  /// where the migration reading it can be seen — this is the only payload shape
  /// this build can no longer write.
  /// A v3 payload: the layouts, and the picks in the sibling map beside them.
  ///
  /// [everyBreakpoint] stores the narrow grids too, the way any install that ever
  /// resized its window would have. It matters because a payload holding all
  /// three is *complete*, so the fold is the only thing left that can make the
  /// migration write itself back.
  String v3(
    Map<String, Map<String, Object>> forms, {
    bool everyBreakpoint = false,
  }) =>
      jsonEncode({
        'version': 3,
        'layouts': {
          '12': _defaultishLayout(),
          if (everyBreakpoint) ...{
            '8': UspWidgetSpecs.scaleLayout(_defaultishLayout(), 12, 8),
            '4': UspWidgetSpecs.scaleLayout(_defaultishLayout(), 12, 4),
          },
        },
        'forms': forms,
      });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ---------------------------------------------------------------------------
  // AC 5: per breakpoint, surviving a reload, with no cross-contamination
  // ---------------------------------------------------------------------------
  group('a pick belongs to the breakpoint it was made on', () {
    test('a pick made at desktop leaves the phone grid alone', () async {
      final first = await boot();
      final phoneBefore = live(first, 'device_info', slots: 4);
      await pick(first, 'device_info', CardDensity.popup, slots: 12);
      first.dispose();

      final second = await reboot();
      addTearDown(second.dispose);

      expect(live(second, 'device_info', slots: 4), phoneBefore,
          reason: 'A desktop pick reached the phone geometry. Each slot count '
              'has its own cached list of items, which is what makes the pick '
              'per grid now that it rides on one of them.');
      expect(await storedPick(4, 'device_info'), isNull,
          reason: 'And the phone grid\'s copy of the card carries no pick, '
              'which is the same claim one layer down: there is no map that '
              'could have filed a desktop pick under the wrong slot count.');
    });

    test('a pick made on a phone survives a reboot and stays there', () async {
      final first = await boot();
      final desktopBefore = live(first, 'device_info', slots: 12);
      await pick(first, 'device_info', CardDensity.popup, slots: 4);
      first.dispose();

      final second = await reboot();
      addTearDown(second.dispose);

      expect(live(second, 'device_info', slots: 4)['h'], 1,
          reason: 'The phone pick did not come back.');
      expect(live(second, 'device_info', slots: 12), desktopBefore,
          reason: 'A phone pick rewrote the desktop grid — #1293 all over '
              'again, this time through the form control.');
    });

    test('one card can be compact on a phone and normal on a laptop', () async {
      final first = await boot();
      await pick(first, 'device_info', CardDensity.compact, slots: 4);
      await pick(first, 'device_info', CardDensity.normal, slots: 12);
      first.dispose();

      expect(
          (await storedPick(4, 'device_info'))?.density, CardDensity.compact);
      expect(
          (await storedPick(12, 'device_info'))?.density, CardDensity.normal);
    });

    test('the pick reaches the pref, not just the controller', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);

      expect((await storedPick(12, 'device_info'))?.density, CardDensity.popup,
          reason: 'The geometry was constrained but the reason was not stored, '
              'so nothing could tell a 2x1 tile from a card the user dragged '
              'that small — and the way out of popup would have no size to '
              'restore.');
    });

    test(
        'a card derived into a grid that predates it arrives in its picked form',
        () async {
      // The membership seam, and the one place a pick crosses a breakpoint the
      // user *did* arrange. A stored narrow grid can predate a card the desktop
      // grid has — that is what `alignMembership` exists for — and the missing
      // card is derived from the desktop one, so it arrives carrying the desktop
      // item's `extra` whatever else happens.
      //
      // Given that, the geometry has to be the pick's. A scale is proportional
      // and a pin is not: scaling a 2-column tile 12 -> 8 gives it one column,
      // which is a size the user never chose and the form cannot render in. The
      // choice #1400 makes is that a derived card is derived whole — position,
      // size and form together — rather than arriving in a form its own `extra`
      // contradicts.
      final desktop = UspWidgetSpecs.withCardForm(
        _defaultishLayout(),
        'device_info',
        const CardFormChoice(density: CardDensity.popup),
        cols: 12,
      );
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({
          12: desktop,
          8: UspWidgetSpecs.scaleLayout(_defaultishLayout(), 12, 8)
              .where((item) => (item as Map)['id'] != 'device_info')
              .toList(),
        }).encode(),
      });
      addTearDown(container.dispose);

      final derived = live(container, 'device_info', slots: 8);
      expect([derived['w'], derived['h']], [2, 1],
          reason: 'Scaled instead of re-derived this is 1 column wide, because '
              'the desktop item it came from is already pinned at 2 of 12.');
      expect(derived['isResizable'], isFalse);
      expect((await storedPick(8, 'device_info'))?.density, CardDensity.popup,
          reason: 'And the form it renders in is the form its own stored pick '
              'names, on the grid it was derived onto.');
    });
  });

  // ---------------------------------------------------------------------------
  // AC 6: the pick and the geometry it justifies are one stored value (#1400)
  // ---------------------------------------------------------------------------
  group('a pick and its geometry cannot be persisted out of step', () {
    test('every stored grid already carries the geometry its picks imply',
        () async {
      // The claim in general form, over the whole payload: re-deriving the
      // geometry of every stored grid from the picks it carries is a no-op. Under
      // #1299 this could not even be asked — the picks were in a sibling map, and
      // the stored geometry was whatever the last save happened to hold, correct
      // only because every import recomputed it.
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await pick(container, 'device_info', CardDensity.compact, slots: 8);
      await pick(container, 'lan_info', CardDensity.popup, slots: 4);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(12);
      await notifier.updateItemSize('lan_info', 8, 4);

      final envelope = await storedEnvelope();
      for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
        final layout = envelope[slots];
        expect(layout, isNotNull, reason: 'Grid $slots was never persisted.');
        expect(
          UspWidgetSpecs.applyPickedForms(layout!, slots),
          layout,
          reason: 'Grid $slots holds a pick whose geometry is not the geometry '
              'that pick implies at $slots columns. The two are written by one '
              'call into one copy of one map, so the only way they can differ on '
              'disk is if something wrote one of them alone.',
        );
      }
    });

    test('an import re-derives nothing, so a stored grid is its own bytes',
        () async {
      // The other face of the same coin, and the cost named in the header. The app
      // can no longer produce a payload whose halves disagree — that is the test
      // above — so one has to be planted to observe that nothing repairs it.
      final planted = _defaultishLayout();
      planted.last['extra'] =
          const CardFormChoice(density: CardDensity.popup).writeInto(null);
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({12: planted}).encode(),
      });
      addTearDown(container.dispose);

      final stored = live(container, 'device_info', slots: 12);
      expect([stored['w'], stored['h']], [6, 3],
          reason: 'A stored grid is imported as written. #1299 recomputed the '
              'geometry from the pick on every import, which healed a payload '
              'like this one — and re-derived seventeen cards on every boot to do '
              'it.');
      expect(container.read(cardFormsProvider).densityFor('device_info'),
          CardDensity.popup,
          reason: 'The pick is still honoured for rendering: the box is the '
              'bytes\', the form is the pick\'s.');

      final derived = live(container, 'device_info', slots: 8);
      expect([derived['w'], derived['h']], [2, 1],
          reason: 'A grid nobody stored is *created* on load, and creation is '
              'the one place the geometry is derived from the pick — see '
              'UspWidgetSpecs.applyPickedForms. So "no healing" is specific: it '
              'means the grids the user arranged are left alone.');
    });
  });

  // ---------------------------------------------------------------------------
  // AC 6 / AC 8: popup pins the box, and shares the phone grid with #1293
  // ---------------------------------------------------------------------------
  group('popup collapses the card and takes its handles away', () {
    test('popup pins a 2x1 tile on the desktop grid', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      final item = live(container, 'device_info');

      expect(item['w'], 2);
      expect(item['h'], 1);
      expect(item['isResizable'], isFalse,
          reason:
              'One value and the card name has no use for a larger box, and '
              'a locked-but-huge popup would be unrecoverable.');
    });

    test('the pin survives the round trip through the pref', () async {
      final first = await boot();
      await pick(first, 'device_info', CardDensity.popup, slots: 12);
      first.dispose();

      final second = await reboot();
      addTearDown(second.dispose);
      final item = live(second, 'device_info');

      expect(item['w'], 2);
      expect(item['minW'], 2);
      expect(item['maxW'], 2.0);
      expect(item['isResizable'], isFalse);
      expect(CardFormChoice.readFrom(item['extra'])?.density, CardDensity.popup,
          reason: 'Both halves came back, off one item. A reboot is where a '
              'write that saved one of them alone shows up.');
    });

    test('popup on a phone keeps the full width and takes only the height',
        () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 4);
      final item = live(container, 'device_info', slots: 4);

      expect(item['w'], 4,
          reason: 'On a 4-column grid the width is #1293\'s, '
              'not the form\'s: each rule owns one axis, so popup becomes a short '
              'full-width bar.');
      expect(item['minW'], 4);
      expect(item['maxW'], 4.0);
      expect(item['h'], 1);
      expect(item['isResizable'], isFalse);
    });

    test('the live width lock leaves a popup tile alone', () async {
      // `lockItemsToFullWidth` watches the layout beacon and rewrites anything
      // that is not `x=0, w=slotCount`. A popup tile on a phone already is, so
      // the guard has to read as a no-op rather than fighting the pin.
      final container = await boot();
      addTearDown(container.dispose);
      final controller = container.read(uspSliverDashboardControllerProvider);

      await pick(container, 'device_info', CardDensity.popup, slots: 4);
      final beacon = controller.layout.value
          .firstWhere((item) => item.id == 'device_info');

      expect(beacon.x, 0);
      expect(beacon.w, 4);
      expect(beacon.h, 1);
    });

    test('popup is refused on a card that has no popup form', () async {
      final container = await boot();
      addTearDown(container.dispose);

      // stats_panel is not built through DashboardCardTemplate, so it has no
      // reduced form to collapse into. Note its default height is already 1 row,
      // so the assertion has to be the handles and the pick, not the box.
      await pick(container, 'stats_panel', CardDensity.popup, slots: 12);

      expect(live(container, 'stats_panel')['isResizable'], isNot(isFalse));
      expect(await storedPick(12, 'stats_panel'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AC 9: leaving popup gives the box back
  // ---------------------------------------------------------------------------
  group('returning to normal restores the box popup collapsed', () {
    test('normal restores the w and h the card had before popup', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final before = live(container, 'device_info');

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await pick(container, 'device_info', CardDensity.normal);

      final after = live(container, 'device_info');
      expect(after['w'], before['w']);
      expect(after['h'], before['h']);
    });

    test('normal restores the handles and the spec bounds', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final before = live(container, 'device_info');

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await pick(container, 'device_info', CardDensity.normal);

      final after = live(container, 'device_info');
      expect(after['isResizable'], isNot(isFalse),
          reason: 'The handles have to come back, or the restore is only '
              'cosmetic — the card is still locked at whatever it restored to.');
      expect(after['minW'], before['minW']);
      expect(after['maxW'], before['maxW']);
      expect(after['minH'], before['minH']);
    });

    test('a size chosen before popup is what comes back, not the default',
        () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(12);
      await notifier.updateItemSize('device_info', 8, 5);

      await pick(container, 'device_info', CardDensity.popup);
      await pick(container, 'device_info', CardDensity.normal);

      final after = live(container, 'device_info');
      expect(after['w'], 8);
      expect(after['h'], 5);
    });

    test('each breakpoint restores its own size', () async {
      // Sizes chosen inside device_info's own caps on each grid: maxColumns 8
      // scales to 5 on the 8-column grid, and `normal` restores the spec bounds,
      // so a card parked outside them would legitimately be pulled in and the
      // test would be measuring that instead of the restore.
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(8);
      await notifier.updateItemSize('device_info', 4, 2);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(12);
      await notifier.updateItemSize('device_info', 6, 4);

      for (final slots in [8, 12]) {
        await pick(container, 'device_info', CardDensity.popup, slots: slots);
      }
      for (final slots in [8, 12]) {
        await pick(container, 'device_info', CardDensity.normal, slots: slots);
      }

      expect(live(container, 'device_info', slots: 8)['w'], 4);
      expect(live(container, 'device_info', slots: 8)['h'], 2);
      expect(live(container, 'device_info', slots: 12)['w'], 6);
      expect(live(container, 'device_info', slots: 12)['h'], 4);
    });

    test('picking popup twice still restores the first box, not the tile',
        () async {
      // The pick is idempotent, and this is where that matters: the second call
      // reads the card's `w` *after* the collapse, so a `setCardForm` that
      // rebuilt the choice each time would write `restoreW: 2` and the way back
      // would restore the tile it was already in. The panel also refuses to call
      // through for a form the card is already in, but that guard is a saved
      // write rather than the thing protecting this — so the invariant is stated
      // where it is decided.
      final container = await boot();
      addTearDown(container.dispose);
      final before = live(container, 'device_info');

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await pick(container, 'device_info', CardDensity.popup);
      await pick(container, 'device_info', CardDensity.normal);

      final after = live(container, 'device_info');
      expect(after['w'], before['w']);
      expect(after['h'], before['h']);
    });

    test('a card parked outside its spec bounds is pulled inside them',
        () async {
      // The other half of the rule above, stated on purpose: `normal` means the
      // spec's bounds, so a width no grid ever allowed does not survive it.
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(8);
      await notifier.updateItemSize('device_info', 8, 2);

      await pick(container, 'device_info', CardDensity.normal);

      final item = live(container, 'device_info', slots: 8);
      expect(item['maxW'], 5.0,
          reason: 'maxColumns 8 of 12 is 5 of 8 — the cap is a fraction of the '
              'grid, not a width.');
      expect(item['w'], 5);
    });
  });

  // ---------------------------------------------------------------------------
  // AC 7: compact raises the floor without capping the ceiling
  // ---------------------------------------------------------------------------
  group('compact can be enlarged but not shrunk', () {
    test('compact raises minW above what the spec declares', () async {
      final container = await boot();
      addTearDown(container.dispose);
      expect(live(container, 'device_info')['minW'], 3,
          reason: 'Guard on the fixture: device_info declares minColumns 3, so '
              'the raise to 4 below is a real change.');

      await pick(container, 'device_info', CardDensity.compact, slots: 12);

      expect(live(container, 'device_info')['minW'], 4,
          reason: 'Compact\'s floor is the width at which the reduced form '
              'still reads: 3 columns is 191.4px, under kPopupBelow.');
    });

    test('a card already narrower than the floor is grown to it', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(12);
      await notifier.updateItemSize('device_info', 3, 3);

      await pick(container, 'device_info', CardDensity.compact);

      expect(live(container, 'device_info')['w'], 4,
          reason: 'A floor that leaves the card below it is not a floor.');
    });

    test('shrinking below the floor is refused', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      await pick(container, 'device_info', CardDensity.compact, slots: 12);
      await notifier.updateItemSize('device_info', 3, 3);

      expect(live(container, 'device_info')['w'], 4);
    });

    test('enlarging past the floor still works', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      await pick(container, 'device_info', CardDensity.compact, slots: 12);
      await notifier.updateItemSize('device_info', 8, 4);

      final item = live(container, 'device_info');
      expect(item['w'], 8,
          reason: 'Compact constrains the floor only. Widening a compact card '
              'is how the user discovers they would rather have it normal.');
      expect(item['h'], 4);
      expect(item['isResizable'], isNot(isFalse));
    });

    test('the floor is scaled to the grid it is applied on', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.compact, slots: 8);

      expect(live(container, 'device_info', slots: 8)['minW'], 3,
          reason: '4 of 12 columns is 3 of 8. A column count names a fraction '
              'of the grid, not a width.');
    });

    test('compact on a phone raises the height floor and nothing else',
        () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.compact, slots: 4);
      final item = live(container, 'device_info', slots: 4);

      expect(item['minW'], 4, reason: 'The phone width belongs to #1293.');
      expect(item['maxW'], 4.0);
      expect(item['minH'], greaterThanOrEqualTo(2));
    });

    test('compact is refused on a card with no compact form', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'topology', CardDensity.compact, slots: 12);

      expect(await storedPick(12, 'topology'), isNull,
          reason: 'Offering compact where no compact form was built would '
              'render the normal form in a box sized for a smaller one.');
    });

    test('compact reached from popup gets its spec ceiling back, not its floor',
        () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await pick(container, 'device_info', CardDensity.compact, slots: 12);
      final item = live(container, 'device_info', slots: 12);

      expect(item['maxW'], 8.0,
          reason: 'Every arm has to be independent of the arm before it. Popup '
              'pins by writing the caps *down*; a compact arm that only ever '
              'raises minima would leave those caps at 2x1, so the card would '
              'come out of popup capped at its own new floor and no gesture '
              'could widen it again.');
      expect(item['maxH'], 6.0);
      expect(item['minW'], 4, reason: "Still compact's floor.");
      expect(item['w'], 6, reason: 'And still the box popup collapsed.');
      expect(
          (await storedPick(12, 'device_info'))?.density, CardDensity.compact);
    });
  });

  // ---------------------------------------------------------------------------
  // Picks are part of the layout, so they follow its lifecycle
  // ---------------------------------------------------------------------------
  group('a pick has the same lifetime as the card', () {
    test('deleting the card drops its pick', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await notifier.removeWidget('device_info');
      await notifier.addWidget('device_info');

      expect(live(container, 'device_info')['isResizable'], isNot(isFalse),
          reason: 'A card added back arrived pre-collapsed by a pick made '
              'before it was deleted. Free now that the pick is on the item — '
              '#1299 had to prune a sibling map to get it.');
      expect(await storedPick(12, 'device_info'), isNull);
    });

    test('resetLayout clears every pick', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      await notifier.resetLayout();

      expect(container.read(cardFormsProvider).isEmpty, isTrue);
      expect(live(container, 'device_info')['isResizable'], isNot(isFalse));
    });

    test('the read model carries what was loaded from the pref', () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({
          12: UspWidgetSpecs.withCardForm(
            _defaultishLayout(),
            'device_info',
            const CardFormChoice(density: CardDensity.compact),
            cols: 12,
          ),
        }).encode(),
      });
      addTearDown(container.dispose);

      expect(
        container.read(cardFormsProvider).densityFor('device_info'),
        CardDensity.compact,
        reason:
            'CardDensityHost reads the picks from the read model, and since '
            '#1400 that model is a projection of the live grid\'s items — so a '
            'pick that reached the layout but not the projection renders as no '
            'pick at all.',
      );
    });

    test('a stored pick renders in the form it names', () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({
          12: UspWidgetSpecs.withCardForm(
            _defaultishLayout(),
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
            cols: 12,
          ),
        }).encode(),
      });
      addTearDown(container.dispose);

      final item = live(container, 'device_info');
      expect(item['w'], 2);
      expect(item['h'], 1);
      expect(item['isResizable'], isFalse,
          reason: 'The load path has to carry the geometry through unchanged, '
              'which is a weaker requirement than #1299\'s — it re-derived this '
              'on every import — and a load that dropped `extra` would fail here '
              'rather than silently rendering a card with handles the user gave '
              'up.');
    });

    test('the read model follows a pick made after load', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);

      expect(container.read(cardFormsProvider).densityFor('device_info'),
          CardDensity.popup);
    });
  });

  // ---------------------------------------------------------------------------
  // The one-time migration #1400 owes an install that picked a form in v3
  // ---------------------------------------------------------------------------
  group('a v3 payload\'s picks move onto their items', () {
    test('the pick survives and the geometry it implies is re-derived',
        () async {
      // Re-derived rather than trusted: in v3 the stored geometry was recomputed
      // from the `forms` map on every import, so the bytes beside the pick were
      // never what the grid rendered. Here the stored item is a 6x3 card whose
      // pick says popup, which is exactly the state a v3 payload is always in.
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: v3({
          '12': {
            'device_info': {'density': 'popup'}
          }
        }),
      });
      addTearDown(container.dispose);

      final item = live(container, 'device_info');
      expect([item['w'], item['h']], [2, 1]);
      expect(item['isResizable'], isFalse);
      expect((await storedPick(12, 'device_info'))?.density, CardDensity.popup);
    });

    test('the restore size comes across, so popup stays a two-way door',
        () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: v3({
          '12': {
            'device_info': {'density': 'popup', 'restoreW': 8, 'restoreH': 5}
          }
        }),
      });
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.normal, slots: 12);

      final item = live(container, 'device_info');
      expect([item['w'], item['h']], [8, 5],
          reason:
              'An install that was sitting in popup when it upgraded has no '
              'handles to drag the card back with, so the box it remembers is '
              'the only way out. A migration that dropped it would turn every '
              'popup card into a permanent 2x1 tile.');
    });

    test('the migration is paid once', () async {
      final first = await boot(initialValues: {
        pUspSliverDashboardLayout: v3({
          '12': {
            'device_info': {'density': 'popup'}
          }
        }),
      });
      first.dispose();

      final raw = await storedRaw();
      expect((jsonDecode(raw) as Map).containsKey('forms'), isFalse,
          reason: 'The sibling map is what this ticket deletes. Left in the '
              'pref it would be re-read on every boot, and two stores that '
              'describe the same cards can disagree.');
      expect(jsonDecode(raw)['version'], UspLayoutEnvelope.currentVersion);

      final second = await reboot();
      addTearDown(second.dispose);
      final item = live(second, 'device_info');
      expect([item['w'], item['h']], [2, 1],
          reason:
              'And the second boot is an ordinary one: it reads the pick off '
              'the item and imports the geometry as written.');
    });

    test('a v3 payload that stored every breakpoint is migrated too', () async {
      // The fixtures above store the desktop grid only, so `_initializeLayout`
      // re-saves them for being *incomplete* and the migration rides along on a
      // write it did not ask for. An install that ever resized its window stored
      // all three, and there the fold is the only reason to write anything back —
      // without it the payload keeps its v3 stamp and its `forms` map, and is
      // re-folded on every boot until the user's next edit.
      final first = await boot(initialValues: {
        pUspSliverDashboardLayout: v3(
          {
            '12': {
              'device_info': {'density': 'popup'}
            }
          },
          everyBreakpoint: true,
        ),
      });
      first.dispose();

      final raw = jsonDecode(await storedRaw()) as Map;
      expect(raw.containsKey('forms'), isFalse);
      expect(raw['version'], UspLayoutEnvelope.currentVersion);
      expect((await storedPick(12, 'device_info'))?.density, CardDensity.popup);
    });

    test('a v3 pick for a card the payload does not hold is dropped', () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: v3({
          '12': {
            'a_card_we_removed': {'density': 'popup'}
          }
        }),
      });
      addTearDown(container.dispose);

      expect(
          container.read(uspSliverDashboardControllerProvider).exportLayout(),
          hasLength(2),
          reason: 'There is no item to write the pick onto, and inventing one '
              'would add a card the user deleted. Picks outlive deletions in a '
              'v3 pref, so this is the state of any install that removed a card '
              'it had picked a form for.');
      expect(
          (jsonDecode(await storedRaw()) as Map).containsKey('forms'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // AC 10-adjacent: an install that never touches the control is unchanged
  // ---------------------------------------------------------------------------
  group('the control is invisible until it is used', () {
    test('a dashboard nobody picked a form on writes no pick at all', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final raw = await storedRaw();

      expect(raw, isNot(contains('forms')),
          reason: 'Every existing install must write the bytes it wrote '
              'before #1299, or the first launch after upgrade is a migration.');
      expect(raw, isNot(contains('extra')),
          reason: 'And #1400 moves the picks rather than adding a key: '
              '`LayoutItem.toMap` omits `extra` when it is null, so an install '
              'with no picks writes the same bytes it did before this ticket '
              'too.');
    });

    test('a v2 payload loads with no picks and is not rejected', () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: jsonEncode({
          'version': 2,
          'layouts': {'12': _defaultishLayout()},
        }),
      });
      addTearDown(container.dispose);

      expect(container.read(cardFormsProvider).isEmpty, isTrue);
      expect(live(container, 'device_info')['isResizable'], isNot(isFalse));
    });

    test('trying popup and changing your mind leaves the stamp at v2',
        () async {
      // The rollback case the stamp exists for, driven through the real control
      // rather than asserted on a hand-built envelope. `setCardForm` records an
      // explicit normal as a pick — it has to, or the pick could not out-rank the
      // width-derived form — so keying the stamp on "are there picks at all"
      // pinned the payload at v3 from the first popup onwards, for a card that
      // ends up carrying nothing an older build cannot read.
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);
      expect(jsonDecode(await storedRaw())['version'],
          UspLayoutEnvelope.currentVersion,
          reason: 'While the card is in popup the payload really does carry '
              'geometry a pre-#1299 build has no rule for.');

      await pick(container, 'device_info', CardDensity.normal);

      expect(jsonDecode(await storedRaw())['version'],
          UspLayoutEnvelope.versionWithoutForms,
          reason: 'Back in normal the card carries the spec bounds and its '
              'handles, so a pre-#1299 build reads these bytes correctly. A '
              'rejection here would reset the dashboard the user arranged '
              'because they once tried a form and undid it.');

      // Stamped v2, but the pick is still on the item for this build: an older
      // build ignores an `extra` key it has no field for, and this one needs it
      // to keep honouring an explicit normal.
      expect(
          (await storedPick(12, 'device_info'))?.density, CardDensity.normal);
    });
  });
}

/// Two real cards in the shape `exportLayout()` produces — enough for the
/// envelope to be importable without standing in for the default layout.
List<Map<String, dynamic>> _defaultishLayout() => [
      {
        'id': 'stats_panel',
        'x': 0,
        'y': 0,
        'w': 12,
        'h': 1,
        'minW': 6,
        'maxW': 12.0,
        'minH': 1,
        'maxH': 2.0,
      },
      {
        'id': 'device_info',
        'x': 0,
        'y': 1,
        'w': 6,
        'h': 3,
        'minW': 3,
        'maxW': 8.0,
        'minH': 2,
        'maxH': 6.0,
      },
    ];
