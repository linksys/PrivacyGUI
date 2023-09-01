import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/timezone.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/timezone/timezone_state.dart';

final timezoneProvider =
    NotifierProvider<TimezoneNotifier, TimezoneState>(() => TimezoneNotifier());

class TimezoneNotifier extends Notifier<TimezoneState> {
  @override
  TimezoneState build() => TimezoneState.init();

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.getTimeSettings,
      auth: true,
    );
    final timezoneId = result.output['timeZoneID'] ?? 'PST8';
    final supportedTimezones = List.from(result.output['supportedTimeZones'])
        .map((e) => SupportedTimezone.fromJson(e))
        .toList();
    final autoAdjustForDST = result.output['autoAdjustForDST'] ?? false;
    state = state.copyWith(
        timezoneId: timezoneId,
        supportedTimezones: supportedTimezones,
        isDaylightSaving: autoAdjustForDST);
  }

  Future save() async {
    final repo = ref.read(routerRepositoryProvider);
    return repo
        .send(
      JNAPAction.setTimeSettings,
      data: {
        'timeZoneID': state.timezoneId,
        'autoAdjustForDST': state.isDaylightSaving,
      },
      auth: true,
    )
        .then<void>((value) async {
      await fetch();
    }).onError((error, stackTrace) {
      if (error is JNAPError) {
        // handle error
        state = state.copyWith(error: error.error);
      }
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
        isDaylightSaving:
            selected.observesDST ? state.isDaylightSaving : false);
  }

  setDaylightSaving(bool isDaylightSaving) {
    state = state.copyWith(isDaylightSaving: isDaylightSaving);
  }
}
