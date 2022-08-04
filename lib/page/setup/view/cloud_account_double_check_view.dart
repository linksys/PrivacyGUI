import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CloudAccountDoubleCheckView extends StatelessWidget {
  const CloudAccountDoubleCheckView({
        Key? key,
        required this.onCreateAccount,
        required this.onSkip
      }) : super(key: key);

  final VoidCallback onCreateAccount;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).cloud_account_double_check_title
        ),
        content: Column(
          children: [
            BulletPoint(context,
                getAppLocalizations(context).add_cloud_account_bullet_1),
            BulletPoint(context,
                getAppLocalizations(context).add_cloud_account_bullet_2),
            BulletPoint(context,
                getAppLocalizations(context).add_cloud_account_bullet_3),
            BulletPoint(context,
                getAppLocalizations(context).add_cloud_account_bullet_4),
            BulletPoint(context,
                getAppLocalizations(context).add_cloud_account_bullet_5),
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(text: getAppLocalizations(context).create_account, onPress: onCreateAccount),
            const SizedBox(
              height: 12,
            ),
            SecondaryButton(text: getAppLocalizations(context).dont_want_cloud_account, onPress: onSkip,)
          ],
        )
      ),
    );
  }
}

Widget BulletPoint(BuildContext context, String title) => Row(
  children: [
    Image.asset('assets/images/icon_check_green.png'),
    const SizedBox(width: 12),
    Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .headline4
                ?.copyWith(color: Colors.white)))
  ],
);