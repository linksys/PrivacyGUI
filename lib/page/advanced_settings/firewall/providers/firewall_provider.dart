import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart' as model;
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final firewallProvider =
    NotifierProvider<FirewallNotifier, FirewallState>(() => FirewallNotifier());

class FirewallNotifier extends Notifier<FirewallState>
    with PreservableNotifierMixin<FirewallSettings, FirewallStatus, FirewallState> {
  @override
  FirewallState build() {
    return const FirewallState(
      settings: FirewallSettings(
        settings: model.FirewallSettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        ),
      ),
      status: FirewallStatus(),
    );
  }

  @override
  Future<void> performFetch() async {
    final value = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getFirewallSettings, auth: true);
    final settings = model.FirewallSettings.fromMap(value.output);
    state = state.copyWith(
      settings: state.settings.copyWith(settings: settings),
    );
  }

  @override
  Future<void> performSave() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setFirewallSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: state.settings.settings.toMap(),
        );
  }

  void setSettings(model.FirewallSettings settings) {
    state = state.copyWith(
      settings: state.settings.copyWith(settings: settings),
    );
  }
}

final preservableFirewallProvider =
    Provider.autoDispose<PreservableContract<FirewallSettings, FirewallStatus>>(
        (ref) {
  return ref.watch(firewallProvider.notifier);
});
