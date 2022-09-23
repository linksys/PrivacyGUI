import 'dart:math';

import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/profile_service_data.dart';

final mockProfiles = [
  GroupProfile(
    id: 'PROFILE_ID_0001',
    name: 'Eric',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    devices: [
      PDevice(name: 'iphone 20'),
      PDevice(name: 'Samsung Galaxy S87')
    ],
  ),
  GroupProfile(
    id: 'PROFILE_ID_0002',
    name: 'Timmy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  GroupProfile(
    id: 'PROFILE_ID_0003',
    name: 'Mandy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  GroupProfile(
    id: 'PROFILE_ID_0004',
    name: 'Dad',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  GroupProfile(
    id: 'PROFILE_ID_0005',
    name: 'Peter',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
  GroupProfile(
    id: 'PROFILE_ID_0006',
    name: 'Austin',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
  ),
];

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
