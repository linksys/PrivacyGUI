/// Provider overrides for `usp_local_network_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `local_network_scene_data.dart` says why a move and not
/// a copy. The class below is unchanged from what the golden suite has been using;
/// the argument to [localNetworkOverrides] became optional so the gate can take the
/// default scene without naming it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';

import '../test_data/scenes/local_network_scene_data.dart';

class FixedLocalNetworkNotifier extends UspLocalNetworkNotifier {
  final LocalNetworkFeatureState _fixedState;

  FixedLocalNetworkNotifier(this._fixedState);

  @override
  LocalNetworkFeatureState build() => _fixedState;

  @override
  Future<(LocalNetworkSettings?, LocalNetworkStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateSetting(
      LocalNetworkUIModel Function(LocalNetworkUIModel) updater) {}
}

/// Overrides for `usp_local_network_view`, defaulting to [gateLocalNetworkState].
List<Override> localNetworkOverrides([LocalNetworkFeatureState? state]) => [
      uspLocalNetworkProvider.overrideWith(
        () => FixedLocalNetworkNotifier(state ?? gateLocalNetworkState),
      ),
    ];
