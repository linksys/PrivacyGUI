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
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/util/extensions.dart';

final instantPrivacyProvider =
    NotifierProvider<InstantPrivacyNotifier, InstantPrivacyState>(
        () => InstantPrivacyNotifier());
// The provider now needs to be generic to match the contract.
final preservableInstantPrivacyProvider =
    Provider<PreservableContract<InstantPrivacySettings, InstantPrivacyStatus>>(
        (ref) {
  return ref.watch(instantPrivacyProvider.notifier);
});
class InstantPrivacyNotifier extends Notifier<InstantPrivacyState>
    with PreservableNotifierMixin<InstantPrivacySettings, InstantPrivacyStatus, InstantPrivacyState> {
  @override
  InstantPrivacyState build() {
    // Asynchronously trigger fetch to load actual data
    Future.microtask(() => fetch());
    return InstantPrivacyState.init();
  }

  @override
  Future<(InstantPrivacySettings?, InstantPrivacyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final settings = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getMACFilterSettings,
          fetchRemote: forceRemote,
          auth: true,
        )
        .then((result) => MACFilterSettings.fromMap(result.output));

    final mode = MacFilterMode.reslove(settings.macFilterMode);
    final newStatus = InstantPrivacyStatus(mode: mode);

    // update status only
    if (updateStatusOnly) {
      return (null, newStatus);
    }

    final List<String> staBSSIDS = serviceHelper.isSupportGetSTABSSID()
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
    final macAddresses =
        settings.macAddresses.map((e) => e.toUpperCase()).toList();
    final InstantPrivacySettings newSettings = InstantPrivacySettings(
      mode: mode,
      macAddresses: mode == MacFilterMode.allow ? macAddresses : [],
      denyMacAddresses: mode == MacFilterMode.deny ? macAddresses : [],
      maxMacAddresses: settings.maxMACAddresses,
      bssids: staBSSIDS.map((e) => e.toUpperCase()).toList(),
      myMac: myMac,
    );
    return (newSettings, newStatus);
  }

  @override
  Future<void> performSave() async {
    var macAddresses = <String>[];
    if (state.settings.current.mode == MacFilterMode.allow) {
      final nodesMacAddresses = ref
          .read(deviceManagerProvider)
          .nodeDevices
          .map((e) => e.getMacAddress().toUpperCase())
          .toList();
      macAddresses = [
        ...state.settings.current.macAddresses,
        ...nodesMacAddresses,
        ...state.settings.current.bssids,
      ].unique();
    } else if (state.settings.current.mode == MacFilterMode.deny) {
      macAddresses = [
        ...state.settings.current.macAddresses,
      ];
    }
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setMACFilterSettings,
          data: {
            'macFilterMode': state.settings.current.mode.name.capitalize(),
            'macAddresses': macAddresses,
          },
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
  }

  Future doPolling() {
    return ref.read(pollingProvider.notifier).forcePolling();
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
        settings: state.settings.update(state.settings.current.copyWith(
            mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled)));
  }

  setAccess(MacFilterMode value) {
    state = state.copyWith(settings: state.settings.update(state.settings.current.copyWith(mode: value)));
  }

  setSelection(List<String> selections, [bool isDeny = false]) {
    selections = selections.map((e) => e.toUpperCase()).toList();
    final List<String> unique = List.from(
        isDeny ? state.settings.current.denyMacAddresses : state.settings.current.macAddresses)
      ..addAll(selections)
      ..unique();
    state = state.copyWith(
      settings: state.settings.update(state.settings.current.copyWith(
        macAddresses: isDeny ? [] : unique,
        denyMacAddresses: isDeny ? unique : [],
      )),
    );
  }

  removeSelection(List<String> selection, [bool isDeny = false]) {
    selection = selection.map((e) => e.toUpperCase()).toList();
    final list = List<String>.from(
        isDeny ? state.settings.current.denyMacAddresses : state.settings.current.macAddresses)
      ..removeWhere((element) => selection.contains(element));
    state = state.copyWith(
      settings: state.settings.update(state.settings.current.copyWith(
        macAddresses: isDeny ? null : list,
        denyMacAddresses: isDeny ? list : null,
      )),
    );
  }

  setMacAddressList(List<String> macAddressList) {
    macAddressList = macAddressList.map((e) => e.toUpperCase()).toList();
    state = state.copyWith(
        settings: state.settings.update(state.settings.current.copyWith(macAddresses: macAddressList)));
  }
}
