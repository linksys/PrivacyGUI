import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';

final timezoneProvider =
    NotifierProvider<TimezoneNotifier, TimezoneState>(() => TimezoneNotifier());

class TimezoneNotifier extends Notifier<TimezoneState> {
  @override
  TimezoneState build() => TimezoneState.init();

  Future fetch({bool fetchRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.getTimeSettings,
      auth: true,
      fetchRemote: fetchRemote,
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
        timezoneId: timezoneId,
        supportedTimezones: supportedTimezones,
        isDaylightSaving: autoAdjustForDST);
    logger.d('[State]:[Timezone]:${state.toJson()}');
  }

  Future save() async {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.setTimeSettings,
      data: {
        'timeZoneID': state.timezoneId,
        'autoAdjustForDST': (state.supportedTimezones
                    .firstWhereOrNull((e) => e.timeZoneID == state.timezoneId)
                    ?.observesDST) ??
                false
            ? state.isDaylightSaving
            : false,
      },
      auth: true,
    )
        .then<void>((value) async {
      await fetch(fetchRemote: true);
      await ref.read(pollingProvider.notifier).forcePolling();
    });
  }

  bool isSelectedTimezone(int index) {
    return state.supportedTimezones[index].timeZoneID == state.timezoneId;
  }

  bool isSupportDaylightSaving() {
    return state.supportedTimezones
            .firstWhereOrNull((e) => e.timeZoneID == state.timezoneId)
            ?.observesDST ??
        false;
  }

  setSelectedTimezone(int index) {
    final selected = state.supportedTimezones[index];
    state = state.copyWith(
        timezoneId: selected.timeZoneID,
        isDaylightSaving: selected.observesDST);
  }

  setDaylightSaving(bool isDaylightSaving) {
    state = state.copyWith(isDaylightSaving: isDaylightSaving);
  }
}
