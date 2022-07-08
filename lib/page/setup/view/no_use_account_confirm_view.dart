import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/route/model/model.dart';

class NoUseAccountConfirmView extends StatelessWidget {
  const NoUseAccountConfirmView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> tips = [
      'Backup and restore your router settings',
      'World class security from Fortinet',
      'User profiles & parental controls',
      'Remote access',
      'Faster, tailored customer support',
    ];

    return BasePageView(
      child: BasicLayout(
        content: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: TitleText(text: 'Are you sure? Your router gets a lot smarter with a cloud account'),
            ),
            Column(
              children: List.generate(tips.length, (index) {
                return Row(
                  children: [
                    Image.asset('assets/images/icon_check_green.png'),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      tips[index],
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Create account',
              onPress: () {
                NavigationCubit.of(context).pop();
              },
            ),
            const SizedBox(
              height: 24,
            ),
            SecondaryButton(
              text: 'I do not want an account',
              onPress: () {
                NavigationCubit.of(context).push(CreateAdminPasswordPath()..args = {});
              },
            )
          ],
        ),
      ),
    );
  }
}
