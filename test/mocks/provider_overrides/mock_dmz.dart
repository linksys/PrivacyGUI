/// Provider overrides for `usp_dmz_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — see `dmz_scene_data.dart` for why the move rather
/// than a copy. The class below is unchanged from what the golden suite has been
/// using; only its address is new.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';

import '../test_data/devices_test_data.dart';
import '../test_data/scenes/dmz_scene_data.dart';
import 'mock_devices.dart' show FixedDevicesDataNotifier;

/// A `uspDmzProvider` pinned to one state.
///
/// Every mutating path is stubbed, and `updateSetting` in particular: the page
/// writes through it on every keystroke and on the switch, so a live one would let
/// a cell's own layout pass change the state it is measuring.
class FixedDmzNotifier extends UspDmzNotifier {
  final DmzFeatureState _fixedState;

  FixedDmzNotifier(this._fixedState);

  @override
  DmzFeatureState build() => _fixedState;

  @override
  Future<(DmzSettings?, DmzStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateSetting(DmzUIModel Function(DmzUIModel) updater) {}
}

/// Overrides for `usp_dmz_view`, defaulting to [gateDmzState].
///
/// The state stays a parameter because the golden suite passes several of
/// them; the default is what the gate sweeps. `devicesDataProvider` is
/// overridden because the destination card watches it for its suggestions
/// (#1775), on the page's own build path.
List<Override> dmzOverrides([DmzFeatureState? state, DevicesData? devices]) => [
      uspDmzProvider
          .overrideWith(() => FixedDmzNotifier(state ?? gateDmzState)),
      // No LAN devices by default: the suggestions open only as the user
      // types, so no cell renders them.
      devicesDataProvider.overrideWith(() => FixedDevicesDataNotifier(devices ??
          DevicesTestData.createDevicesData(
              meshNetwork: DevicesTestData.createEmptyNetwork()))),
    ];
