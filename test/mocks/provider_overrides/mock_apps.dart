/// Provider overrides for `usp_apps_view` (#1380, wave 4).
///
/// One provider, and — as with `mock_router_assistant` — the reason it must be
/// overridden rather than fed is a timer. `UspAppsNotifier.build` starts a
/// `Timer.periodic(5s)` that re-fetches `/api/apps.json` and, on any change, spawns
/// a 60-second `Future.delayed` per newly-seen app to clear its `New` badge.
/// Overriding `uspAppsServiceProvider` instead would leave that timer real, so
/// every one of the 234 cells would end with a pending timer the test binding
/// fails on — and the fetch it polls is an `http.Client` call with no handler.
/// Replacing the notifier is what makes a cell one layout with no clock attached.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/apps/providers/usp_apps_notifier.dart';

import '../test_data/scenes/apps_scene_data.dart';

/// A `uspAppsProvider` that resolves to a fixed state and starts no timer.
///
/// `build` is still `async` because the base class declares it so, which means the
/// page renders exactly one `AsyncLoading` frame per cell before the data lands —
/// the same first-frame window `mock_admin` documents. It is why
/// `kAppsPageCase.forbids` cannot be read at settle as proof no loader was ever
/// built, and why the `requires` list carries the premise instead.
class FixedUspAppsNotifier extends UspAppsNotifier {
  FixedUspAppsNotifier(this._state);

  final UspAppsState _state;

  @override
  Future<UspAppsState> build() async => _state;
}

/// Overrides for `usp_apps_view`.
List<Override> appsOverrides({UspAppsState? state}) => [
      uspAppsProvider.overrideWith(
        () => FixedUspAppsNotifier(state ?? gateAppsState),
      ),
    ];
