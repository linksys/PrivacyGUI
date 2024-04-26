import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/util/in_app_browser.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:linksys_app/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:linksys_app/util/url_helper/url_helper_web.dart';

class SpeedTestExternalView extends StatelessWidget {
  const SpeedTestExternalView({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Speed Check',
      child: AppBasicLayout(
          content: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0, vertical: Spacing.extraBig),
                  child: Container(
                    width: 224,
                    height: 56,
                    child: SvgPicture(
                      CustomTheme.of(context).images.internetToDevice,
                    ),
                  ),
                ),
                AppText.bodyMedium(loc(context).speedTestExternalDesc),
                const AppGap.big(),
                AppBulletList(
                  style: AppBulletStyle.number,
                  itemSpacing: Spacing.big,
                  children: [
                    AppText.bodyMedium(loc(context).speedTestExternalStep1),
                    AppText.bodyMedium(loc(context).speedTestExternalStep2),
                    AppText.bodyMedium(loc(context).speedTestExternalStep3),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppOutlinedButton.fillWidth(
                      loc(context).speedTestExternalCloudFlare,
                      onTap: () {
                        openUrl('https://speed.cloudflare.com/');
                      },
                    ),
                    const AppGap.regular(),
                    AppOutlinedButton.fillWidth(
                      loc(context).speedTestExternalFast,
                      onTap: () {
                        openUrl('https://www.fast.com');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
