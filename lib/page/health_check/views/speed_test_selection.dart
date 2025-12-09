import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

/// A view that allows the user to select between two types of speed tests:
/// 1. Internet to Router: An internal test run by the router itself.
/// 2. Internet to Device: A test that links to external speed test websites.
class SpeedTestSelectionView extends ConsumerWidget {
  const SpeedTestSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerType = ref.watch(connectivityProvider
        .select((value) => value.connectivityInfo.routerType));
    // The "Internet to Device" option is only available when the user is behind the router.
    final isBehindRouter = routerType == RouterType.behindManaged ||
        BuildConfig.forceCommandType == ForceCommand.local;
    // The internal speed test is only supported if the router's firmware reports it.
    final isSpeedCheckSupported =
        ref.watch(healthCheckProvider.select((s) => s.isSpeedTestModuleSupported));

    return StyledAppPageView.withSliver(
      title: loc(context).speedTest,
      child: (context, constraints) => SizedBox(
        width: 6.col,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).speedTestDesc),
            const AppGap.large3(),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _createInternetToRouterCard(context, isSpeedCheckSupported),
              _createInternetToDeviceCard(context, isBehindRouter),
            ])
          ],
        ),
      ),
    );
  }

  /// Creates the card for the "Internet to Router" speed test option.
  ///
  /// This option is disabled if the router does not support the speed check feature.
  Widget _createInternetToRouterCard(
      BuildContext context, bool isSpeedCheckSupported) {
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
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 164),
            padding: const EdgeInsets.all(Spacing.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(loc(context).speedTestInternetToRouter),
                const AppGap.medium(),
                AppText.bodySmall(loc(context).speedTestInternetToRouterDesc),
                const AppGap.large3(),
                SvgPicture(
                  CustomTheme.of(context).images.internetToRouter,
                  semanticsLabel: 'internet To Router image',
                  width: 192,
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Creates the card for the "Internet to Device" speed test option.
  ///
  /// This option is disabled if the user is not connected directly behind the router.
  Widget _createInternetToDeviceCard(
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
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 164),
            padding: const EdgeInsets.all(Spacing.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(loc(context).speedTestInternetToDevice),
                const AppGap.medium(),
                AppText.bodySmall(loc(context).speedTestInternetToDeviceDesc),
                const AppGap.large3(),
                SvgPicture(
                  CustomTheme.of(context).images.internetToDevice,
                  width: 192,
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
