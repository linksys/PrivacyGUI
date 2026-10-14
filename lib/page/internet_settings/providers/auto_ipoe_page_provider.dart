import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';

final autoIPoEPageProvider =
    AutoDisposeNotifierProvider<AutoIPoEPageNotifier, AutoIPoEPageState>(
        AutoIPoEPageNotifier.new);

class AutoIPoEPageNotifier extends AutoDisposeNotifier<AutoIPoEPageState>
    with
        PreservableAutoDisposeNotifierMixin<AutoIPoESettings,
            AutoIPoEPageStatus, AutoIPoEPageState> {
  @override
  AutoIPoEPageState build() {
    ref.listen(autoIPoEDataProvider, (_, next) {
      final snapshot = next.valueOrNull;
      if (snapshot != null) {
        // Runtime polling never overwrites an in-progress edit.
        state = state.copyWith(
            status: AutoIPoEPageStatus(
                snapshot: snapshot,
                saving: state.status.saving,
                error: next.error is ServiceError
                    ? next.error as ServiceError
                    : null));
      }
    });
    Future.microtask(fetch);
    return AutoIPoEPageState.initial();
  }

  @override
  Future<(AutoIPoESettings?, AutoIPoEPageStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    try {
      if (forceRemote) await ref.read(autoIPoEDataProvider.notifier).refresh();
      final snapshot = await ref.read(autoIPoEDataProvider.future);
      return (snapshot.settings, AutoIPoEPageStatus(snapshot: snapshot));
    } on ServiceError catch (e) {
      return (
        null,
        AutoIPoEPageStatus(snapshot: state.status.snapshot, error: e)
      );
    }
  }

  void updateSettings(AutoIPoESettings settings) {
    state = state.copyWith(settings: state.settings.update(settings));
  }

  // PnP keeps the draft (including entered secrets) until the verified job
  // finishes. The general Save path intentionally re-fetches masked settings.
  Future<void> saveForPnp() => performSave();

  @override
  Future<void> performSave() async {
    // Never submit an IPoE draft while the selectable-service policy is unknown.
    // Reset remains available through the separate verified recovery path.
    if (ref.read(autoIPoEDataProvider).valueOrNull?.capabilitiesAvailable !=
        true) {
      throw const ConnectivityError();
    }
    state = state.copyWith(
        status:
            AutoIPoEPageStatus(snapshot: state.status.snapshot, saving: true));
    try {
      final current = state.current.copyWith(
          isEnabled: true,
          selectedMode: state.current.selectedMode == AutoIPoEMode.disabled
              ? AutoIPoEMode.auto
              : state.current.selectedMode);
      await ref.read(autoIPoEDataProvider.notifier).apply(current,
          resetFirst: state.status.snapshot.settings.isEnabled &&
              state.status.snapshot.settings.selectedMode !=
                  current.selectedMode);
    } finally {
      state = state.copyWith(
          status: AutoIPoEPageStatus(snapshot: state.status.snapshot));
    }
  }
}
