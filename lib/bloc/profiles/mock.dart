import 'dart:math';

import 'package:linksys_moab/bloc/profiles/state.dart';

final mockProfiles = [
  Profile(
    id: 'PROFILE_ID_0001',
    name: 'Eric',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [
      PService.contentFilter,
      PService.internetSchedule
    ],
    devices: [
      PDevice(name: 'iphone 20'),
      PDevice(name: 'Samsung Galaxy S87')
    ],
  ),
  Profile(
    id: 'PROFILE_ID_0002',
    name: 'Timmy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [],
  ),
  Profile(
    id: 'PROFILE_ID_0003',
    name: 'Mandy',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [PService.internetSchedule],
  ),
  Profile(
    id: 'PROFILE_ID_0004',
    name: 'Dad',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [
      PService.contentFilter,
    ],
  ),
  Profile(
    id: 'PROFILE_ID_0005',
    name: 'Peter',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [
      PService.contentFilter,
    ],
  ),
  Profile(
    id: 'PROFILE_ID_0006',
    name: 'Austin',
    icon: 'assets/images/img_profile_icon_${1 + Random().nextInt(3)}.png',
    enabledServices: const [
      PService.contentFilter,
      PService.internetSchedule
    ],
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

final mockContentFilterData = {
  'PROFILE_ID_0001': ContentFilterData(
    isEnabled: true,
    filterCategory: CFPresetCategory.teen,
    rules: mockTeenPresetRules,
    profileId: 'PROFILE_ID_0001',
  ),
};

const List<CFFilterCategory> mockChildPresetRules = [
  CFFilterCategory(
    name: 'Adult & sexual content',
    status: FilterStatus.force,
    description:
    'Mature content websites (18+ years and over) which present or display sexual acts with the intent to sexually arouse and excite.\n\n\nExamples: xvideos.com, xhamster.com, pornhub.com, xnxx.com',
    apps: [],
  ),
  CFFilterCategory(
      name: 'Criminal & violence',
      status: FilterStatus.force,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Mature topics',
      status: FilterStatus.force,
      description:
      'Mature category includes topics considered to be sensitive in nature such as:\n\nAbortion\nAdvocacy Organizations\nAlcohol\nAlternative Beliefs\nDating\nGambling\nLingerie and Swimsuit\nMarijuana\nSex Education\nSports Hunting and War Games\nTobacco\n\n\nExamples: Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      apps: [
        CFFilterApp(
            name: 'Badoo', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Tinder', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'OKcupid', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Craigslist', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Reddit', category: '', status: FilterStatus.notAllowed),
      ]),
  CFFilterCategory(
      name: 'Social media',
      status: FilterStatus.notAllowed,
      description:
      'A social networking site is a platform to build social networks or social relations among people who share similar interests, activities, backgrounds or real-life connections. A social network service consists of a representation of each user (often a profile), his or her social links, and a variety of additional services. Social network sites are web-based services that allow individuals to create a public profile, create a list of users with whom to share connections, and view and cross the connections within the system.\n\n\nExamples: facebook.com, twitter.com, weibo.com, vk.com',
      apps: []),
  CFFilterCategory(
      name: 'Chat & messaging',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Streaming',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Large file sharing',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Gaming',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Email',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Shopping',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'News & media',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Government & religion',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Banking',
      status: FilterStatus.notAllowed,
      description: '',
      apps: []),
];

const List<CFFilterCategory> mockTeenPresetRules = [
  CFFilterCategory(
      name: 'Adult & sexual content',
      status: FilterStatus.force,
      description:
      'Mature content websites (18+ years and over) which present or display sexual acts with the intent to sexually arouse and excite.\n\n\nExamples: xvideos.com, xhamster.com, pornhub.com, xnxx.com',
      apps: []),
  CFFilterCategory(
      name: 'Criminal & violence',
      status: FilterStatus.force,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Mature topics',
      status: FilterStatus.notAllowed,
      description:
      'Mature category includes topics considered to be sensitive in nature such as:\n\nAbortion\nAdvocacy Organizations\nAlcohol\nAlternative Beliefs\nDating\nGambling\nLingerie and Swimsuit\nMarijuana\nSex Education\nSports Hunting and War Games\nTobacco\n\n\nExamples: Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      apps: [
        CFFilterApp(
            name: 'Badoo', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Tinder', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'OKcupid', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Craigslist', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Reddit', category: '', status: FilterStatus.notAllowed),
      ]),
  CFFilterCategory(
      name: 'Social media',
      status: FilterStatus.allowed,
      description:
      'A social networking site is a platform to build social networks or social relations among people who share similar interests, activities, backgrounds or real-life connections. A social network service consists of a representation of each user (often a profile), his or her social links, and a variety of additional services. Social network sites are web-based services that allow individuals to create a public profile, create a list of users with whom to share connections, and view and cross the connections within the system.\n\n\nExamples: facebook.com, twitter.com, weibo.com, vk.com',
      apps: []),
  CFFilterCategory(
      name: 'Chat & messaging',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Streaming',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Large file sharing',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Gaming', status: FilterStatus.allowed, description: '', apps: []),
  CFFilterCategory(
      name: 'Email', status: FilterStatus.allowed, description: '', apps: []),
  CFFilterCategory(
      name: 'Shopping',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'News & media',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Government & religion',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Banking', status: FilterStatus.allowed, description: '', apps: []),
];

const List<CFFilterCategory> mockAdultPresetRules = [
  CFFilterCategory(
      name: 'Adult & sexual content',
      status: FilterStatus.allowed,
      description:
      'Mature content websites (18+ years and over) which present or display sexual acts with the intent to sexually arouse and excite.\n\n\nExamples: xvideos.com, xhamster.com, pornhub.com, xnxx.com',
      apps: []),
  CFFilterCategory(
      name: 'Criminal & violence',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Mature topics',
      status: FilterStatus.allowed,
      description:
      'Mature category includes topics considered to be sensitive in nature such as:\n\nAbortion\nAdvocacy Organizations\nAlcohol\nAlternative Beliefs\nDating\nGambling\nLingerie and Swimsuit\nMarijuana\nSex Education\nSports Hunting and War Games\nTobacco\n\n\nExamples: Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      apps: [
        CFFilterApp(
            name: 'Badoo', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Tinder', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'OKcupid', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Craigslist', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(
            name: 'Reddit', category: '', status: FilterStatus.notAllowed),
      ]),
  CFFilterCategory(
      name: 'Social media',
      status: FilterStatus.allowed,
      description:
      'A social networking site is a platform to build social networks or social relations among people who share similar interests, activities, backgrounds or real-life connections. A social network service consists of a representation of each user (often a profile), his or her social links, and a variety of additional services. Social network sites are web-based services that allow individuals to create a public profile, create a list of users with whom to share connections, and view and cross the connections within the system.\n\n\nExamples: facebook.com, twitter.com, weibo.com, vk.com',
      apps: []),
  CFFilterCategory(
      name: 'Chat & messaging',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Streaming',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Large file sharing',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Gaming', status: FilterStatus.allowed, description: '', apps: []),
  CFFilterCategory(
      name: 'Email', status: FilterStatus.allowed, description: '', apps: []),
  CFFilterCategory(
      name: 'Shopping',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'News & media',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Government & religion',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Banking', status: FilterStatus.allowed, description: '', apps: []),
];
