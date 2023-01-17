part of '../storybook.dart';

Iterable<Story> panelStories() {
  bool testSwitchValue = true;
  return [
    Story(
      name: 'AppPanel/AppPanelWithSimpleTitle',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          const AppPanelWithSimpleTitle(
            title: 'NETWORK',
            titleColorSet: AppWidgetStateColorSet(
              inactive: ConstantColors.secondaryCyberPurple,
              hovered: ConstantColors.secondaryCyberPurple,
              pressed: ConstantColors.secondaryCyberPurple,
              disabled: ConstantColors.secondaryCyberPurple,
            ),
          ),
          const AppPanelWithSimpleTitle(
            title: 'Title',
          ),
          AppPanelWithSimpleTitle(
            title: 'Title',
            onTap: () {},
          ),
          const AppPanelWithSimpleTitle(
            title: 'NETWORK',
            titleColorSet: AppWidgetStateColorSet(
              inactive: ConstantColors.secondaryCyberPurple,
              hovered: ConstantColors.secondaryCyberPurple,
              pressed: ConstantColors.secondaryCyberPurple,
              disabled: ConstantColors.secondaryCyberPurple,
            ),
            description: 'Description content',
          ),
          const AppPanelWithSimpleTitle(
            title: 'Title',
            description: 'Description content',
          ),
          AppPanelWithSimpleTitle(
            title: 'Title',
            description: 'Description content',
            onTap: () {},
          ),
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppPanelWithInfo',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          const AppPanelWithInfo(
            title: 'Title',
            infoText: 'information',
          ),
          const AppPanelWithInfo(
            title: 'Title',
            infoText: 'information',
            description: 'Here is a description text',
          ),
          AppPanelWithInfo(
            title: 'Title',
            infoText: 'information',
            description: 'Here is a description text',
            onTap: () {},
          ),
          AppPanelWithInfo(
            title: 'Title',
            infoText: 'On',
            infoTextColor: AppTheme.of(context).colors.textBoxApproved,
            onTap: () {},
          ),
          AppPanelWithInfo(
            title: 'Title',
            infoText: 'Failed',
            infoTextColor: AppTheme.of(context).colors.textBoxTextAlert,
            description: 'Here is a detailed error description text',
          ),
        ],
      )
    ),
    Story(
        name: 'AppPanel/AppPanelWithValueCheck',
        description: 'A general panel with title-value widely used in app',
        builder: (context) => Column(
          children: [
            const AppPanelWithValueCheck(
              title: 'Title',
              valueText: 'Status',
            ),
            const AppPanelWithValueCheck(
              title: 'Title',
              valueText: 'Status',
              isChecked: true,
            ),
            AppPanelWithValueCheck(
              title: 'Title',
              valueText: 'Status',
              valueTextColor: AppTheme.of(context).colors.ctaSecondary,
              isChecked: true,
            ),
          ],
        )
    ),
    Story(
      name: 'AppPanel/AppPanelWithSwitch',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppPanelWithSwitch(
            title: 'Title',
            value: testSwitchValue,
            onChangedEvent: (value) {},
          ),
          AppPanelWithSwitch(
            title: 'Title',
            value: testSwitchValue,
            description: 'Here is a description text',
            onChangedEvent: (value) {},
          ),
          AppPanelWithSwitch(
            title: 'Title',
            value: testSwitchValue,
            onChangedEvent: (value) {},
            onInfoEvent: () {},
          ),
          AppPanelWithSwitch(
            title: 'MeetandGreetSingles',
            description: 'Mature topics',
            image: AppTheme.of(context).images.brandTinder,
            value: testSwitchValue,
            onChangedEvent: (value) {},
          ),
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppPanelWithTimeline',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppPanelWithTimeline(
            title: 'MeetandGreetSingles',
            description: 'Mature topics',
            time: '11:20 pm',
            profileName: 'Timmy',
            brandImage: AppTheme.of(context).images.brandTinder,
            profileImage: AppTheme.of(context).images.defaultAvatar1,
          ),
          AppPanelWithTimeline(
            title: 'MeetandGreetSingles',
            description: 'Mature topics',
            time: '11:20 pm',
            profileName: 'Timmy',
            profileImage: AppTheme.of(context).images.defaultAvatar7,
          ),
          const AppPanelWithTimeline(
            title: 'MeetandGreetSingles',
            description: 'Mature topics',
            time: '11:20 pm',
            profileName: 'Timmy',
          ),
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppDevicePanel.normal',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppDevicePanel.normal(
            title: 'Google Pixel',
            place: 'Living Room node',
            frequency: '2.4 GHz',
            deviceImage: AppTheme.of(context).images.deviceSmartPhone,
            signalImage: AppTheme.of(context).images.signalExcellent,
          )
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppDevicePanel.speed',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppDevicePanel.speed(
            title: 'Macbook',
            place: 'Living Room node',
            frequency: '5 GHz',
            deviceImage: AppTheme.of(context).images.deviceLaptop,
            signalImage: AppTheme.of(context).images.signalGood,
            upload: 12,
            download: 0.4,
          )
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppDevicePanel.bandwidth',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppDevicePanel.bandwidth(
            title: 'Google Pixel',
            deviceImage: AppTheme.of(context).images.deviceSmartPhone,
            bandwidth: 345,
          )
        ],
      ),
    ),
    Story(
      name: 'AppPanel/AppDevicePanel.offline',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          AppDevicePanel.offline(
            title: 'Google Pixel',
            deviceImage: AppTheme.of(context).images.deviceSmartPhone,
          )
        ],
      ),
    ),
  ];
}
