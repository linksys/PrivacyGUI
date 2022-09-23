import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/bloc/profiles/mock.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';

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
    required this.filterCategory,
    required this.rules,
    required super.profileId,
  }) : super(serviceCategory: PService.contentFilter);

  final bool isEnabled;
  final CFPresetCategory filterCategory;
  final List<CFFilterCategory> rules;

  ContentFilterData copyWith({
    bool? isEnabled,
    CFPresetCategory? filterCategory,
    List<CFFilterCategory>? rules,
    String? profileId,
  }) {
    return ContentFilterData(
      isEnabled: isEnabled ?? this.isEnabled,
      filterCategory: filterCategory ?? this.filterCategory,
      rules: rules ?? this.rules,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([isEnabled, filterCategory, rules]);
}

enum CFPresetCategory { child, teen, adult }

enum FilterStatus {
  allowed,
  someAllowed,
  notAllowed,
  force,
}

class CFPreset {
  const CFPreset({
    required this.category,
    required this.name,
    required this.description,
    required this.color,
    required this.filters,
  });

  const CFPreset.child()
      : category = CFPresetCategory.child,
        name = 'Child',
        description =
            'Child filter allows content appropriate for ages X to X. Customize sites or apps you want to block.',
        color = MoabColor.contentFilterChildPreset,
        filters = mockChildPresetRules;

  const CFPreset.teen()
      : category = CFPresetCategory.teen,
        name = 'Teen',
        description =
            'Pre-teen filter allows topics appropriate for ages X to X. Customize sites or apps you want to block.',
        color = MoabColor.contentFilterTeenPreset,
        filters = mockTeenPresetRules;

  const CFPreset.adult()
      : category = CFPresetCategory.adult,
        name = 'Adult',
        description =
            'Adult Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed. You can customize.',
        color = MoabColor.contentFilterAdultPreset,
        filters = mockAdultPresetRules;

  factory CFPreset.fromCategory(CFPresetCategory category) {
    if (category == CFPresetCategory.child) {
      return CFPreset.child();
    } else if (category == CFPresetCategory.teen) {
      return CFPreset.teen();
    } else if (category == CFPresetCategory.adult) {
      return CFPreset.adult();
    } else {
      throw Exception('Not support preset category!');
    }
  }

  CFPreset copyWith({
    CFPresetCategory? category,
    String? name,
    String? description,
    Color? color,
    List<CFFilterCategory>? filters,
  }) {
    return CFPreset(
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      filters: filters ?? this.filters,
    );
  }

  final CFPresetCategory category;
  final String name;
  final String description;
  final Color color;
  final List<CFFilterCategory> filters;
}

class CFFilterCategory {
  const CFFilterCategory({
    required this.name,
    required this.status,
    required this.description,
    required this.apps,
  });

  final String name;
  final FilterStatus status;
  final String description;
  final List<CFFilterApp> apps;

  CFFilterCategory copyWith({
    String? name,
    FilterStatus? status,
    String? description,
    List<CFFilterApp>? apps,
  }) {
    return CFFilterCategory(
      name: name ?? this.name,
      status: status ?? this.status,
      description: description ?? this.description,
      apps: apps ?? this.apps,
    );
  }

  getAppSummaryStatus() {
    if (apps.isEmpty) {
      return FilterStatus.notAllowed;
    }
    return apps.fold<FilterStatus>(
        apps[0].status == FilterStatus.force ? FilterStatus.notAllowed : apps[0].status,
            (value, element) => (value != FilterStatus.force && value != element.status) ? FilterStatus.someAllowed : value);
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
}

class CFFilterApp {
  const CFFilterApp(
      {required this.name,
      required this.category,
      this.icon,
      required this.status});

  final String name;
  final String category;
  final String? icon;
  final FilterStatus status;

  CFFilterApp copyWith(
      {String? name, String? category, String? icon, FilterStatus? status}) {
    return CFFilterApp(
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }
}
