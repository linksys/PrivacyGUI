import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/util/in_app_browser.dart';

class LearnBatteryModemView extends StatelessWidget {
  const LearnBatteryModemView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).learn_battery_modem_title,
        ),
        content: Column(
          children: [
            Image.asset(
              'assets/images/battery_powered.png',
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(
              height: 28,
            ),
            SimpleTextButton(
              text: getAppLocalizations(context).learn_battery_modem_link,
              onPressed: () {
                MoabInAppBrowser.withDefaultOption().openUrlRequest(
                    urlRequest: URLRequest(
                        url: Uri.parse('https://www.linksys.com/us/support-article?articleNum=302834')
                    )
                );
              },
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}