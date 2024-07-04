import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';

final firewallProvider =
    NotifierProvider<FirewallNotifier, FirewallState>(() => FirewallNotifier());

class FirewallNotifier extends Notifier<FirewallState> {
  @override
  FirewallState build() => const FirewallState(
          settings: FirewallSettings(
        blockAnonymousRequests: false,
        blockIDENT: false,
        blockIPSec: false,
        blockL2TP: false,
        blockMulticast: false,
        blockNATRedirection: false,
        blockPPTP: false,
        isIPv4FirewallEnabled: false,
        isIPv6FirewallEnabled: false,
      ));

  Future<FirewallState> fetch([bool force = false]) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getFirewallSettings, auth: true, fetchRemote: force)
        .then((value) {
      final settings = FirewallSettings.fromMap(value.output);
      state = state.copyWith(settings: settings);
      return state;
    });
  }

  Future<FirewallState> save() {
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setFirewallSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: state.settings.toMap(),
        )
        .then((_) => fetch(true));
  }

  setSettings(FirewallSettings settings) {
    state = state.copyWith(settings: settings);
  }
}
