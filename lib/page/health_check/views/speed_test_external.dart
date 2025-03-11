import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';

class SpeedTestExternalView extends StatelessWidget {
  const SpeedTestExternalView({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).externalSpeedText,
      child: (context, constraints) => SizedBox(
        width: 6.col,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 0, vertical: Spacing.large5),
                child: SizedBox(
                  width: 224,
                  height: 56,
                  child: SvgPicture(
                    CustomTheme.of(context).images.internetToDevice,
                  ),
                ),
              ),
              AppText.labelLarge(loc(context).speedTestExternalDesc),
              const AppGap.large3(),
              AppBulletList(
                style: AppBulletStyle.number,
                itemSpacing: Spacing.large3,
                children: [
                  AppText.bodyMedium(loc(context).speedTestExternalStep1),
                  AppText.bodyMedium(loc(context).speedTestExternalStep2),
                  AppText.bodyMedium(loc(context).speedTestExternalStep3),
                ],
              ),
              ResponsiveLayout.isMobileLayout(context)
                  ? _externalButtonsMobile(context)
                  : _externalButtonsDesktop(context),
              const AppGap.large3(),
              AppText.bodyMedium(loc(context).speedTestExternalOthers)
            ],
          ),
        ),
      ),
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
        const AppGap.medium(),
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
        const AppGap.medium(),
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
