import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class CheckWiringView extends StatelessWidget {
  const CheckWiringView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).check_wiring_title,
        ),
        content: Column(
          children: [
            Image.asset('assets/images/check_wiring.png'),
            const SizedBox(
              height: 40,
            ),
            Text(
              getAppLocalizations(context).check_wiring_description_1,
              style: Theme.of(context).textTheme.headline3?.copyWith(
                color: Theme.of(context).colorScheme.tertiary
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                getAppLocalizations(context).check_wiring_description_2,
                style: Theme.of(context).textTheme.headline3?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary
                ),
              ),
            ),
            Text(
              getAppLocalizations(context).check_wiring_description_3,
              style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: PrimaryButton(
          text: 'Check again',
          onPress: () {
            //TODO: Go to next page
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}