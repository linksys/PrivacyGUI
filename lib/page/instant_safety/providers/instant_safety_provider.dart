import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final instantSafetyProvider =
    NotifierProvider<InstantSafetyNotifier, InstantSafetyState>(
        () => InstantSafetyNotifier());

// The provider now needs to be generic to match the contract.
final preservableInstantSafetyProvider =
    Provider<PreservableContract<InstantSafetySettings, InstantSafetyStatus>>(
        (ref) {
  return ref.watch(instantSafetyProvider.notifier);
});

class InstantSafetyNotifier extends Notifier<InstantSafetyState>
    with
        PreservableNotifierMixin<InstantSafetySettings, InstantSafetyStatus,
            InstantSafetyState> {
  @override
  InstantSafetyState build() {
    // The mixin's fetch method is now available.
    fetch(forceRemote: true);
    return InstantSafetyState.initial();
  }

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(instantSafetyServiceProvider);
    final deviceInfo = ref.read(instantSafetyDeviceInfoProvider);

    final result = await service.fetchSettings(
      deviceInfo: deviceInfo,
      forceRemote: forceRemote,
    );

    final settings =
        InstantSafetySettings(safeBrowsingType: result.safeBrowsingType);
    final status = InstantSafetyStatus(hasFortinet: result.hasFortinet);

    return (settings, status);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(instantSafetyServiceProvider);
    final currentType = state.settings.current.safeBrowsingType;
    await service.saveSettings(currentType);
  }

  // These methods are for UI interaction to update the 'current' state.
  void setSafeBrowsingEnabled(bool isEnabled) {
    final newType = isEnabled
        ? (state.status.hasFortinet
            ? InstantSafetyType.fortinet
            : InstantSafetyType.openDNS)
        : InstantSafetyType.off;

    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(safeBrowsingType: newType),
      ),
    );
  }

  void setSafeBrowsingProvider(InstantSafetyType provider) {
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(safeBrowsingType: provider),
      ),
    );
  }
}
