/// The one way the dashboard *provider* tests boot a container.
///
/// The container-level sibling of `test/util/dashboard_page_harness.dart`, which
/// does the same job for the three files that pump the real page. This one
/// serves the six files under `test/page/dashboard/providers/` that drive the
/// layout controller with no widget tree at all.
///
/// Hoisted out of six near-copies that had drifted into three spellings of the
/// same helper — `createContainer` (edit_mode, preferences, selection),
/// `boot`/`reboot` (card_form, breakpoint_persistence) and
/// `createInitializedContainer` (controller) — plus six copies of the 100ms
/// delay, five named `pumpAsync` and one inlined in selection's boot.
///
/// They were not byte-identical, and that is the reason to unify them: the
/// differences between them were *behavioural*, and with each file spelling its
/// own boot there was no way to see that from a call site. Below they are named
/// parameters, so a test states which it needs and the two that matter carry the
/// measurement that says so.
///
/// #1310's own scope statement also named a seventh file,
/// `usp_layout_fixed_surface_test.dart`, and its `cardIdsOf` helper. That file is
/// not in this branch's tree — it arrives with `feat/1474-mode-strategies`
/// (`848de24a`), so its boot and its `exportLayout()` read are for whoever merges
/// the two, not for this issue.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the notifier's async init and save chains run to completion.
///
/// A wall-clock delay rather than `pumpAndSettle`: these tests have no
/// `WidgetTester` and no frames to pump, and the chains being waited on are
/// `SharedPreferences.getInstance()` and the debounced save behind it — real
/// async work off the platform channel, not a Flutter animation.
Future<void> pumpAsync() => Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

/// A container holding the real layout controller, booted and settled.
///
/// The controller is `read` rather than merely overridden, because construction
/// is what starts `_initializeLayout` — a container that never reads it holds an
/// empty grid, which is why every one of the six files did this.
///
/// [initialValues] seeds the mock pref store. The distinction between passing
/// `const {}` and passing nothing is load-bearing and is the whole difference
/// between a fresh install and a reboot: `setMockInitialValues` *replaces* the
/// store, so seeding it on a second boot wipes what the first boot persisted.
/// Omit it to boot against whatever is already there — see [rebootLayout].
///
/// [awaitPreferences] additionally creates `uspLayoutPreferencesProvider` and
/// waits for its load. It is not just a timing flag: `usp_layout_controller.dart`
/// never reads that provider, so passing `true` changes which providers exist in
/// the container, not only when the boot returns. Tests that only touch the grid
/// should leave it off rather than pay for a provider they never read.
///
/// Load-bearing, but in exactly one of the three files that pass it — measured by
/// flipping it to `false` in each:
///
/// | file | killed |
/// |------|--------|
/// | preferences | 1 — `loads saved prefs from SharedPreferences` |
/// | edit_mode | 0 — `enterEditMode` awaits the same completer itself |
/// | selection | 0 — the mirror does not read a preference |
///
/// The two zeroes are kept anyway: they are what those files booted before this
/// harness existed, and dropping the flag there would be a behaviour change
/// smuggled into a refactor. The one kill is why the parameter exists at all —
/// without the await, `build()` returns the default `UspLayoutPreferences()` and
/// `_loadFromPrefs` replaces it a microtask later, so a test that reads the
/// provider straight after the boot sees the default instead of what was stored.
///
/// [overrides] are applied to the container as given.
Future<ProviderContainer> bootLayout({
  Map<String, Object>? initialValues,
  bool awaitPreferences = false,
  List<Override> overrides = const [],
}) async {
  if (initialValues != null) {
    SharedPreferences.setMockInitialValues(initialValues);
  }
  final container = ProviderContainer(overrides: overrides);
  container.read(uspSliverDashboardControllerProvider);
  if (awaitPreferences) {
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
  }
  await pumpAsync();
  return container;
}

/// Boots a second container against the pref store the first one wrote — the
/// "close the tab and come back on a laptop" path.
///
/// Exactly [bootLayout] with [initialValues] omitted; it exists as its own name
/// because that omission is the entire mechanism and reads as an oversight
/// otherwise. Measured: passing `const {}` through instead of omitting it fails
/// 4 tests across the two persistence files — the second boot finds an empty
/// store and seeds a default layout, so nothing the first boot wrote is there to
/// be read back.
Future<ProviderContainer> rebootLayout({
  bool awaitPreferences = false,
  List<Override> overrides = const [],
}) =>
    bootLayout(awaitPreferences: awaitPreferences, overrides: overrides);
