import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/buttons/button.dart';
import 'package:linksys_core/widgets/progress_bar/progress_bar.dart';
import 'package:linksys_core/widgets/toast/app_toast.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

Iterable<Story> toastStories() {
  return [
    Story(
      name: 'Toast/Toast',
      description: 'A custom toast widget used in app',
      builder: (context) => Column(
        children: const [
          AppToast.positive(text: 'Biometric sign on enabled',),
          AppGap.regular(),
          AppToast.negative(text: 'Biometric sign on enabled',),
        ],
      ),
    ),
    Story(
      name: 'Toast/Show Toast',
      description: 'A custom toast widget used in app',
      builder: (context) => Column(
        children: [
          AppPrimaryButton('Show Positive', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.of(context).colors.textBoxBox,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              content: AppToast.positive(text: 'Biometric sign on enabled',),
            ),);
          },),
          AppGap.regular(),
          AppPrimaryButton('Show Negative', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.of(context).colors.textBoxBox,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              content: AppToast.negative(text: 'Biometric sign on enabled',),
            ),);
          },),
        ],
      ),
    ),
  ];
}
