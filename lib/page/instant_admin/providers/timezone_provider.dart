import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/page/instant_admin/services/timezone_service.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final timezoneProvider =
    NotifierProvider<TimezoneNotifier, TimezoneState>(() => TimezoneNotifier());

final preservableTimezoneProvider = Provider<PreservableContract>(
  (ref) => ref.watch(timezoneProvider.notifier),
);

class TimezoneNotifier extends Notifier<TimezoneState>
    with
        PreservableNotifierMixin<TimezoneSettings, TimezoneStatus,
            TimezoneState> {
  @override
  TimezoneState build() => TimezoneState.init();

  @override
  Future<(TimezoneSettings, TimezoneStatus)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final service = ref.read(timezoneServiceProvider);
    return service.fetchTimezoneSettings(forceRemote: forceRemote);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(timezoneServiceProvider);
    await service.saveTimezoneSettings(
      settings: state.settings.current,
      supportedTimezones: state.status.supportedTimezones,
    );
    await ref.read(pollingProvider.notifier).forcePolling();
  }

  bool isSelectedTimezone(int index) {
    return state.status.supportedTimezones[index].timeZoneID ==
        state.settings.current.timezoneId;
  }

  bool isSupportDaylightSaving() {
    return state.status.supportedTimezones
            .firstWhereOrNull(
                (e) => e.timeZoneID == state.settings.current.timezoneId)
            ?.observesDST ??
        false;
  }

  setSelectedTimezone(int index) {
    final selected = state.status.supportedTimezones[index];
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          timezoneId: selected.timeZoneID,
          isDaylightSaving: selected.observesDST,
        ),
      ),
    );
  }

  setDaylightSaving(bool isDaylightSaving) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          isDaylightSaving: isDaylightSaving,
        ),
      ),
    );
  }
}
