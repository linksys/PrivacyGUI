import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
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
        PreservableNotifierMixin<FirewallSettings, EmptyStatus, FirewallState> {
  @override
  FirewallState build() {
    const settings = FirewallSettings(
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
  Future<(FirewallSettings?, EmptyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final result = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getFirewallSettings, auth: true, fetchRemote: forceRemote);
    final settings = FirewallSettings.fromMap(result.output);
    return (settings, const EmptyStatus());
  }

  @override
  Future<void> performSave() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setFirewallSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: state.settings.current.toMap(),
        );
  }

  setSettings(FirewallSettings settings) {
    state = state.copyWith(
      settings: state.settings.copyWith(current: settings),
    );
  }
}
