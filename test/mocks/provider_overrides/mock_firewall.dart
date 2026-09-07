/// Provider overrides for `usp_firewall_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `firewall_scene_data.dart` says why a move and not a
/// copy. The class below is unchanged from what the golden suite has been using.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';

import '../test_data/scenes/firewall_scene_data.dart';

/// A `uspFirewallProvider` pinned to one state, with every mutating path stubbed.
class FixedFirewallNotifier extends UspFirewallNotifier {
  final FirewallFeatureState _fixedState;

  FixedFirewallNotifier(this._fixedState);

  @override
  FirewallFeatureState build() => _fixedState;

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {}
}

/// Overrides for `usp_firewall_view`, defaulting to [gateFirewallState].
List<Override> firewallOverrides([FirewallFeatureState? state]) => [
      uspFirewallProvider.overrideWith(
          () => FixedFirewallNotifier(state ?? gateFirewallState)),
    ];
