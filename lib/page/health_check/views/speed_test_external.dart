import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                      horizontal: Spacing.big, vertical: Spacing.extraBig),
                  child: Container(
                    constraints: BoxConstraints(minWidth: 144, maxWidth: 512),
                    child: SvgPicture(
                      CustomTheme.of(context).images.deviceToInternet,
                    ),
                  ),
                ),
                const AppText.bodyMedium('Let\'s get started'),
                const AppGap.big(),
                const AppBulletList(
                  style: AppBulletStyle.number,
                  itemSpacing: Spacing.big,
                  children: [
                    AppText.bodyMedium(
                        'Make sure you\'re connected to your Wi-Fi network and not using cellular data.'),
                    AppText.bodyMedium(
                        'Use a mobile device to check speeds at various areas of your home. Optional.'),
                    AppText.bodyMedium(
                        'See what speeds your device is getting at this location with a 3rd party service.'),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppOutlinedButton.fillWidth(
                      'Test with CloudFlare',
                      onTap: () {
                        openUrl('https://speed.cloudflare.com/');
                      },
                    ),
                    const AppGap.regular(),
                    AppOutlinedButton.fillWidth(
                      'Test with Fast.com',
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
