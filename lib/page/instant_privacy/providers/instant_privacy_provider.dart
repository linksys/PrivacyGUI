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

class InstantPrivacyNotifier extends Notifier<InstantPrivacyState>
    with
        PreservableNotifierMixin<InstantPrivacySettings, InstantPrivacyStatus,
            InstantPrivacyState> {
  @override
  InstantPrivacyState build() {
    return InstantPrivacyState.init();
  }

  @override
  Future<void> performFetch({bool statusOnly = false}) async {
    final settings = await ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.getMACFilterSettings,
          auth: true,
        )
        .then((result) => MACFilterSettings.fromMap(result.output));

    if (statusOnly) {
      state = state.copyWith(
        status: InstantPrivacyStatus(
            mode: MacFilterMode.reslove(settings.macFilterMode)),
      );
      return;
    }
    final List<String> staBSSIDS = serviceHelper.isSupportGetSTABSSID()
        ? await ref
            .read(routerRepositoryProvider)
            .send(
              JNAPAction.getSTABSSIDs,
              auth: true,
            )
            .then((result) {
            return List<String>.from(result.output['staBSSIDS']);
          }).catchError((error, _) {
            logger.d('Not able to get STA BSSIDs');
            return [];
          })
        : [];

    final myMac = await getMyMACAddress();
    final mode = MacFilterMode.reslove(settings.macFilterMode);
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
    final InstantPrivacyStatus newStatus = InstantPrivacyStatus(
      mode: mode,
    );
    state = state.copyWith(
      settings: newSettings,
      status: newStatus,
    );
    logger.d('[State]:[instantPrivacy]: ${state.toJson()}');
  }

  @override
  Future<void> performSave() async {
    var macAddresses = <String>[];
    if (state.settings.mode == MacFilterMode.allow) {
      final nodesMacAddresses = ref
          .read(deviceManagerProvider)
          .nodeDevices
          .map((e) => e.getMacAddress().toUpperCase())
          .toList();
      macAddresses = [
        ...state.settings.macAddresses,
        ...nodesMacAddresses,
        ...state.settings.bssids,
      ].unique();
    } else if (state.settings.mode == MacFilterMode.deny) {
      macAddresses = [
        ...state.settings.macAddresses,
      ];
    }
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setMACFilterSettings,
          data: {
            'macFilterMode': state.settings.mode.name.capitalize(),
            'macAddresses': macAddresses,
          },
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );
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
    }).catchError((_, __) {
      return null;
    });
  }

  void setEnable(bool isEnabled) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled));
  }

  void setAccess(MacFilterMode value) {
    state = state.copyWith(settings: state.settings.copyWith(mode: value));
  }

  void setSelection(List<String> selections, [bool isDeny = false]) {
    selections = selections.map((e) => e.toUpperCase()).toList();
    final List<String> unique = List.from(
        isDeny ? state.settings.denyMacAddresses : state.settings.macAddresses)
      ..addAll(selections)
      ..unique();
    state = state.copyWith(
      settings: state.settings.copyWith(
        macAddresses: isDeny ? [] : unique,
        denyMacAddresses: isDeny ? unique : [],
      ),
    );
  }

  void removeSelection(List<String> selection, [bool isDeny = false]) {
    selection = selection.map((e) => e.toUpperCase()).toList();
    final list = List<String>.from(
        isDeny ? state.settings.denyMacAddresses : state.settings.macAddresses)
      ..removeWhere((element) => selection.contains(element));
    state = state.copyWith(
      settings: state.settings.copyWith(
        macAddresses: isDeny ? null : list,
        denyMacAddresses: isDeny ? list : null,
      ),
    );
  }

  void setMacAddressList(List<String> macAddressList) {
    macAddressList = macAddressList.map((e) => e.toUpperCase()).toList();
    state = state.copyWith(
        settings: state.settings.copyWith(macAddresses: macAddressList));
  }
}

final preservableInstantPrivacyProvider = Provider.autoDispose<
    PreservableContract<InstantPrivacySettings, InstantPrivacyStatus>>((ref) {
  return ref.watch(instantPrivacyProvider.notifier);
});
