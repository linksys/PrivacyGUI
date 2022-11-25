import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/timezone.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/jnap_result.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class TimezoneCubit extends Cubit<TimezoneState> {
  TimezoneCubit(RouterRepository repository)
      : _repository = repository,
        super(TimezoneState.init());

  final RouterRepository _repository;

  fetch() async {
    final result = await _repository.getTimeSettings();
    final timezoneId = result.output['timeZoneID'] ?? 'PST8';
    final supportedTimezones = List.from(result.output['supportedTimeZones']).map((e) => SupportedTimezone.fromJson(e)).toList();
    final autoAdjustForDST = result.output['autoAdjustForDST'] ?? false;
    emit(state.copyWith(timezoneId: timezoneId, supportedTimezones: supportedTimezones, isDaylightSaving: autoAdjustForDST));
  }

  Future save() async {
    return _repository
        .setTimeSettings(state.timezoneId, state.isDaylightSaving)
        .then<void>((value) async {
      await fetch();
    }).onError((error, stackTrace) => onError(error ?? Object(), stackTrace));
  }

  bool isSelectedTimezone(int index) {
    return state.supportedTimezones[index].timeZoneID == state.timezoneId;
  }
  bool isSupportDaylightSaving() {
    return state.supportedTimezones.firstWhereOrNull((e) => e.timeZoneID == state.timezoneId)?.observesDST ?? false;
  }

  setSelectedTimezone(int index) {
    final selected = state.supportedTimezones[index];
    emit(state.copyWith(timezoneId: selected.timeZoneID, isDaylightSaving: selected.observesDST ? state.isDaylightSaving : false ));
  }
  setDaylightSaving(bool isDaylightSaving) {
    emit(state.copyWith(isDaylightSaving: isDaylightSaving));
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JNAPError) {
      // handle error
      emit(state.copyWith(error: error.error));
    }
  }

  @override
  void onChange(Change<TimezoneState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
