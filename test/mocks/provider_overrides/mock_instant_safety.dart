/// Provider overrides for `instant_safety_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `instant_safety_scene_data.dart` says why a move and
/// not a copy. The class below is unchanged from what the golden suite has been
/// using; the argument became optional so the gate can take the default scene
/// without naming it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';

import '../test_data/scenes/instant_safety_scene_data.dart';

/// A `uspInstantSafetyProvider` pinned to one state, with every mutating path
/// stubbed.
class FixedInstantSafetyNotifier extends UspInstantSafetyNotifier {
  final InstantSafetyFeatureState _fixedState;

  FixedInstantSafetyNotifier(this._fixedState);

  @override
  InstantSafetyFeatureState build() => _fixedState;

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void setEnabled(bool enabled) {}
}

/// Overrides for `instant_safety_view`, defaulting to [gateInstantSafetyState].
List<Override> instantSafetyOverrides([InstantSafetyFeatureState? state]) => [
      uspInstantSafetyProvider.overrideWith(
        () => FixedInstantSafetyNotifier(state ?? gateInstantSafetyState),
      ),
    ];
