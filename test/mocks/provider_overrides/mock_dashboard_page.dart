/// Provider overrides for the two dashboard pages (#1380, wave 4).
///
/// One list for both `usp_dashboard_view` and `usp_sliver_dashboard_view`, because
/// the first is a frame around the second and the only provider it adds is the
/// orchestrator the frame branches on. Two cases, one fixture, and no chance of the
/// wrapper being measured against different data than the page it wraps.
///
/// **What is deliberately left real.** Almost everything: the widget factory, the
/// layout controller, the edit-mode notifier, `packageWidgetLoaderProvider`. The point
/// of the case is that the cards it reaches are really built, by the real factory, at
/// the width the real grid really gives them. A stub factory would make it cheap and
/// would measure nothing — `test/golden_test/golden_framework/mocks/mock_dashboard.dart`
/// has one, and it is the right choice there and the wrong one here.
///
/// "The cards it reaches" is a smaller set than the layout's, and the fixture cannot
/// change that: `SliverDashboard` is a lazy sliver, so a 1600px `kPageSweepHeight`
/// builds the cards above the fold and no others — measured, **4 of the 19 in
/// `UspWidgetSpecs.all` at 320–905px and 7 at 1080px and up** (8 and 11 `AppCard`s; the
/// stats panel builds more than one). Which four is a property of
/// `createDefaultLayout`'s order, not of this file. See [kSliverDashboardPageCase] for
/// what that leaves unmeasured and why it is still worth 234 cells.
///
/// `packageWidgetLoaderProvider` is real and still touches no network: it awaits
/// `appsCapabilityProvider`, which [commonOverrides] (through [kitchenSinkOverrides])
/// pins to false, so it returns `const {}` on the first frame and starts no 30-second
/// poll. That is a fixture by argument rather than by override, and if the gate has to
/// stub it later the reason will be that the capability override moved.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/dashboard/kitchen_sink_overrides.dart';

/// An orchestrator that is already done, and did nothing to get there.
///
/// The real `build()` runs an auth check, opens SSE and fires every domain provider;
/// left alone in a widget test it lands in `AsyncError` and `usp_dashboard_view` shows
/// [ServiceErrorView] for all 234 cells — green, and a measurement of the error page.
/// `refreshAll` is overridden as well because the header's refresh action is wired to
/// it and a cell that somehow taps it should be inert rather than reaching a service.
class SettledDashboardOrchestrator extends DashboardOrchestrator {
  @override
  Future<DashboardOrchestratorState> build() async =>
      const DashboardOrchestratorState(isAuthenticated: true);

  @override
  Future<void> refreshAll() async {}
}

/// Overrides for `usp_dashboard_view` and `usp_sliver_dashboard_view`.
///
/// Seeds `SharedPreferences` as a side effect before returning the list, which is not
/// how the other fixtures in this directory behave and is worth the exception: the
/// layout controller is real, and the first thing it does is
/// `SharedPreferences.getInstance()`. Unseeded that throws `MissingPluginException`
/// off a platform channel; seeded with **no layout key** it takes the branch this
/// fixture wants — `UspWidgetSpecs.createDefaultLayout()` stands and every cell
/// measures the dashboard a new user is given rather than one a test invented. The
/// controller then persists that default into the same mock store, which is why the
/// seeding has to happen per cell rather than once in a `setUpAll`: `overrides()` is
/// called for every cell, and each call resets the store.
///
/// [pUspPresetDialogSeen] is the one key seeded, and it is seeded **true**, which is
/// the opposite of what "measure what a new user is given" suggests. The page's
/// `initState` posts `_showPresetDialogIfNeeded` (`usp_sliver_dashboard_view.dart:65`),
/// and on an unseeded store that dialog is open in every cell — measured, and
/// measured *instead of* the page under it: the first run of this sweep found
/// `_PresetCard` and an `_OverlayEntryWidget` in the tree at all nine widths. #1380
/// puts dialogs out of scope explicitly, and the modal is not this page's layout, so
/// the flag is set. Sweeping the preset dialog is worth doing and is a case of its
/// own, against `showPresetSelectionDialog` rather than against a page.
List<Override> dashboardPageOverrides() {
  SharedPreferences.setMockInitialValues(
      const <String, Object>{pUspPresetDialogSeen: true});
  return [
    ...kitchenSinkOverrides(),
    dashboardOrchestratorProvider
        .overrideWith(() => SettledDashboardOrchestrator()),
  ];
}
