part of '../storybook.dart';

Iterable<Story> toastStories() {
  return [
    Story(
      name: 'Toast/Toast',
      description: 'A custom toast widget used in app',
      builder: (context) => Column(
        children: const [
          AppToast.positive(
            text: 'Biometric sign on enabled',
          ),
          AppGap.regular(),
          AppToast.negative(
            text: 'Biometric sign on enabled',
          ),
        ],
      ),
    ),
    Story(
      name: 'Toast/Show Toast',
      description: 'A custom toast widget used in app',
      builder: (context) => Column(
        children: [
          AppPrimaryButton(
            'Show Positive',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                AppToastHelp.positiveToast(context,
                    text: 'Biometric sign on enabled'),
              );
            },
          ),
          const AppGap.regular(),
          AppPrimaryButton(
            'Show Negative',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                AppToastHelp.negativeToast(context,
                    text: 'Biometric sign on enabled'),
              );
            },
          ),
        ],
      ),
    ),
  ];
}
