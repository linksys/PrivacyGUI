import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/bloc/profiles/mock.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/security/app_signature.dart';
import 'package:linksys_moab/security/cloud_preset.dart';
import 'package:linksys_moab/security/web_filter.dart';

class ProfilesState extends Equatable {
  final Map<String, Profile> profiles;
  final Profile? createdProfile;
  final Profile? selectedProfile;

  const ProfilesState(
      {this.profiles = const {}, this.createdProfile, this.selectedProfile});

  List<Profile> get profileList => List.from(profiles.values);

  ProfilesState copyWith(
      {Map<String, Profile>? profiles,
      Profile? createdProfile,
      Profile? selectedProfile}) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      createdProfile: createdProfile ?? this.createdProfile,
      selectedProfile: selectedProfile ?? this.selectedProfile,
    );
  }

  ProfilesState addOrUpdateProfile(Profile profile) {
    profiles[profile.id] = profile;
    if (selectedProfile?.id == profile.id) {
      return copyWith(profiles: profiles, selectedProfile: profile);
    }
    return copyWith(profiles: profiles);
  }

  @override
  List<Object?> get props =>
      [profiles, createdProfile, selectedProfile, profiles.entries];
}

class Profile extends Equatable {
  final String id;
  final String icon;
  final String name;

  final List<PDevice> devices;
  final List<PService> enabledServices;
  final Map<PService, MoabServiceData> serviceDetails;

  const Profile({
    required this.id,
    required this.icon,
    required this.name,
    this.devices = const [],
    this.enabledServices = const [],
    this.serviceDetails = const {},
  });

  Profile copyWith({
    String? id,
    String? name,
    String? icon,
    List<PDevice>? devices,
    List<PService>? enabledServices,
    Map<PService, MoabServiceData>? serviceDetails,
  }) {
    return Profile(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      devices: devices ?? this.devices,
      enabledServices: enabledServices ?? this.enabledServices,
      serviceDetails: serviceDetails ?? this.serviceDetails,
    );
  }

  bool hasServiceDetail(PService category) {
    return serviceDetails.containsKey(category);
  }

  // TODO move
  String serviceOverallStatus(BuildContext context, PService category) {
    if (category == PService.internetSchedule) {
      bool hasData = serviceDetails.containsKey(category);
      bool isEnable = false;
      if (hasData) {
        final details = serviceDetails[category] as InternetScheduleData;
        hasData = details.scheduledPauseRule.isNotEmpty |
            details.dateTimeLimitRule.isNotEmpty;
        isEnable = hasData &
            (details.dateTimeLimitRule.any((element) => element.isEnabled) |
                details.scheduledPauseRule.any((element) => element.isEnabled));
      }
      return hasData
          ? isEnable
              ? getAppLocalizations(context).on
              : getAppLocalizations(context).off
          : getAppLocalizations(context).none;
    } else if (category == PService.contentFilter) {
      bool hasData = serviceDetails.containsKey(category);
      bool isEnable = false;
      if (hasData) {
        final details = serviceDetails[category] as ContentFilterData;
        isEnable = hasData & details.isEnabled;
      }
      return hasData
          ? isEnable
              ? getAppLocalizations(context).on
              : getAppLocalizations(context).off
          : getAppLocalizations(context).no_filters;
    }
    return '';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        devices,
        enabledServices,
        serviceDetails,
        serviceDetails.entries
      ];
}

// TODO rename
class PDevice extends Equatable {
  const PDevice({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

enum PService {
  contentFilter,
  internetSchedule,
  all,
}

abstract class MoabServiceData extends Equatable {
  const MoabServiceData(
      {required this.serviceCategory, required this.profileId});

  final PService serviceCategory;
  final String profileId;

  @override
  List<Object?> get props => [serviceCategory, profileId];
}

class InternetScheduleData extends MoabServiceData {
  const InternetScheduleData({
    required this.dateTimeLimitRule,
    required this.scheduledPauseRule,
    required super.profileId,
  }) : super(serviceCategory: PService.internetSchedule);
  final List<DateTimeLimitRule> dateTimeLimitRule;
  final List<ScheduledPausedRule> scheduledPauseRule;

  InternetScheduleData copyWith({
    String? profileId,
    List<DateTimeLimitRule>? dateTimeLimitRule,
    List<ScheduledPausedRule>? scheduledPauseRule,
  }) {
    return InternetScheduleData(
      dateTimeLimitRule: dateTimeLimitRule ?? this.dateTimeLimitRule,
      scheduledPauseRule: scheduledPauseRule ?? this.scheduledPauseRule,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([dateTimeLimitRule, scheduledPauseRule]);
}

abstract class InternetScheduleRule extends Equatable {
  const InternetScheduleRule(
      {required this.isEnabled, required this.weeklySet});

  final bool isEnabled;
  final List<bool> weeklySet;

  @override
  List<Object?> get props => [isEnabled, weeklySet];
}

class DateTimeLimitRule extends InternetScheduleRule {
  const DateTimeLimitRule({
    required super.isEnabled,
    required super.weeklySet,
    required this.timeInSeconds,
  });

  factory DateTimeLimitRule.empty() {
    return DateTimeLimitRule(
        isEnabled: true, weeklySet: List.filled(7, false), timeInSeconds: 0);
  }

  final int timeInSeconds;

  DateTimeLimitRule copyWith({
    bool? isEnabled,
    List<bool>? weeklySet,
    int? timeInSeconds,
  }) {
    return DateTimeLimitRule(
      isEnabled: isEnabled ?? this.isEnabled,
      weeklySet: weeklySet ?? this.weeklySet,
      timeInSeconds: timeInSeconds ?? this.timeInSeconds,
    );
  }

  @override
  List<Object?> get props => super.props..addAll([timeInSeconds]);
}

class ScheduledPausedRule extends InternetScheduleRule {
  const ScheduledPausedRule({
    required super.isEnabled,
    required super.weeklySet,
    required this.pauseStartTime,
    required this.pauseEndTime,
    this.isAllDay = true,
  });

  factory ScheduledPausedRule.empty() {
    return ScheduledPausedRule(
        isEnabled: true,
        weeklySet: List.filled(7, false),
        pauseStartTime: 0,
        pauseEndTime: 0);
  }

  final int pauseStartTime;
  final int pauseEndTime;
  final bool isAllDay;

  ScheduledPausedRule copyWith({
    bool? isEnabled,
    List<bool>? weeklySet,
    int? pauseStartTime,
    int? pauseEndTime,
    bool? isAllDay,
  }) {
    return ScheduledPausedRule(
      isEnabled: isEnabled ?? this.isEnabled,
      weeklySet: weeklySet ?? this.weeklySet,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
      pauseEndTime: pauseEndTime ?? this.pauseEndTime,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([pauseStartTime, pauseEndTime, isAllDay]);
}

class ContentFilterData extends MoabServiceData {
  const ContentFilterData({
    required this.isEnabled,
    required this.secureProfile,
    required super.profileId,
  }) : super(serviceCategory: PService.contentFilter);

  final bool isEnabled;
  final CFSecureProfile secureProfile;

  ContentFilterData copyWith({
    bool? isEnabled,
    CFSecureProfile? secureProfile,
    String? profileId,
  }) {
    return ContentFilterData(
      isEnabled: isEnabled ?? this.isEnabled,
      secureProfile: secureProfile ?? this.secureProfile,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  List<Object?> get props => super.props..addAll([isEnabled, secureProfile]);
}

enum CFSecureProfileType { child, teen, adult }

enum FilterStatus {
  allowed,
  someAllowed,
  notAllowed,
  force,
}

class CFSecureProfile extends Equatable {
  const CFSecureProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.securityCategories,
  });

  CFSecureProfile copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    List<CFSecureCategory>? securityCategories,
  }) {
    return CFSecureProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      securityCategories: securityCategories ?? this.securityCategories,
    );
  }

  final String id;
  final String name;
  final String description;
  final List<CFSecureCategory> securityCategories;

  @override
  List<Object?> get props => [id, name, description, securityCategories];
}

class CFSecureCategory extends Equatable {
  const CFSecureCategory({
    required this.name,
    required this.id,
    required this.status,
    required this.description,
    required this.webFilters,
    required this.apps,
  });

  final String name;
  final String id;
  final FilterStatus status;
  final String description;
  final CFWebFilters webFilters;
  final List<CFAppSignature> apps;

  CFSecureCategory copyWith({
    String? name,
    String? id,
    FilterStatus? status,
    String? description,
    CFWebFilters? webFilters,
    List<CFAppSignature>? apps,
  }) {
    return CFSecureCategory(
      name: name ?? this.name,
      id: id ?? this.id,
      status: status ?? this.status,
      description: description ?? this.description,
      webFilters: webFilters ?? this.webFilters,
      apps: apps ?? this.apps,
    );
  }

  static FilterStatus switchStatus(FilterStatus current) {
    if (current == FilterStatus.allowed) {
      return FilterStatus.notAllowed;
    } else if (current == FilterStatus.notAllowed) {
      return FilterStatus.allowed;
    } else {
      return current;
    }
  }

  static FilterStatus mapStatus(String status) {
    if (status == 'Block') {
      return FilterStatus.force;
    } else if (status == 'Allow') {
      return FilterStatus.allowed;
    } else if (status == 'Not Allow') {
      // TODO TBD
      return FilterStatus.notAllowed;
    } else {
      return FilterStatus.notAllowed;
    }
  }

  @override
  List<Object?> get props => [name, id, status, description, webFilters, apps];
}

class CFWebFilters extends Equatable {
  const CFWebFilters({
    required this.status,
    required this.webFilters,
  });

  final FilterStatus status;
  final List<WebFilter> webFilters;

  CFWebFilters copyWith({FilterStatus? status, List<WebFilter>? webFilters}) {
    return CFWebFilters(
      status: status ?? this.status,
      webFilters: webFilters ?? this.webFilters,
    );
  }

  @override
  List<Object?> get props => [status, webFilters];
}

class CFAppSignature extends Equatable {
  const CFAppSignature({
    required this.name,
    required this.category,
    this.icon = '0',
    required this.status,
    this.raw = const [],
  });

  final String name;
  final String category;
  final String icon;
  final FilterStatus status;
  final List<AppSignature> raw;

  CFAppSignature copyWith({
    String? name,
    String? category,
    String? icon,
    FilterStatus? status,
    List<AppSignature>? raw,
  }) {
    return CFAppSignature(
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      raw: raw ?? this.raw,
    );
  }

  @override
  List<Object?> get props => [name, category, icon, status, raw];
}
