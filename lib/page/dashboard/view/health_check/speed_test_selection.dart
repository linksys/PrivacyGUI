import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SpeedTestSelectionView extends ConsumerWidget {
  const SpeedTestSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerType = ref.watch(connectivityProvider
        .select((value) => value.connectivityInfo.routerType));
    final isBehindRouter = routerType == RouterType.behindManaged;
    final isSpeedCheckSupported = ref
        .read(dashboardManagerProvider.notifier)
        .isHealthCheckModuleSupported('SpeedTest');
    return StyledAppPageView(
      title: 'Speed Check',
      child: AppBasicLayout(
          content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.bodyMedium('There are two ways to check your speeds.'),
          const AppGap.big(),
          ResponsiveLayout.isMobile(context)
              ? Column(children: [
                  _createVerticalCard(context, isSpeedCheckSupported),
                  _createDeviceToInternetCard(context, isBehindRouter),
                ])
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: _createVerticalCard(
                            context, isSpeedCheckSupported)),
                    Expanded(
                        child: _createDeviceToInternetCard(
                            context, isBehindRouter)),
                  ],
                ),
        ],
      )),
    );
  }

  Widget _createVerticalCard(BuildContext context, bool isSpeedCheckSupported) {
    return Opacity(
      opacity: isSpeedCheckSupported ? 1 : 0.6,
      child: Card(
        child: InkWell(
          onTap: isSpeedCheckSupported
              ? () {
                  context.pushNamed(RouteNamed.dashboardSpeedTest);
                }
              : null,
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
      ),
    );
  }

  Widget _createDeviceToInternetCard(
      BuildContext context, bool isBehindManaged) {
    return Opacity(
      opacity: isBehindManaged ? 1 : 0.6,
      child: Card(
        child: InkWell(
          onTap: isBehindManaged
              ? () {
                  context.pushNamed(RouteNamed.speedTestExternal);
                }
              : null,
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
      ),
    );
  }
}
