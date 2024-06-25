import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SpeedTestSelectionView extends ConsumerWidget {
  const SpeedTestSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerType = ref.watch(connectivityProvider
        .select((value) => value.connectivityInfo.routerType));
    final isBehindRouter = routerType == RouterType.behindManaged ||
        BuildConfig.forceCommandType == ForceCommand.local;
    final isSpeedCheckSupported = ref
        .read(dashboardManagerProvider.notifier)
        .isHealthCheckModuleSupported('SpeedTest');
    return StyledAppPageView(
      title: loc(context).speedTest,
      child: AppBasicLayout(
          content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).speedTestDesc),
          const AppGap.large3(),
          Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _createInternetToRouterCard(context, isSpeedCheckSupported),
              _createInternetToDeviceCard(context, isBehindRouter),
            ]),
          )
        ],
      )),
    );
  }

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
