/// Provider overrides for `mac_filter_view` (save-based).
///
/// A `uspMacFilterProvider` pinned to one state, with `build()` returning it
/// directly (no fetch microtask) and the local mutations left as the real
/// mixin's — but since nothing calls `save()` here, no write happens. Used by
/// the golden suite, the layout gate and the view tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';

import '../test_data/scenes/mac_filter_scene_data.dart';

class FixedMacFilterNotifier extends UspMacFilterNotifier {
  FixedMacFilterNotifier(this._fixedState);

  final MacFilterState _fixedState;

  @override
  MacFilterState build() => _fixedState;
}

/// Overrides for `mac_filter_view`, defaulting to [gateMacFilterState].
List<Override> macFilterOverrides([MacFilterState? state]) => [
      uspMacFilterProvider.overrideWith(
        () => FixedMacFilterNotifier(state ?? gateMacFilterState),
      ),
    ];
