import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/firewall_settings_service.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final firewallProvider =
    NotifierProvider<FirewallNotifier, FirewallState>(() => FirewallNotifier());

final preservableFirewallProvider = Provider<PreservableContract>(
  (ref) => ref.watch(firewallProvider.notifier),
);

class FirewallNotifier extends Notifier<FirewallState>
    with
        PreservableNotifierMixin<FirewallUISettings, EmptyStatus,
            FirewallState> {
  @override
  FirewallState build() {
    const settings = FirewallUISettings(
      blockAnonymousRequests: false,
      blockIDENT: false,
      blockIPSec: false,
      blockL2TP: false,
      blockMulticast: false,
      blockNATRedirection: false,
      blockPPTP: false,
      isIPv4FirewallEnabled: false,
      isIPv6FirewallEnabled: false,
    );
    return const FirewallState(
      settings: Preservable(original: settings, current: settings),
      status: EmptyStatus(),
    );
  }

  @override
  Future<(FirewallUISettings?, EmptyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(firewallSettingsServiceProvider);
    return await service.fetchFirewallSettings(ref, forceRemote: forceRemote);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(firewallSettingsServiceProvider);
    await service.saveFirewallSettings(ref, state.settings.current);
  }

  setSettings(FirewallUISettings settings) {
    state = state.copyWith(
      settings: state.settings.copyWith(current: settings),
    );
  }
}
