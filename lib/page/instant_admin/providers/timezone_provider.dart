import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final timezoneProvider =
    NotifierProvider<TimezoneNotifier, TimezoneState>(() => TimezoneNotifier());

final preservableTimezoneProvider = Provider<PreservableContract>(
  (ref) => ref.watch(timezoneProvider.notifier),
);

class TimezoneNotifier extends Notifier<TimezoneState> with PreservableNotifierMixin<TimezoneSettings, TimezoneStatus, TimezoneState> {
  @override
  TimezoneState build() => TimezoneState.init();

  @override
  Future<(TimezoneSettings, TimezoneStatus)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.getTimeSettings,
      auth: true,
      fetchRemote: forceRemote,
    );

    final timezoneId = result.output['timeZoneID'] ?? 'PST8';
    final supportedTimezones = List.from(result.output['supportedTimeZones'])
        .map((e) => SupportedTimezone.fromMap(e))
        .toList()
      ..sort((t1, t2) {
        return t1.utcOffsetMinutes.compareTo(t2.utcOffsetMinutes);
      });
    final autoAdjustForDST = result.output['autoAdjustForDST'] ?? false;

    final settings = TimezoneSettings(
      isDaylightSaving: autoAdjustForDST,
      timezoneId: timezoneId,
    );
    final status = TimezoneStatus(
      supportedTimezones: supportedTimezones,
      error: null,
    );

    return (settings, status);
  }

  @override
  Future<void> performSave() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(
      JNAPAction.setTimeSettings,
      data: {
        'timeZoneID': state.settings.current.timezoneId,
        'autoAdjustForDST': (state.status.supportedTimezones
                    .firstWhereOrNull(
                        (e) => e.timeZoneID == state.settings.current.timezoneId)
                    ?.observesDST) ??
                false
            ? state.settings.current.isDaylightSaving
            : false,
      },
      auth: true,
    );
    await ref.read(pollingProvider.notifier).forcePolling();
  }

  bool isSelectedTimezone(int index) {
    return state.status.supportedTimezones[index].timeZoneID == state.settings.current.timezoneId;
  }

  bool isSupportDaylightSaving() {
    return state.status.supportedTimezones
            .firstWhereOrNull((e) => e.timeZoneID == state.settings.current.timezoneId)
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
