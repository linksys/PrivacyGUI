import 'dart:convert';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/mock.dart';
import 'package:linksys_moab/model/app_signature.dart';
import 'package:linksys_moab/model/fcn/address_group.dart';
import 'package:linksys_moab/model/fcn/application.dart';
import 'package:linksys_moab/model/fcn/application_list.dart';
import 'package:linksys_moab/model/fcn/objects.dart';
import 'package:linksys_moab/model/fcn/policy.dart';
import 'package:linksys_moab/model/fcn/web_filter.dart';
import 'package:linksys_moab/model/fcn/web_filter_profile.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/model/web_filter.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:collection/collection.dart';
import 'package:linksys_moab/util/storage.dart';

import 'state.dart';

class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit() : super(const ProfilesState());

  fetchProfiles() async {
    await Future.delayed(Duration(seconds: 3));

    emit(state.copyWith(
        profiles: Map.fromEntries(mockProfiles.map((e) => MapEntry(e.id, e)))));
    fetchAllServices();
  }

  selectProfile(GroupProfile? profile) {
    emit(state.copyWith(selectedProfile: profile));
  }

  updateCreatedProfile({
    String? name,
    String? icon,
    List<PDevice>? devices,
  }) {
    GroupProfile? _profile = state.createdProfile;
    _profile ??= GroupProfile(
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
    emit(state
        .addOrUpdateProfile(state.createdProfile!)
        .copyWith(createdProfile: null));
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

  // TODO refactor
  // Internet schedule - Daily time limit
  updateDailyTimeLimitEnabled(
      String profileId, DateTimeLimitRule rule, bool isEnabled) async {
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

  Future<bool> deleteTimeLimitRule(
      String profileId, DateTimeLimitRule rule) async {
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
  updateSchedulePausesEnabled(
      String profileId, ScheduledPausedRule rule, bool isEnabled) async {
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

  Future<void> updateSchedulePausesDetail(
    String profileId,
    ScheduledPausedRule rule,
    List<bool> weeklyBool,
    int startTimeInSeconds,
    int endTimeInSeconds,
    bool isAllDay,
  ) async {
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

  Future<bool> deleteSchedulePausesRule(
      String profileId, ScheduledPausedRule rule) async {
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

  Future updateContentFilterDetails(
      String profileId,
      CFSecureProfile secureProfile,
      Set<CFAppSignature> blockedSearchApplication) async {
    logger.d('updateContentFilterDetails: $profileId');
    var profile = state.selectedProfile;
    if (profile == null || profile.id != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.id == profileId);
    }
    var data =
        profile.serviceDetails[PService.contentFilter] as ContentFilterData?;
    if (data == null) {
      data = ContentFilterData(
          isEnabled: true, secureProfile: secureProfile, profileId: profileId);
    } else {
      data = data.copyWith(secureProfile: secureProfile);
    }
    Map<PService, MoabServiceData> dataMap = Map.from(profile.serviceDetails);
    dataMap[PService.contentFilter] = data;
    _transformDataToFCN(profile, data, blockedSearchApplication);
    emit(state.addOrUpdateProfile(profile.copyWith(serviceDetails: dataMap)));
  }

  _transformDataToFCN(GroupProfile profile, ContentFilterData data,
      Set<CFAppSignature> changedSearchApplication) async {
    await _createWebFilterProfile(profile, data);
    await _createApplicationList(profile, data, changedSearchApplication);
    _createAddressGroup(profile);
    _createPolicy(profile);
  }

  _createWebFilterProfile(GroupProfile profile, ContentFilterData data) async {
    final blockedWebFilters = data.secureProfile.securityCategories
        .where((categories) =>
            categories.webFilters.status != FilterStatus.allowed)
        .fold<List<WebFilter>>(
            List<WebFilter>.empty(),
            (previousValue, categories) =>
                [...previousValue, ...categories.webFilters.webFilters]);
    logger.d('Blocked web filters $blockedWebFilters');
    final fcnBlockedWebFilters =
        blockedWebFilters.map((e) => FCNWebFilter.fromData(e)).toList();
    final fcnWebFilterProfile = FCNWebFilterProfile(
        name: base64Encode(profile.name.codeUnits),
        comment: "${profile.name}'s web filter profile",
        filters: fcnBlockedWebFilters);
    logger.d(
        'FCN Web Filter Profile: ${jsonEncode(fcnWebFilterProfile.toFullJson())}');
  }

  _createApplicationList(GroupProfile profile, ContentFilterData data,
      Set<CFAppSignature> changedSearchApplication) async {
    final blockedApps = data.secureProfile.securityCategories
        .fold<List<CloudAppSignature>>(
            [],
            (previousValue, categories) => [
                  ...previousValue,
                  ..._extractRawApps(categories.apps
                      .where((cfApp) => cfApp.status != FilterStatus.allowed))
                ])
      ..addAll(_extractRawApps(changedSearchApplication
          .where((element) => element.status != FilterStatus.allowed)));
    logger.d('Blocked Apps $blockedApps');

    final blockedAppDataList = await SecurityProfileManager.instance()
        .fetchAppSignature()
        .then((appSignatureList) => appSignatureList
            .where((appSignature) => blockedApps
                .any((blockedApp) => blockedApp.id == appSignature.id))
            .toList())
        .onError((error, stackTrace) => []);
    logger.d('Blocked App Data List: ${jsonEncode(blockedAppDataList.map((e) => e.toJson()).toList())}');
    final fcnBlockedApp =
        blockedAppDataList.map((e) => FCNApplication.fromData(e)).toList();

    final fcnApplicationList = FCNApplicationList(
      name: base64Encode(profile.name.codeUnits),
      comment: "${profile.name}'s application list",
      entries: fcnBlockedApp,
    );
    logger.d(
        'FCN Application List: ${jsonEncode(fcnApplicationList.toFullJson())}');
  }

  List<CloudAppSignature> _extractRawApps(Iterable<CFAppSignature> cfApps) {
    return cfApps
        .where((cfApp) => cfApp.status != FilterStatus.allowed)
        .fold<List<CloudAppSignature>>(
      [],
      (previousValue, element) => [
        ...previousValue,
        ...element.raw.whereType<CloudAppSignature>(),
      ],
    );
  }

  _createAddressGroup(GroupProfile profile) {
    // TODO do not have group yet
    final addressGroup = FCNAddressGroup(
      name: base64Encode(profile.name.codeUnits),
      comment: "${profile.name}'s address group",
      member: [
        FCNNameObject(name: 'MacBook-Pro-2'),
        FCNNameObject(name: 'Pixel-6'),
      ],
    );
    // TODO FCN command to set into FCN
    logger.d('Address group: ${jsonEncode(addressGroup.toJson())}');
  }

  _createPolicy(GroupProfile profile) {
    final policy = FCNPolicy(
      policyid: '199',
      status: 'enable',
      name: base64Encode(profile.name.codeUnits),
      addressGroup: base64Encode(profile.name.codeUnits),
      webFilterProfile: base64Encode(profile.name.codeUnits),
      applicationList: base64Encode(profile.name.codeUnits),
      nid: 'd525eed2-3fea-454c-91c5-f69d9b0dfab5',
      gid: base64Encode(profile.name.codeUnits),
      devices: ['MacBook-Pro-2'],
    );
    logger.d('Policy: ${jsonEncode(policy.toFullJson())}');
  }

  @override
  void onChange(Change<ProfilesState> change) {
    super.onChange(change);
    logger.i(
        'Profiles Cubit changed: ${change.currentState} -> ${change.nextState}');
  }
}
