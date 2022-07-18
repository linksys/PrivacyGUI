import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class LearnBatteryModemView extends StatelessWidget {
  const LearnBatteryModemView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'You may have a battery-powered modem that requires a different way to reset',
        ),
        content: Column(
          children: [
            //TODO: Add the central picture
            const SizedBox(
              height: 16,
            ),
            SimpleTextButton(
              text: 'Learn more about restarting battery-powered modems',
              onPressed: () {
                //TODO: Go to next page
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}