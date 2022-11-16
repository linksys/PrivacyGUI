import 'package:equatable/equatable.dart';
import 'secure_profile.dart';

enum PService {
  contentFilter,
  internetSchedule,
  all,
}

enum CFSecureProfileType {
  child, teen, adult
}

enum FilterStatus {
  allowed,
  someAllowed,
  notAllowed,
  force,
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

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'secureProfile': secureProfile.toJson(),
    'profileId': profileId,
  };

  factory ContentFilterData.fromJson(Map<String, dynamic> json) => ContentFilterData(
    isEnabled: json['isEnabled'],
    secureProfile: CFSecureProfile.fromJson(json['secureProfile']),
    profileId: json['profileId'],
  );

  @override
  List<Object?> get props => super.props..addAll([isEnabled, secureProfile]);
}