import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/services/dmz_settings_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final preservableDMZSettingsProvider = Provider<PreservableContract>(
    (ref) => ref.watch(dmzSettingsProvider.notifier));

final dmzSettingsProvider =
    NotifierProvider<DMZSettingsNotifier, DMZSettingsState>(
        () => DMZSettingsNotifier());

class DMZSettingsNotifier extends Notifier<DMZSettingsState>
    with PreservableNotifierMixin<DMZUISettings, DMZStatus, DMZSettingsState> {
  @override
  DMZSettingsState build() {
    const settings = DMZUISettings(
      isDMZEnabled: false,
      sourceType: DMZSourceType.auto,
      destinationType: DMZDestinationType.ip,
    );
    return const DMZSettingsState(
      settings: Preservable(original: settings, current: settings),
      status: DMZStatus(),
    );
  }

  @override
  Future<(DMZUISettings?, DMZStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(dmzSettingsServiceProvider);
    return service.fetchDmzSettings(ref, forceRemote: forceRemote);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(dmzSettingsServiceProvider);
    final uiSettings = state.settings.current;
    await service.saveDmzSettings(ref, uiSettings);
  }

  /// Updates the current DMZ settings.
  ///
  /// This updates the current settings without affecting the original settings,
  /// allowing for undo/reset functionality through [PreservableNotifierMixin].
  void setSettings(DMZUISettings settings) {
    state =
        state.copyWith(settings: state.settings.copyWith(current: settings));
  }

  /// Sets the DMZ source IP restriction type (auto or range).
  ///
  /// When switching to [DMZSourceType.auto], clears any existing source restriction.
  /// When switching to [DMZSourceType.range], initializes from original settings or creates new.
  void setSourceType(DMZSourceType type) {
    final currentSettings = state.settings.current;
    final originalSettings = state.settings.original;
    final newSettings = type == DMZSourceType.auto
        ? currentSettings.copyWith(sourceRestriction: () => null)
        : currentSettings.copyWith(
            sourceRestriction: () =>
                originalSettings.sourceRestriction ??
                DMZSourceRestrictionUI(firstIPAddress: '', lastIPAddress: ''));

    state = state.copyWith(
      settings: state.settings
          .copyWith(current: newSettings.copyWith(sourceType: type)),
    );
  }

  /// Sets the DMZ destination address type (IP address or MAC address).
  ///
  /// When switching to [DMZDestinationType.ip], clears MAC address.
  /// When switching to [DMZDestinationType.mac], clears IP address.
  void setDestinationType(DMZDestinationType type) {
    final currentSettings = state.settings.current;
    final newSettings = type == DMZDestinationType.ip
        ? currentSettings.copyWith(
            destinationMACAddress: () => null,
            destinationIPAddress: () =>
                state.settings.original.destinationIPAddress ?? '')
        : currentSettings.copyWith(
            destinationIPAddress: () => null,
            destinationMACAddress: () =>
                state.settings.original.destinationMACAddress ?? '');
    state = state.copyWith(
      settings: state.settings
          .copyWith(current: newSettings.copyWith(destinationType: type)),
    );
  }
}
