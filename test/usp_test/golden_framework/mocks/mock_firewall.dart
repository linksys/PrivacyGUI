import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';

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

/// Returns provider overrides for firewall golden tests.
List<Override> firewallOverrides(FirewallFeatureState state) => [
      uspFirewallProvider.overrideWith(() => FixedFirewallNotifier(state)),
    ];
