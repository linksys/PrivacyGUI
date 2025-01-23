import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
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
    final List<String> staBSSIDS = ServiceHelper().isSupportGetSTABSSID()
        ? await ref
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
          })
        : [];

    final myMac = await getMyMACAddress();
    final mode = MacFilterMode.reslove(settings.macFilterMode);
    final macAddresses =
        settings.macAddresses.map((e) => e.toUpperCase()).toList();
    state = state.copyWith(
      mode: mode,
      macAddresses: mode == MacFilterMode.allow ? macAddresses : [],
      denyMacAddresses: mode == MacFilterMode.deny ? macAddresses : [],
      maxMacAddresses: settings.maxMACAddresses,
      bssids: staBSSIDS,
      myMac: myMac,
    );
    logger.d('[State]:[instantPrivacy]: ${state.toJson()}');
    return state;
  }

  Future doPolling() {
    return ref.read(pollingProvider.notifier).forcePolling();
  }

  Future<InstantPrivacyState> save() async {
    var macAddresses = [];
    if (state.mode == MacFilterMode.allow) {
      final nodesMacAddresses = ref
          .read(deviceManagerProvider)
          .nodeDevices
          .map((e) => e.getMacAddress().toUpperCase())
          .toList();
      macAddresses = [
        ...state.macAddresses,
        ...nodesMacAddresses,
        ...state.bssids,
      ].unique();
    } else if (state.mode == MacFilterMode.deny) {
      macAddresses = [
        ...state.macAddresses,
      ];
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
    return fetch(fetchRemote: true);
  }

  Future<String?> getMyMACAddress() {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(JNAPAction.getLocalDevice, auth: true, fetchRemote: true)
        .then((result) {
      final deviceID = result.output['deviceID'];
      return ref
          .read(deviceManagerProvider)
          .deviceList
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    }).onError((_, __) {
      return null;
    });
  }

  setEnable(bool isEnabled) {
    state = state.copyWith(
        mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled);
  }

  setAccess(MacFilterMode value) {
    state = state.copyWith(mode: value);
  }

  setSelection(List<String> selections, [bool isDeny = false]) {
    selections = selections.map((e) => e.toUpperCase()).toList();
    final List<String> unique =
        List.from(isDeny ? state.denyMacAddresses : state.macAddresses)
          ..addAll(selections)
          ..unique();
    state = state.copyWith(
      macAddresses: isDeny ? [] : unique,
      denyMacAddresses: isDeny ? unique : [],
    );
  }

  removeSelection(List<String> selection, [bool isDeny = false]) {
    selection = selection.map((e) => e.toUpperCase()).toList();
    final list =
        List<String>.from(isDeny ? state.denyMacAddresses : state.macAddresses)
          ..removeWhere((element) => selection.contains(element));
    state = state.copyWith(
      macAddresses: isDeny ? null : list,
      denyMacAddresses: isDeny ? list : null,
    );
  }

  setMacAddressList(List<String> macAddressList) {
    macAddressList = macAddressList.map((e) => e.toUpperCase()).toList();
    state = state.copyWith(macAddresses: macAddressList);
  }
}
