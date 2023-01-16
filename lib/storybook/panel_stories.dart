part of 'storybook.dart';

Iterable<Story> panelStories() {
  bool testSwitchValue = true;
  return [
    Story(
      name: 'AppPanel/AppPanelWithSimpleTitle',
      description: 'A general panel with title-value widely used in app',
      builder: (context) => Column(
        children: [
          //TODO: Remove this template
          AppPanel(
            head: AppText.descriptionSub(
              'Label Title',
              color: AppTheme.of(context).colors.ctaPrimary,
            ),
            iconOne: Container(
              color: Colors.red,
              child: SizedBox(
                height: 24,
                width: 24,
              ),
            ),
            iconTwo: Container(
              color: Colors.green,
              child: SizedBox(
                height: 24,
                width: 24,
              ),
            ),
            description: 'This is a long long long long long long sentence',
            backgroundColorSet: const AppWidgetStateColorSet(
              inactive: Colors.blue,
              hovered: Colors.greenAccent,
              pressed: Colors.brown,
              disabled: Colors.purple,
            ),
            borderColorSet: const AppWidgetStateColorSet(
              inactive: Colors.green,
              hovered: Colors.yellow,
              pressed: Colors.pinkAccent,
              disabled: Colors.white,
            ),
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
  ];
}
