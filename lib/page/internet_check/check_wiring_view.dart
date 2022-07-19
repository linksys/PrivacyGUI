import 'package:flutter/material.dart';
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
        header: const BasicHeader(
          title: 'We’re having trouble finding an internet connection. Let’s check your wiring.',
        ),
        content: Column(
          children: [
            Image.asset('assets/images/check_wiring.png'),
            const SizedBox(
              height: 40,
            ),
            Text(
              'Make sure the internet cord from your wall is connected to your modem.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                color: Theme.of(context).colorScheme.tertiary
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Check the ethernet cable connecting your modem to your parent router. Any port on the modem should work. If your router has a port labeled internet, use that one.',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary
                ),
              ),
            ),
            Text(
              'Make sure all wires are firmly snapped into place.',
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