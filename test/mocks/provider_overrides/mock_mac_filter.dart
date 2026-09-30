/// Provider overrides for `mac_filter_view`.
///
/// Same shape as `mock_instant_privacy.dart`: a `uspMacFilterProvider` pinned to
/// one state with every mutating path stubbed, so the golden suite, the layout
/// gate and the view tests can render the page without a live router.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

import '../test_data/scenes/mac_filter_scene_data.dart';

/// A `uspMacFilterProvider` pinned to one state, with every mutating path
/// stubbed to a no-op.
class FixedMacFilterNotifier extends UspMacFilterNotifier {
  final MacFilterState _fixedState;

  FixedMacFilterNotifier(this._fixedState);

  @override
  Future<MacFilterState> build() async => _fixedState;

  @override
  Future<void> setMode(MacFilterMode mode) async {}

  @override
  Future<void> addMac(String mac) async {}

  @override
  Future<void> removeMac(String mac) async {}
}

/// Overrides for `mac_filter_view`, defaulting to [gateMacFilterState].
List<Override> macFilterOverrides([MacFilterState? state]) => [
      uspMacFilterProvider.overrideWith(
        () => FixedMacFilterNotifier(state ?? gateMacFilterState),
      ),
    ];
