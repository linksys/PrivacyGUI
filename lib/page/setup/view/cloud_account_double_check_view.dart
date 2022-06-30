import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
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
          title: AppLocalizations.of(context)!.cloud_account_double_check_title
        ),
        content: Column(
          children: [
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_1),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_2),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_3),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_4),
            BulletPoint(context,
                AppLocalizations.of(context)!.add_cloud_account_bullet_5),
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(text: AppLocalizations.of(context)!.create_account, onPress: onCreateAccount),
            const SizedBox(
              height: 12,
            ),
            SecondaryButton(text: AppLocalizations.of(context)!.dont_want_cloud_account, onPress: onSkip,)
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