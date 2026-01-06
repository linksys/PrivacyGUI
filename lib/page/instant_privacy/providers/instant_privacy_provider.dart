import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
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
    with
        PreservableNotifierMixin<InstantPrivacySettings, InstantPrivacyStatus,
            InstantPrivacyState> {
  @override
  InstantPrivacyState build() {
    // Asynchronously trigger fetch to load actual data
    Future.microtask(() => fetch());
    return InstantPrivacyState.init();
  }

  @override
  Future<(InstantPrivacySettings?, InstantPrivacyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(instantPrivacyServiceProvider);

    final (settings, status) = await service.fetchMacFilterSettings(
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );

    // For status-only updates, don't fetch myMac
    if (updateStatusOnly) {
      return (null, status);
    }

    // Fetch myMac and add to settings
    final myMac = await getMyMACAddress();
    final newSettings = settings?.copyWith(myMac: myMac);

    return (newSettings, status);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(instantPrivacyServiceProvider);

    // Get node MAC addresses for allow mode
    final nodesMacAddresses = ref
        .read(deviceManagerProvider)
        .nodeDevices
        .map((e) => e.getMacAddress().toUpperCase())
        .toList();

    await service.saveMacFilterSettings(
      state.settings.current,
      nodesMacAddresses,
    );
  }

  Future doPolling() {
    return ref.read(pollingProvider.notifier).forcePolling();
  }

  Future<String?> getMyMACAddress() {
    final service = ref.read(instantPrivacyServiceProvider);
    final deviceList = ref.read(deviceManagerProvider).deviceList;
    return service.fetchMyMacAddress(deviceList);
  }

  setEnable(bool isEnabled) {
    state = state.copyWith(
        settings: state.settings.update(state.settings.current.copyWith(
            mode: isEnabled ? MacFilterMode.allow : MacFilterMode.disabled)));
  }

  setAccess(MacFilterMode value) {
    state = state.copyWith(
        settings: state.settings
            .update(state.settings.current.copyWith(mode: value)));
  }

  setSelection(List<String> selections, [bool isDeny = false]) {
    selections = selections.map((e) => e.toUpperCase()).toList();
    final List<String> unique = List.from(isDeny
        ? state.settings.current.denyMacAddresses
        : state.settings.current.macAddresses)
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
    final list = List<String>.from(isDeny
        ? state.settings.current.denyMacAddresses
        : state.settings.current.macAddresses)
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
        settings: state.settings.update(
            state.settings.current.copyWith(macAddresses: macAddressList)));
  }
}
