// #1497 (phase 7 of epic #1474), folded in 2026-09-08: a dashboard layout that
// is not the viewer's.
//
// THE DECISION GUARDED. That `SurfaceStrategy.fixedDashboardLayout()` decides
// *both* halves of "this layout is nobody's preference" — which grid the
// dashboard starts on, and that neither the layout nor the widget preferences are
// read from or written to storage — and that it decides them for the two
// providers together.
//
// One member, two consumers, on purpose. `usp_layout_controller.dart` owns the
// grid and `usp_layout_preferences_provider.dart` owns the visibility/preset
// preferences, and until this change each asked `GlobalConfig.remote.forcedPreset`
// for itself: one decision spelled twice, which is the shape that comes apart the
// day only one of them is edited. The tests are therefore paired — a stored value
// planted once, read back under each profile — so a fix applied to one consumer
// and not the other cannot be green.
//
// WHY THESE TWO SITES HAD NO COVERAGE AT ALL. Both reads resolved through a
// build-time global (`GlobalConfig.remote.isActive` -> `BuildConfig.isRemote()`),
// and falsification criterion 2 of #1474 forbids a test that assigns
// `BuildConfig.forceCommandType`. There was no lever, so there was no test, for
// either behaviour — which is the whole argument for cause 5 rather than a flag.
// Every case below selects its mode with one
// `appModeProfileProvider.overrideWithValue(...)` and nothing else.
//
// THE FIXTURE IS WRITTEN BY THE APP, not by hand. `plantStoredLayout` boots a
// local container, applies a preset through the notifier and disposes it, leaving
// a real complete envelope in the mock pref store. A hand-built payload would be
// this test's own idea of the format, and the assertion "remote ignored what was
// stored" is only worth as much as the proof that the stored thing was loadable —
// which the local control case is.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The two profiles, named so a failure message says which surface was wrong.
  const local = LocalModeProfile();
  const remote = RemoteModeProfile();

  /// Wait for the notifier's async init/save chains to settle.
  Future<void> pumpAsync() => Future.delayed(const Duration(milliseconds: 100));

  ProviderContainer container(AppModeProfile profile) => ProviderContainer(
        overrides: [appModeProfileProvider.overrideWithValue(profile)],
      );

  /// Boots the layout controller under [profile] against whatever the mock pref
  /// store already holds.
  Future<ProviderContainer> bootGrid(AppModeProfile profile) async {
    final c = container(profile);
    c.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return c;
  }

  /// Leaves a complete, app-written envelope for the 6-card `essential` preset in
  /// the pref store — distinguishable from both the 18-card default and the
  /// 8-card remote layout, so a failure says which of the three arrived.
  Future<void> plantStoredLayout() async {
    final seed = await bootGrid(local);
    await seed
        .read(uspSliverDashboardControllerProvider.notifier)
        .applyPreset(UspDashboardPreset.essential);
    await pumpAsync();
    seed.dispose();
  }

  List<String> cardIdsOf(ProviderContainer c) => c
      .read(uspSliverDashboardControllerProvider)
      .exportLayout()
      .map((item) => item['id'] as String)
      .toList()
    ..sort();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ---------------------------------------------------------------------------
  // Which grid the surface starts on
  // ---------------------------------------------------------------------------
  group('the grid a surface starts on', () {
    test('remote renders its fixed layout over a stored one', () async {
      await plantStoredLayout();

      final c = await bootGrid(remote);
      addTearDown(c.dispose);

      expect(
        cardIdsOf(c),
        UspDashboardPreset.remote.cardIds.toList()..sort(),
        reason: 'a support session got the router owner\'s arranged dashboard. '
            'The layout is not the agent\'s to inherit or to keep: '
            'SurfaceStrategy.fixedDashboardLayout() is what this grid comes '
            'from in that mode, and the pref is not consulted.',
      );
    });

    test('local renders the stored one — the control', () async {
      await plantStoredLayout();

      final c = await bootGrid(local);
      addTearDown(c.dispose);

      expect(
        cardIdsOf(c),
        UspDashboardPreset.essential.cardIds.toList()..sort(),
        reason: 'the planted envelope did not load, so the remote case above '
            'proves nothing: "remote ignored the stored layout" needs the '
            'stored layout to have been loadable in the first place.',
      );
    });

    test('remote stores nothing on a first boot', () async {
      final c = await bootGrid(remote);
      addTearDown(c.dispose);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(pUspSliverDashboardLayout),
        isNull,
        reason: 'a support session wrote a dashboard layout into the agent\'s '
            'browser. Nothing in that session is the agent\'s preference, and '
            'the fixed layout is rebuilt from the surface every boot — so there '
            'is nothing a write could be for.',
      );

      // The control is inside this test, not beside it, and that is the fix for a
      // flake review found: `pumpAsync` is a wall clock, the write it must not see
      // goes through an async queue, and an undrained write is indistinguishable
      // from no write. A starved runner therefore flaked this test *green*. Booting
      // local against the same store, in the same test, on the same budget makes
      // a too-short wait fail here rather than pass.
      final control = await bootGrid(local);
      addTearDown(control.dispose);
      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspSliverDashboardLayout),
        isNotNull,
        reason: 'the wait was long enough for local to persist but the remote '
            'assertion above still saw nothing — so it saw nothing because the '
            'surface is fixed, not because the write had not landed yet.',
      );
    });

    test('remote persists nothing a mutation asks it to either', () async {
      final c = await bootGrid(remote);
      addTearDown(c.dispose);

      // `updateItemSize` rather than a drag, because it is one of the five
      // mutators that call `saveLayout()` **directly** rather than through the
      // auto-persist hook — which is why the guard is in `saveLayout` and why
      // suppressing the hook would have looked like a fix and left five holes.
      await c
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 12, 4);
      await pumpAsync();

      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspSliverDashboardLayout),
        isNull,
        reason: 'first boot writing nothing is the weaker half: the layout is '
            'not this viewer\'s at any point in the session, so a mutation must '
            'not create the pref either. Reachable only from edit mode today, '
            'which `layoutEditor()` closes — a promise resting on a different '
            'member is one an unrelated edit can break.',
      );
    });

    test('local persists the same mutation — the control', () async {
      final c = await bootGrid(local);
      addTearDown(c.dispose);

      final before = (await SharedPreferences.getInstance())
          .getString(pUspSliverDashboardLayout);

      await c
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 12, 4);
      await pumpAsync();

      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspSliverDashboardLayout),
        isNot(before),
        reason: 'the mutation does not reach storage in either mode, so the '
            'remote assertion above is vacuous — check that `device_info` is '
            'still in the default layout and that 12x4 is a legal size for it.',
      );
    });

    // The next two close the residual review flagged and Austin then asked for:
    // `resetLayout()` and `applyPreset()` swap the controller *before* they reach
    // `saveLayout()`, so the write guard leaves the pref clean while the grid in
    // front of the viewer is replaced anyway. Both are reachable only from edit
    // mode today — which is exactly the "promise resting on a different member"
    // shape, and the same reason the mutation test above exists.
    test('remote refuses a reset to the default layout', () async {
      final c = await bootGrid(remote);
      addTearDown(c.dispose);

      await c.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
      await pumpAsync();

      expect(
        cardIdsOf(c),
        UspDashboardPreset.remote.cardIds.toList()..sort(),
        reason:
            'a support session was handed the 18-card default grid. "Back to '
            'the default" is not a place a viewer whose layout was chosen for '
            'them can be returned to — the fixed layout is the only one this '
            'surface has.',
      );
    });

    test('local resets to the default — the control', () async {
      await plantStoredLayout();

      final c = await bootGrid(local);
      addTearDown(c.dispose);
      expect(
          cardIdsOf(c), UspDashboardPreset.essential.cardIds.toList()..sort());

      await c.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
      await pumpAsync();

      expect(
        cardIdsOf(c),
        isNot(UspDashboardPreset.essential.cardIds.toList()..sort()),
        reason:
            'resetLayout() no longer changes the grid in either mode, so the '
            'remote assertion above passes for the wrong reason.',
      );
    });

    test('remote refuses a preset applied over its layout', () async {
      final c = await bootGrid(remote);
      addTearDown(c.dispose);

      await c
          .read(uspSliverDashboardControllerProvider.notifier)
          .applyPreset(UspDashboardPreset.essential);
      await pumpAsync();

      expect(
        cardIdsOf(c),
        UspDashboardPreset.remote.cardIds.toList()..sort(),
        reason: 'a preset replaced the fixed layout. This is the guard that '
            'would have been silently wrong on its own: applyPreset() ends in '
            'saveLayout(), which refuses — so the pref stays clean and only the '
            'screen is wrong.',
      );

      final control = await bootGrid(local);
      addTearDown(control.dispose);
      await control
          .read(uspSliverDashboardControllerProvider.notifier)
          .applyPreset(UspDashboardPreset.essential);
      await pumpAsync();
      expect(
        cardIdsOf(control),
        UspDashboardPreset.essential.cardIds.toList()..sort(),
        reason:
            'applyPreset() is a no-op in both modes, so the assertion above '
            'is vacuous.',
      );
    });

    test('local stores its default on a first boot — the control', () async {
      final c = await bootGrid(local);
      addTearDown(c.dispose);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(pUspSliverDashboardLayout),
        isNotNull,
        reason: 'the first-boot write is gone, which would make the remote '
            'assertion above vacuous — it would pass in a build that persists '
            'nothing anywhere.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Which preferences the surface reads
  // ---------------------------------------------------------------------------
  group('the layout preferences a surface reads', () {
    /// Stored preferences that differ from the defaults in all **four** of
    /// `UspLayoutPreferences`' Equatable props, so a partial read cannot pass.
    ///
    /// `widgetConfigs` was the one left at its default, and review was right that
    /// it was the wrong one to omit: it is the only non-scalar field, so the only
    /// one whose JSON round-trip can realistically break, and it is also the
    /// field the leak this group is named after consists of — the agent's own
    /// hidden cards. With `{}` on both sides, a remote skip that loaded
    /// `widgetConfigs` and nothing else was green.
    final stored = UspLayoutPreferences(
      useCustomLayout: false,
      widgetConfigs: const {
        'device_info': GridWidgetConfig(
          widgetId: 'device_info',
          order: 0,
          visible: false,
        ),
      },
      selectedPreset: UspDashboardPreset.standard,
      hasSeenPresetDialog: true,
    );

    /// Reads the preferences under [profile].
    ///
    /// Deliberately does **not** boot the grid controller: `build()` touches only
    /// `surfaceStrategyProvider` and the pref store. The earlier version did, copied
    /// from [bootGrid], which under local also fired a layout write this group never
    /// asserts on — a race added for nothing.
    Future<UspLayoutPreferences> read(AppModeProfile profile) async {
      final c = container(profile);
      addTearDown(c.dispose);
      await c.read(uspLayoutPreferencesProvider.notifier).initialized;
      await pumpAsync();
      return c.read(uspLayoutPreferencesProvider);
    }

    test('remote reads none of them', () async {
      SharedPreferences.setMockInitialValues({
        pUspLayoutPreferences: stored.toJsonString(),
      });

      expect(
        await read(remote),
        const UspLayoutPreferences(),
        reason: 'the agent\'s own hidden cards, custom-layout toggle and '
            '"already asked" flag leaked into a support session. A surface with '
            'a fixed layout has no preferences to load — which is the same '
            'member as the grid above, and the reason it is one member and not '
            'two.',
      );
    });

    test('remote leaves selectedPreset null, not `remote`', () async {
      // Planted, even though the claim is about the *seed* rather than the load:
      // with an empty store this passed against a mutant that removed the skip
      // entirely, because there was nothing to load and `null` is also the
      // default. A stored `standard` makes `null` the answer to both questions.
      SharedPreferences.setMockInitialValues({
        pUspLayoutPreferences: stored.toJsonString(),
      });

      expect(
        (await read(remote)).selectedPreset,
        isNull,
        reason: 'deliberate, and the one behaviour change here: the field used '
            'to be seeded with UspDashboardPreset.remote by a mode read. '
            'Nobody picked it, and its only reader — the edit-mode-only '
            'settings panel — is a surface this mode cannot open. If a second '
            'reader appears, this is the assertion that has to be revisited '
            'rather than deleted.',
      );
    });

    test('local reads all of them — the control', () async {
      SharedPreferences.setMockInitialValues({
        pUspLayoutPreferences: stored.toJsonString(),
      });

      expect(
        await read(local),
        stored,
        reason: 'the planted preferences did not load at all, so the remote '
            'case above is vacuous.',
      );
    });

    // The write half of this group, found while closing the grid's: the read was
    // guarded in `build()` and none of the six mutators was, so the same "nothing
    // is read and nothing is written" claim was true of the grid and only half
    // true here. `setVisibility` stands for all five that go through
    // `_saveToPrefs`; `resetToDefaults` writes directly and is guarded at its own
    // head.
    test('remote writes none of them either', () async {
      final c = container(remote);
      addTearDown(c.dispose);
      await c.read(uspLayoutPreferencesProvider.notifier).initialized;

      await c
          .read(uspLayoutPreferencesProvider.notifier)
          .setVisibility('device_info', false);
      await pumpAsync();

      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspLayoutPreferences),
        isNull,
        reason: 'a support session left its hidden cards in the agent\'s '
            'browser, where the next session — a different customer\'s router — '
            'would read them. In-memory state changing is fine and deliberate; '
            'outliving the session is not.',
      );

      final control = container(local);
      addTearDown(control.dispose);
      await control.read(uspLayoutPreferencesProvider.notifier).initialized;
      await control
          .read(uspLayoutPreferencesProvider.notifier)
          .setVisibility('device_info', false);
      await pumpAsync();
      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspLayoutPreferences),
        isNotNull,
        reason: 'setVisibility() does not persist in either mode, so the '
            'assertion above is vacuous.',
      );
    });

    test('remote does not delete them either', () async {
      // The sixth mutator, and the only one that reaches storage without going
      // through `_saveToPrefs`. Planted first on purpose: with an empty store a
      // removal is indistinguishable from a no-op, which is the same vacuity
      // mutant 3 of the fold-in found in `'remote leaves selectedPreset null'`.
      SharedPreferences.setMockInitialValues({
        pUspLayoutPreferences: stored.toJsonString(),
      });

      final c = container(remote);
      addTearDown(c.dispose);
      await c.read(uspLayoutPreferencesProvider.notifier).initialized;

      await c.read(uspLayoutPreferencesProvider.notifier).resetToDefaults();
      await pumpAsync();

      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspLayoutPreferences),
        stored.toJsonString(),
        reason: 'a support session deleted preferences it had refused to read. '
            '"Not the viewer\'s" cuts both ways: a fixed surface has no standing '
            'to reset a store it is not looking at, and whoever left that '
            'payload there is the one who gets to clear it.',
      );

      final control = container(local);
      addTearDown(control.dispose);
      await control.read(uspLayoutPreferencesProvider.notifier).initialized;
      await control
          .read(uspLayoutPreferencesProvider.notifier)
          .resetToDefaults();
      await pumpAsync();
      expect(
        (await SharedPreferences.getInstance())
            .getString(pUspLayoutPreferences),
        isNull,
        reason: 'resetToDefaults() clears nothing in either mode, so the '
            'assertion above is vacuous.',
      );
    });
  });
}
