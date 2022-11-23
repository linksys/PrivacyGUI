import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/mock.dart';
import 'package:linksys_moab/constants/_constants.dart';
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
import 'package:linksys_moab/network/mqtt/model/command/jnap/fcn_result.dart';
import 'package:linksys_moab/repository/router/fcn_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';

class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit(RouterRepository routerRepository)
      : _routerRepository = routerRepository,
        super(const ProfilesState());

  final RouterRepository _routerRepository;

  fetchProfiles() async {
    final sharedPreference = await SharedPreferences.getInstance();
    final jsonString = sharedPreference.getString(moabPrefUserProfiles);
    if (jsonString != null) {
      final jsonObject = jsonDecode(jsonString) as Map<String, dynamic>;
      final savedProfiles = jsonObject
          .map((key, value) => MapEntry(key, UserProfile.fromJson(value)));
      emit(state.copyWith(
        profiles: savedProfiles,
      ));
    }

    fetchAllServices();
  }

  selectProfile(UserProfile? profile) {
    emit(state.copyWith(selectedProfile: profile));
  }

  createProfile({String? name, String? icon, List<ProfileDevice>? devices}) {
    var profile = state.createdProfile ?? UserProfile();
    emit(state.copyWith(
        createdProfile: profile.copyWith(
      name: name ?? profile.name,
      icon: icon ?? profile.icon,
      devices: devices ?? profile.devices,
      enabled: true,
    )));
  }

  saveCreatedProfile() async {
    final createdProfile = state.createdProfile;
    if (createdProfile != null) {
      _newOrUpdateProfile(createdProfile);
      emit(state.copyWith(
        createdProfile: null,
      ));
      // Save the new profile list into the persistent storage
      final jsonString = jsonEncode(state.profiles);
      final sharedPreference = await SharedPreferences.getInstance();
      await sharedPreference.setString(moabPrefUserProfiles, jsonString);
    }
  }

  updateSelectedProfile({String? name, String? icon}) {
    final selectedProfile = state.selectedProfile;
    if (selectedProfile != null) {
      _newOrUpdateProfile(selectedProfile.copyWith(
        name: name,
        icon: icon,
      ));
    }
  }

  _newOrUpdateProfile(UserProfile profile) {
    var updatedProfiles = Map<String, UserProfile>.from(state.profiles);
    updatedProfiles[profile.name] = profile;
    if (profile.name == state.selectedProfile?.name) {
      emit(state.copyWith(
        profiles: updatedProfiles,
        selectedProfile: profile,
      ));
    } else {
      emit(state.copyWith(
        profiles: updatedProfiles,
      ));
    }
  }

  fetchAllServices({PService serviceCategory = PService.all}) async {
    await Future.delayed(const Duration(seconds: 3));
    for (var profile in state.profileList) {
      final profileId = profile.name; //TODO: There's no longer profileId!!
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

      _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
    }
  }

  bool isProfileNameValid(String name) {
    bool isValid = !state.profiles.keys.contains(name);
    return isValid;
  }

  // Internet schedule - Daily time limit
  updateDailyTimeLimitEnabled(
      String profileId, DateTimeLimitRule rule, bool isEnabled) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
  }

  Future<void> updateDetailTimeLimitDetail(String profileId,
      DateTimeLimitRule rule, List<bool> weeklyBool, int timeInSeconds) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
  }

  Future<bool> deleteTimeLimitRule(
      String profileId, DateTimeLimitRule rule) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
    return true;
  }

  // Internet schedule - schedule pauses
  updateSchedulePausesEnabled(
      String profileId, ScheduledPausedRule rule, bool isEnabled) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
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
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
  }

  Future<bool> deleteSchedulePausesRule(
      String profileId, ScheduledPausedRule rule) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
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

    _newOrUpdateProfile(profile.copyWith(serviceDetails: dataMap));
    return true;
  }

  // Content filter
  Future<bool> updateContentFilterEnabled(
      String profileId, bool isEnabled) async {
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
    }
    if (profile.contentFilterConfig == null) return false;
    var data = profile.contentFilterConfig?.data;
    final result = await _updateStatusToFCN(
        isEnabled, profile.contentFilterConfig!.policyId);
    if (result) {
      _newOrUpdateProfile(profile.copyWith(
          contentFilterConfig: profile.contentFilterConfig
              ?.copyWith(data: data?.copyWith(isEnabled: isEnabled))));
    } else {
      logger.d('FCN update enabled failed!');
    }
    return result;
  }

  Future<bool> updateContentFilterDetails(
      String profileId,
      String networkId,
      CFSecureProfile secureProfile,
      Set<CFAppSignature> blockedSearchApplication) async {
    logger.d('updateContentFilterDetails: $profileId');
    var profile = state.selectedProfile;
    //TODO: There's no longer profileId!!
    if (profile == null || profile.name != profileId) {
      profile =
          state.profileList.firstWhere((element) => element.name == profileId);
    }

    var data = profile.contentFilterConfig?.data;
    if (data == null) {
      data = ContentFilterData(
          isEnabled: true, secureProfile: secureProfile, profileId: profileId);
    } else {
      data = data.copyWith(secureProfile: secureProfile);
    }
    final result = await _transformDataToFCN(
        profile, networkId, data, blockedSearchApplication);
    logger.d('FCN:: store FCN data result: $result');
    if (result > 0) {
      _newOrUpdateProfile(profile.copyWith(
          contentFilterConfig: profile.contentFilterConfig
                  ?.copyWith(policyId: '$result', data: data) ??
              ContentFilterConfiguration(policyId: '$result', data: data)));
    } else {
      // TODO ERRORHANDLING
      logger.d('FCN:: Create policy failed!');
    }
    return result > 0;
  }

  Future<bool> _updateStatusToFCN(bool isEnabled, String policyId) async {
    final result = await _routerRepository
        .getFirewallPolicyById(policyId)
        .then<FCNResult?>((value) => value.toFCNResult())
        .onError((error, stackTrace) => null);
    if (result == null || result.status != 200) {
      // TODO ERRORHANDLING
      return false;
    }
    final policy = FCNPolicy.fromJson(result.response.results);
    policy.copyWith(status: isEnabled ? 'enable' : 'disable');
    return await _routerRepository
        .setFirewallPolicy(policy)
        .then((value) =>
            value.result == 'OK' && value.toFCNResult().status == 200)
        .onError((error, stackTrace) => false);
  }

  Future<int> _transformDataToFCN(
      UserProfile profile,
      String networkId,
      ContentFilterData data,
      Set<CFAppSignature> changedSearchApplication) async {
    final webFilterProfileSuccess =
        await _createWebFilterProfile(profile, data);
    final applicationListSuccess =
        await _createApplicationList(profile, data, changedSearchApplication);
    final addressGroupSuccess = await _createAddressGroup(profile);
    if (webFilterProfileSuccess &&
        applicationListSuccess &&
        addressGroupSuccess) {
      await _routerRepository.setLogCustomField(
          'gid',
          'gid',
          Utils.fullStringEncoded(
            profile.name,
          ));
      await _routerRepository.setLogCustomField(
        'nid',
        'nid',
        networkId,
      );

      return await _createPolicy(profile, networkId);
    } else {
      logger.e(
          'something wrong when save content filter data:: w:$webFilterProfileSuccess, a:$applicationListSuccess, g:$addressGroupSuccess');
      return -1;
    }
  }

  Future<bool> _createWebFilterProfile(
      UserProfile profile, ContentFilterData data) async {
    final blockedWebFilters = data.secureProfile.securityCategories
        .where((categories) =>
            categories.webFilters.status != FilterStatus.allowed)
        .fold<List<WebFilter>>(
            List<WebFilter>.empty(),
            (previousValue, categories) =>
                [...previousValue, ...categories.webFilters.webFilters]);
    // logger.d('Blocked web filters $blockedWebFilters');
    final fcnBlockedWebFilters =
        blockedWebFilters.map((e) => FCNWebFilter.fromData(e)).toList();
    final fcnWebFilterProfile = FCNWebFilterProfile(
        name: getProfileNameEncoded(profile.name),
        // comment: "${profile.name}'s web filter profile",
        filters: fcnBlockedWebFilters);
    // logger.d(
    //     'FCN Web Filter Profile: ${jsonEncode(fcnWebFilterProfile.toFullJson())}');
    final result = await _routerRepository
        .setWebFilterProfile(fcnWebFilterProfile)
        .then((value) =>
            value.result == 'OK' && value.toFCNResult().status == 200)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> _createApplicationList(
      UserProfile profile,
      ContentFilterData data,
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
    // logger.d('Blocked Apps $blockedApps');

    final blockedAppDataList = await SecurityProfileManager.instance()
        .fetchAppSignature()
        .then((appSignatureList) => appSignatureList
            .where((appSignature) => blockedApps
                .any((blockedApp) => blockedApp.id == appSignature.id))
            .toList())
        .onError((error, stackTrace) => []);
    // logger.d(
    //     'Blocked App Data List: ${jsonEncode(blockedAppDataList.map((e) => e.toJson()).toList())}');
    final fcnBlockedApp =
        blockedAppDataList.map((e) => FCNApplication.fromData(e)).toList();

    final fcnApplicationList = FCNApplicationList(
      name: getProfileNameEncoded(profile.name),
      // comment: "${profile.name}'s application list",
      entries: fcnBlockedApp,
    );
    // logger.d(
    //     'FCN Application List: ${jsonEncode(fcnApplicationList.toFullJson())}');
    final result = await _routerRepository
        .setApplicationList(fcnApplicationList)
        .then((value) =>
            value.result == 'OK' && value.toFCNResult().status == 200)
        .onError((error, stackTrace) => false);
    return result;
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

  Future<bool> _createAddressGroup(UserProfile profile) async {
    // TODO do not have group yet
    final addressGroup = FCNAddressGroup(
      name: getProfileNameEncoded(profile.name),
      // comment: "${profile.name}'s address group",
      member: profile.devices.map((e) => FCNNameObject(name: e.name)).toList(),
    );
    // TODO FCN command to set into FCN
    // logger.d('Address group: ${jsonEncode(addressGroup.toJson())}');
    final result = await _routerRepository
        .setFirewallAddrgrp(addressGroup)
        .then((value) =>
            value.result == 'OK' && value.toFCNResult().status == 200)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<int> _createPolicy(UserProfile profile, String networkId) async {
    final policy = FCNPolicy(
      policyid: profile.contentFilterConfig?.policyId ??
          await _generateAndCheckPolicyId(),
      status: 'enable',
      name: getProfileNameEncoded(profile.name),
      addressGroup: getProfileNameEncoded(profile.name),
      webFilterProfile: getProfileNameEncoded(profile.name),
      applicationList: getProfileNameEncoded(profile.name),
      devices: profile.devices.map((e) => e.name).toList(),
    );
    logger.d('Policy: ${jsonEncode(policy.toFullJson())}');
    final result = await _routerRepository
        .setFirewallPolicy(policy)
        .then((value) =>
            value.result == 'OK' && value.toFCNResult().status == 200
                ? int.parse(policy.policyid)
                : -1)
        .onError((error, stackTrace) => -1);
    return result;
  }

  Future<String> _generateAndCheckPolicyId() async {
    final fcnResult = await _routerRepository
        .getFirewallPolicies()
        .then((value) => value.toFCNResult());
    int id;
    bool isExist;
    do {
      id = Random().nextInt(65535);
      isExist = List.from(fcnResult.response.results)
          .any((element) => element['id'] == '$id');
      Future.delayed(const Duration(milliseconds: 100));
    } while (isExist);
    return '$id';
  }

  String getProfileNameEncoded(String name) {
    return Utils.fullStringEncoded(name);
  }

  @override
  void onChange(Change<ProfilesState> change) {
    super.onChange(change);
    logger.i(
        'Profiles Cubit changed: ${change.currentState} -> ${change.nextState}');
  }
}
