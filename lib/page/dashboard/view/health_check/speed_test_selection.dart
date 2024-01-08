import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SpeedTestSelectionView extends StatelessWidget {
  const SpeedTestSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: 'Speed Check',
      child: AppBasicLayout(
          content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium('There are two ways to check your speeds.'),
          const AppGap.big(),
          ResponsiveLayout.isMobile(context)
              ? Column(children: [
                  _createVerticalCard(context),
                  _createDeviceToInternetCard(context),
                ])
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _createVerticalCard(context)),
                    Expanded(child: _createDeviceToInternetCard(context)),
                  ],
                ),
        ],
      )),
    );
  }

  Widget _createVerticalCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: Container(
          constraints: BoxConstraints(minHeight: 240),
          padding: const EdgeInsets.all(Spacing.regular),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText.bodyLarge('Router to Internet'),
              const AppGap.regular(),
              const AppText.bodySmall(
                  'Measure the speeds you signed up for with your ISP.'),
              const AppGap.semiBig(),
              Center(
                  child: SvgPicture(
                CustomTheme.of(context).images.routerToInternet,
                width: 72,
                height: 24,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createDeviceToInternetCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: Container(
          constraints: BoxConstraints(minHeight: 240),
          padding: const EdgeInsets.all(Spacing.regular),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText.bodyLarge('Device to Internet'),
              const AppGap.regular(),
              const AppText.bodySmall(
                  'Measure the speeds your device is currently getting.'),
              const AppGap.semiBig(),
              Center(
                child: SvgPicture(
                  CustomTheme.of(context).images.deviceToInternet,
                  width: 72,
                  height: 24,
                ),
              ),
              const AppGap.regular(),
              const AppText.bodySmall(
                  'TIP This is useful when checking speeds on devices located in corners of your home.'),
            ],
          ),
        ),
      ),
    );
  }
}
