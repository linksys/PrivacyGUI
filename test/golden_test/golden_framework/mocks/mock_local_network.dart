import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';

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

/// Returns provider overrides for local network golden tests.
List<Override> localNetworkOverrides(LocalNetworkFeatureState state) => [
      uspLocalNetworkProvider
          .overrideWith(() => FixedLocalNetworkNotifier(state)),
    ];
