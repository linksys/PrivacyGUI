import 'package:linksys_moab/model/profile_service_data.dart';

final mockInternetScheduleData = {
  'PROFILE_ID_0001': InternetScheduleData(dateTimeLimitRule: [
    const DateTimeLimitRule(
      isEnabled: true,
      weeklySet: [
        true,
        true,
        true,
        true,
        true,
        false,
        false,
      ],
      timeInSeconds: 14400,
    ),
    const DateTimeLimitRule(
      isEnabled: true,
      weeklySet: [
        true,
        false,
        false,
        false,
        false,
        true,
        true,
      ],
      timeInSeconds: 28800,
    ),
  ], scheduledPauseRule: [
    const ScheduledPausedRule(
      isEnabled: true,
      weeklySet: [
        true,
        false,
        false,
        false,
        false,
        true,
        true,
      ],
      pauseStartTime: 8 * 3600,
      pauseEndTime: 12 * 3600,
      isAllDay: false,
    ),
    const ScheduledPausedRule(
      isEnabled: true,
      weeklySet: [
        true,
        false,
        true,
        true,
        true,
        true,
        true,
      ],
      pauseStartTime: 22 * 3600,
      pauseEndTime: 10 * 3600,
      isAllDay: false,
    ),
    const ScheduledPausedRule(
      isEnabled: true,
      weeklySet: [
        true,
        false,
        true,
        false,
        false,
        true,
        true,
      ],
      pauseStartTime: 0,
      pauseEndTime: 0,
      isAllDay: true,
    ),
  ], profileId: 'PROFILE_ID_0001'),
};
