import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final timezoneProvider =
    NotifierProvider<TimezoneNotifier, TimezoneState>(() => TimezoneNotifier());

class TimezoneNotifier extends Notifier<TimezoneState>
    with PreservableNotifierMixin<TimezoneSettings, TimezoneStatus, TimezoneState> {
  @override
  TimezoneState build() {
    return TimezoneState.init();
  }

  @override
  Future<void> performFetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.getTimeSettings,
      auth: true,
    );
    final timezoneId = result.output['timeZoneID'] ?? 'PST8';
    final supportedTimezones = List.from(result.output['supportedTimeZones'])
        .map((e) => SupportedTimezone.fromMap(e))
        .toList()
      ..sort((t1, t2) {
        return t1.utcOffsetMinutes.compareTo(t2.utcOffsetMinutes);
      });
    final autoAdjustForDST = result.output['autoAdjustForDST'] ?? false;
    state = state.copyWith(
      settings: state.settings.copyWith(
        timezoneId: timezoneId,
        isDaylightSaving: autoAdjustForDST,
      ),
      status: state.status.copyWith(
        supportedTimezones: supportedTimezones,
      ),
    );
    logger.d('[State]:[Timezone]:${state.toJson()}');
  }

  @override
  Future<void> performSave() async {
    final repo = ref.read(routerRepositoryProvider);
    await repo
        .send(
      JNAPAction.setTimeSettings,
      data: {
        'timeZoneID': state.settings.timezoneId,
        'autoAdjustForDST': (state.status.supportedTimezones
                    .firstWhereOrNull(
                        (e) => e.timeZoneID == state.settings.timezoneId)
                    ?.observesDST) ??
                false
            ? state.settings.isDaylightSaving
            : false,
      },
      auth: true,
    )
        .then<void>((value) async {
      await ref.read(pollingProvider.notifier).forcePolling();
    });
  }

  bool isSelectedTimezone(int index) {
    return state.status.supportedTimezones[index].timeZoneID ==
        state.settings.timezoneId;
  }

  bool isSupportDaylightSaving() {
    return state.status.supportedTimezones
            .firstWhereOrNull(
                (e) => e.timeZoneID == state.settings.timezoneId)
            ?.observesDST ??
        false;
  }

  void setSelectedTimezone(int index) {
    final selected = state.status.supportedTimezones[index];
    state = state.copyWith(
      settings: state.settings.copyWith(
        timezoneId: selected.timeZoneID,
        isDaylightSaving: selected.observesDST,
      ),
    );
  }

  void setDaylightSaving(bool isDaylightSaving) {
    state = state.copyWith(
      settings: state.settings.copyWith(isDaylightSaving: isDaylightSaving),
    );
  }
}

final preservableTimezoneProvider =
    Provider.autoDispose<PreservableContract<TimezoneSettings, TimezoneStatus>>(
        (ref) {
  return ref.watch(timezoneProvider.notifier);
});
