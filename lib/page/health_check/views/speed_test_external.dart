import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:linksys_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:linksys_app/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:linksys_app/util/url_helper/url_helper_web.dart';

class SpeedTestExternalView extends StatelessWidget {
  const SpeedTestExternalView({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).speedTestInternetToDevice,
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
                  child: SizedBox(
                    width: 224,
                    height: 56,
                    child: SvgPicture(
                      CustomTheme.of(context).images.internetToDevice,
                    ),
                  ),
                ),
                AppText.labelLarge(loc(context).speedTestExternalDesc),
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
                ResponsiveLayout.isLayoutBreakpoint(context)
                    ? _externalButtonsMobile(context)
                    : _externalButtonsDesktop(context),
                const AppGap.big(),
                Center(child: AppText.bodyMedium(loc(context).speedTestExternalOthers))
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _externalButtonsMobile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppFilledButton.fillWidth(
          loc(context).speedTestExternalCloudFlare,
          onTap: () {
            openUrl('https://speed.cloudflare.com/');
          },
        ),
        const AppGap.regular(),
        AppFilledButton.fillWidth(
          loc(context).speedTestExternalFast,
          onTap: () {
            openUrl('https://www.fast.com');
          },
        ),
      ],
    );
  }

  Widget _externalButtonsDesktop(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppFilledButton.fillWidth(
            loc(context).speedTestExternalCloudFlare,
            onTap: () {
              openUrl('https://speed.cloudflare.com/');
            },
          ),
        ),
        const AppGap.regular(),
        Expanded(
          child: AppFilledButton.fillWidth(
            loc(context).speedTestExternalFast,
            onTap: () {
              openUrl('https://www.fast.com');
            },
          ),
        ),
      ],
    );
  }
}
