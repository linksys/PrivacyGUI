import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The persistence half of #1299: a picked form is stored per breakpoint and the
/// geometry it implies is re-derived on every import.
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
/// ## Why the pick lives in the layout envelope
///
/// `LayoutItem` has a closed field set and `exportLayout()` silently drops
/// anything else, so the pick cannot ride along on the item map. It is a sibling
/// field on [UspLayoutEnvelope], keyed by the same slot counts as the geometry:
/// "compact on a phone, normal on a laptop" is the case this exists for, and a
/// pref that was *not* keyed by breakpoint is exactly the #1293 trap.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_layout_controller.dart`, applied to the real file
/// and run against this file and `card_form_choice_test.dart`; see that file for
/// the `usp_widget_specs.dart` half. Counts are from the run, not predicted.
///
/// |  # | mutation                                          | killed by |
/// |----|---------------------------------------------------|-----------|
/// |  1 | `_normalize` skips `applyCardForms`                | 11 — every geometry assertion here |
/// |  2 | `_seedBreakpoints` drops the desktop pass          | the desktop grid re-derives the geometry a stored pick implies |
/// |  3 | `setCardForm` writes the pick to every breakpoint  | 4, incl. a pick made at desktop leaves the phone grid alone |
/// |  4 | `setCardForm` never records `restoreW`/`restoreH`  | 3 — all three restore tests |
/// |  5 | `setCardForm` rebuilds the choice on re-entry, so popup twice records the tile | picking popup twice still restores the first box |
/// |  6 | `setCardForm` skips the `selectableForms` guard    | popup / compact is refused on a card that has no such form |
/// |  7 | `saveLayout` drops `forms` from the envelope       | the pick reaches the pref; compact on a phone and normal on a laptop |
/// |  8 | `_initializeLayout` ignores the stored forms       | 2 — the read model carries what was loaded; the desktop grid re-derives it |
/// |  9 | `removeWidget` keeps the deleted card's pick       | deleting the card drops its pick |
/// | 10 | `resetLayout` keeps the picks                      | resetLayout clears every pick |
/// | 11 | `_setForms` skips the read-model write             | both read-model tests |
/// | 12 | `UspLayoutEnvelope.version` keys on `forms.isEmpty` | trying popup and changing your mind leaves the stamp at v2 |
///
/// Row 5 was added after the fact: the panel's "re-picking the same form does
/// nothing" guard turned out to be an *equivalent* mutation (see that file's
/// ledger), which is what exposed that the invariant it looked like it was
/// protecting had no test where the invariant actually lives.
///
/// ### One survivor, and why it is left alive
///
/// Swapping the two rules inside `_normalize` — width lock first, forms second —
/// survives, and is supposed to: each rule abstains from the other's axis on the
/// phone grid, so the two orders produce the same layout by construction. A test
/// that pinned the order would be testing an implementation detail we deliberately
/// made irrelevant. What *is* tested is the consequence: popup on a phone keeps
/// the full width and takes only the height.
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
          reason: 'A desktop pick reached the phone geometry. The pick is '
              'stored per slot count precisely so it cannot.');
      expect(
          (await storedEnvelope()).forms.choiceFor(4, 'device_info'), isNull);
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

      final forms = (await storedEnvelope()).forms;
      expect(forms.densityFor(4, 'device_info'), CardDensity.compact);
      expect(forms.densityFor(12, 'device_info'), CardDensity.normal);
    });

    test('the pick reaches the pref, not just the controller', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);

      expect((await storedEnvelope()).forms.densityFor(12, 'device_info'),
          CardDensity.popup,
          reason: 'The geometry was constrained but the reason was not stored, '
              'so the next import would undo it.');
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
      expect(item['isResizable'], isFalse,
          reason: 'The flags are derived from the stored pick on import, so a '
              'reboot is where a derivation that only ran once shows up.');
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
      expect(
          (await storedEnvelope()).forms.choiceFor(12, 'stats_panel'), isNull);
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

      expect((await storedEnvelope()).forms.choiceFor(12, 'topology'), isNull,
          reason: 'Offering compact where no compact form was built would '
              'render the normal form in a box sized for a smaller one.');
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
              'before it was deleted.');
      expect(
          (await storedEnvelope()).forms.choiceFor(12, 'device_info'), isNull);
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
        pUspSliverDashboardLayout: UspLayoutEnvelope(
          {12: _defaultishLayout()},
          forms: const CardForms({
            12: {'device_info': CardFormChoice(density: CardDensity.compact)},
          }),
        ).encode(),
      });
      addTearDown(container.dispose);

      expect(
        container.read(cardFormsProvider).densityFor(12, 'device_info'),
        CardDensity.compact,
        reason: 'CardDensityHost reads the picks from the read model, so a '
            'pick that only reached the notifier renders as no pick at all.',
      );
    });

    test('the desktop grid re-derives the geometry a stored pick implies',
        () async {
      // The pick is stored; the sizes it justifies are not. So a payload whose
      // geometry disagrees with its pick — one written before `popupColumns`
      // changed, or hand-edited — has to be corrected on load, on the desktop
      // grid as much as on the narrow ones. That grid is the one every load path
      // imports first and then seeds the others from, and it used to be the one
      // the normalising walk skipped: harmless while the only rule was mobile-only
      // and identity at 12 columns, wrong the moment a rule applies there.
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope(
          {12: _defaultishLayout()},
          forms: const CardForms({
            12: {'device_info': CardFormChoice(density: CardDensity.popup)},
          }),
        ).encode(),
      });
      addTearDown(container.dispose);

      final item = live(container, 'device_info');
      expect(item['w'], 2);
      expect(item['h'], 1);
      expect(item['isResizable'], isFalse);
    });

    test('the read model follows a pick made after load', () async {
      final container = await boot();
      addTearDown(container.dispose);

      await pick(container, 'device_info', CardDensity.popup, slots: 12);

      expect(container.read(cardFormsProvider).densityFor(12, 'device_info'),
          CardDensity.popup);
    });
  });

  // ---------------------------------------------------------------------------
  // AC 10-adjacent: an install that never touches the control is unchanged
  // ---------------------------------------------------------------------------
  group('the control is invisible until it is used', () {
    test('a dashboard nobody picked a form on writes no forms key', () async {
      final container = await boot();
      addTearDown(container.dispose);

      expect(await storedRaw(), isNot(contains('forms')),
          reason: 'Every existing install must write the bytes it wrote '
              'before #1299, or the first launch after upgrade is a migration.');
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

      // Stamped v2, but the pick is still there for this build.
      expect((await storedEnvelope()).forms.densityFor(12, 'device_info'),
          CardDensity.normal);
    });

    test('a stored pick for a card that is gone is ignored, not an error',
        () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope(
          {12: _defaultishLayout()},
          forms: const CardForms({
            12: {
              'a_card_we_removed': CardFormChoice(density: CardDensity.popup)
            },
          }),
        ).encode(),
      });
      addTearDown(container.dispose);

      expect(
          container.read(uspSliverDashboardControllerProvider).exportLayout(),
          hasLength(2));
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
