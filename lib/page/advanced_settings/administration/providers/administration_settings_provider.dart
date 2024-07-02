import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

import 'administration_settings_state.dart';

final administrationSettingsProvider =
    NotifierProvider<AdministrationSettingsNotifier, AdministrationSettingsState>(
        () => AdministrationSettingsNotifier());

class AdministrationSettingsNotifier extends Notifier<AdministrationSettingsState> {
  @override
  AdministrationSettingsState build() => const AdministrationSettingsState(
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

  Future<AdministrationSettingsState> fetch([bool force = false]) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getFirewallSettings, auth: true, fetchRemote: force)
        .then((value) {
      final settings = FirewallSettings.fromMap(value.output);
      state = state.copyWith(settings: settings);
      return state;
    });
  }

  Future<AdministrationSettingsState> save() {
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
