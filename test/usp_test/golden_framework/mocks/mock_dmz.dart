import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';

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

/// Returns provider overrides for DMZ golden tests.
List<Override> dmzOverrides(DmzFeatureState state) => [
      uspDmzProvider.overrideWith(() => FixedDmzNotifier(state)),
    ];
