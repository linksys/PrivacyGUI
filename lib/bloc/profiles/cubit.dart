import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/mock.dart';
import 'package:linksys_moab/security/app_signature.dart';
import 'package:linksys_moab/security/cloud_preset.dart';
import 'package:linksys_moab/security/web_filter.dart';
import 'package:linksys_moab/security/app_icon_manager.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit() : super(const ProfilesState());

  fetchProfiles() async {
    await Future.delayed(Duration(seconds: 3));

    emit(state.copyWith(
        profiles: Map.fromEntries(mockProfiles.map((e) => MapEntry(e.id, e)))));
    fetchAllServices();
  }

  selectProfile(Profile? profile) {
    emit(state.copyWith(selectedProfile: profile));
  }

  updateCreatedProfile({
    String? name,
    String? icon,
    List<PDevice>? devices,
  }) {
    Profile? _profile = state.createdProfile;
    _profile ??= Profile(
        id: 'PROFILE_ID_${Random().nextInt(999999)}',
        name: name ?? '',
        icon: icon ?? '',
        devices: devices ?? []);
    emit(state.copyWith(
      createdProfile: _profile.copyWith(
          name: name ?? _profile.name,
          icon: icon ?? _profile.icon,
          devices: devices ?? _profile.devices),
    ));
  }

  saveCreatedProfile() {
    if (state.createdProfile == null) {
      return;
    }
    emit(state.copyWith(createdProfile: null)
      ..addOrUpdateProfile(state.createdProfile!));
  }

  fetchAllServices({PService serviceCategory = PService.all}) async {
    await Future.delayed(Duration(seconds: 3));
    for (var profile in state.profileList) {
      final profileId = profile.id;
      Map<PService, MoabServiceData> dataMap = {};
      if (serviceCategory == PService.internetSchedule ||
          serviceCategory == PService.all) {
        final data = mockInternetScheduleData[profileId];
        if (data != null) {
          dataMap[PService.internetSchedule] = data;
        }
      }
      if (serviceCategory == PService.contentFilter ||
          serviceCategory == PService.all) {
        // final data = mockContentFilterData[profileId];
        // if (data != null) {
        //   dataMap[PService.contentFilter] = data;
        // }
      }

      emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
    }
  }

  // Internet schedule - Daily time limit
  updateDailyTimeLimitEnabled(String profileId, DateTimeLimitRule rule,
      bool isEnabled) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final copy = List<DateTimeLimitRule>.from(data.dateTimeLimitRule);
    copy.contains(rule)
        ? copy.replaceRange(copy.indexOf(rule), copy.indexOf(rule) + 1,
        [rule.copyWith(isEnabled: isEnabled)])
        : copy.add(rule.copyWith(isEnabled: isEnabled));
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] = data.copyWith(dateTimeLimitRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  Future<void> updateDetailTimeLimitDetail(String profileId,
      DateTimeLimitRule rule, List<bool> weeklyBool, int timeInSeconds) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final newRule =
    rule.copyWith(weeklySet: weeklyBool, timeInSeconds: timeInSeconds);
    final copy = List<DateTimeLimitRule>.from(data.dateTimeLimitRule);
    copy.contains(rule)
        ? copy
        .replaceRange(copy.indexOf(rule), copy.indexOf(rule) + 1, [newRule])
        : copy.add(newRule);
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] = data.copyWith(dateTimeLimitRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  Future<bool> deleteTimeLimitRule(String profileId,
      DateTimeLimitRule rule) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final copy = List<DateTimeLimitRule>.from(data.dateTimeLimitRule);
    if (copy.contains(rule)) {
      copy.remove(rule);
    }
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] = data.copyWith(dateTimeLimitRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
    return true;
  }

  // Internet schedule - schedule pauses
  updateSchedulePausesEnabled(String profileId, ScheduledPausedRule rule,
      bool isEnabled) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final copy = List<ScheduledPausedRule>.from(data.scheduledPauseRule);
    copy.contains(rule)
        ? copy.replaceRange(copy.indexOf(rule), copy.indexOf(rule) + 1,
        [rule.copyWith(isEnabled: isEnabled)])
        : copy.add(rule.copyWith(isEnabled: isEnabled));
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] =
        data.copyWith(scheduledPauseRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  Future<void> updateSchedulePausesDetail(String profileId,
      ScheduledPausedRule rule,
      List<bool> weeklyBool,
      int startTimeInSeconds,
      int endTimeInSeconds,
      bool isAllDay,) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final newRule = rule.copyWith(
        weeklySet: weeklyBool,
        pauseStartTime: startTimeInSeconds,
        pauseEndTime: endTimeInSeconds,
        isAllDay: isAllDay);
    final copy = List<ScheduledPausedRule>.from(data.scheduledPauseRule);
    copy.contains(rule)
        ? copy
        .replaceRange(copy.indexOf(rule), copy.indexOf(rule) + 1, [newRule])
        : copy.add(newRule);
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] =
        data.copyWith(scheduledPauseRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  Future<bool> deleteSchedulePausesRule(String profileId,
      ScheduledPausedRule rule) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data = profile.serviceDetails[PService.internetSchedule]
    as InternetScheduleData?;
    data ??= InternetScheduleData(
        dateTimeLimitRule: const [],
        scheduledPauseRule: const [],
        profileId: profileId);
    final copy = List<ScheduledPausedRule>.from(data.scheduledPauseRule);
    if (copy.contains(rule)) {
      copy.remove(rule);
    }
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.internetSchedule] =
        data.copyWith(scheduledPauseRule: copy);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
    return true;
  }

  // Content filter
  updateContentFilterEnabled(String profileId, bool isEnabled) {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data =
    profile.serviceDetails[PService.contentFilter] as ContentFilterData?;
    if (data == null) return;
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.contentFilter] = data.copyWith(isEnabled: isEnabled);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  Future updateContentFilterDetails(String profileId,
      CFSecureProfile secureProfile,) async {
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data =
    profile.serviceDetails[PService.contentFilter] as ContentFilterData?;
    if (data == null) {
      data = ContentFilterData(
          isEnabled: true,
          secureProfile: secureProfile,
          profileId: profileId);
    } else {
      data = data.copyWith(secureProfile: secureProfile);
    }
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.contentFilter] = data;
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  @override
  void onChange(Change<ProfilesState> change) {
    super.onChange(change);
    logger.i(
        'Profiles Cubit changed: ${change.currentState} -> ${change
            .nextState}');
  }
}
