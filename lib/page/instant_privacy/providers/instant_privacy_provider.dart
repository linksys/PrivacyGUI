import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/util/extensions.dart';

final instantPrivacyProvider =
    NotifierProvider<InstantPrivacyNotifier, InstantPrivacyState>(
        () => InstantPrivacyNotifier());

class InstantPrivacyNotifier extends Notifier<InstantPrivacyState> {
  @override
  InstantPrivacyState build() {
    fetch(fetchRemote: true);
    return InstantPrivacyState.init();
  }

  Future<InstantPrivacyState> fetch({bool fetchRemote = false}) async {
    final settings = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getMACFilterSettings,
          fetchRemote: fetchRemote,
          auth: true,
        )
        .then((result) => MACFilterSettings.fromMap(result.output));
    state = state.copyWith(
      mode: MacFilterMode.reslove(settings.macFilterMode),
      macAddresses: settings.macAddresses.map((e) => e.toUpperCase()).toList(),
      maxMacAddresses: settings.maxMACAddresses,
    );
    return state;
  }

  Future doPolling() {
    return ref.read(pollingProvider.notifier).forcePolling();
  }

  Future save() async {
    var macAddresses = [];
    if (state.mode == MacFilterMode.allow) {
      final List<String> staBSSIDS = await ref
          .read(routerRepositoryProvider)
          .send(
            JNAPAction.getSTABSSIDs,
            fetchRemote: true,
            auth: true,
          )
          .then((result) {
        return List<String>.from(result.output['staBSSIDS']);
      }).onError((error, _) {
        logger.d('Not able to get STA BSSIDs');
        return [];
      });
      final nodesMacAddresses = ref
          .read(deviceManagerProvider)
          .nodeDevices
          .map((e) => e.getMacAddress().toUpperCase())
          .toList();
      macAddresses = [
        ...state.macAddresses,
        ...nodesMacAddresses,
        ...staBSSIDS,
      ].unique();
    }
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setMACFilterSettings,
          data: {
            'macFilterMode': state.mode.name.capitalize(),
            'macAddresses': macAddresses,
          },
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
    await fetch(fetchRemote: true);
  }

  setEnable(bool isEnabled) {
    state = state.copyWith(
        mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled);
  }

  setAccess(String value) {
    final status =
        MacFilterMode.values.firstWhereOrNull((e) => e.name == value);
    if (status != null) {
      state = state.copyWith(mode: status);
    }
  }

  setSelection(List<String> selections) {
    selections = selections.map((e) => e.toUpperCase()).toList();
    final List<String> unique = List.from(state.macAddresses)
      ..addAll(selections)
      ..unique();
    state = state.copyWith(macAddresses: unique);
  }

  removeSelection(List<String> selection) {
    selection = selection.map((e) => e.toUpperCase()).toList();
    final list = List<String>.from(state.macAddresses)
      ..removeWhere((element) => selection.contains(element));
    state = state.copyWith(macAddresses: list);
  }

  setMacAddressList(List<String> macAddressList) {
    macAddressList = macAddressList.map((e) => e.toUpperCase()).toList();
    state = state.copyWith(macAddresses: macAddressList);
  }
}
