import 'dart:core';
import 'dart:core';
import 'dart:core';
import 'dart:ui';

import 'package:linksys_moab/design/colors.dart';

enum CFPresetCategory { child, teen, adult }

enum FilterStatus {
  allowed,
  someAllowed,
  notAllowed,
  force,
}

class Profile {
  String imagePath;
  String name;

  Profile(this.imagePath, this.name);
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
        filters = _mockChildPresetRules;

  const CFPreset.teen()
      : category = CFPresetCategory.teen,
        name = 'Teen',
        description =
            'Pre-teen filter allows topics appropriate for ages X to X. Customize sites or apps you want to block.',
        color = MoabColor.contentFilterTeenPreset,
        filters = _mockTeenPresetRules;

  const CFPreset.adult()
      : category = CFPresetCategory.adult,
        name = 'Adult',
        description =
            'Adult Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed. You can customize.',
        color = MoabColor.contentFilterAdultPreset,
        filters = _mockAdultPresetRules;

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
}

class CFFilterApp {

  const CFFilterApp({required this.name, required this.category, this.icon, required this.status});

  final String name;
  final String category;
  final String? icon;
  final FilterStatus status;
}


const List<CFFilterCategory> _mockChildPresetRules = [
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
        CFFilterApp(name: 'Badoo', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(name: 'Tinder', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(name: 'OKcupid', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(name: 'Craigslist', category: '', status: FilterStatus.notAllowed),
        CFFilterApp(name: 'Reddit', category: '', status: FilterStatus.notAllowed),
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

const List<CFFilterCategory> _mockTeenPresetRules = [
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
      apps: []),
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
      name: 'Gaming',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Email',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
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
      name: 'Banking',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
];

const List<CFFilterCategory> _mockAdultPresetRules = [
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
      apps: []),
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
      name: 'Gaming',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
  CFFilterCategory(
      name: 'Email',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
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
      name: 'Banking',
      status: FilterStatus.allowed,
      description: '',
      apps: []),
];
