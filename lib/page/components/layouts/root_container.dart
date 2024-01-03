import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_app/page/components/customs/no_network_bottom_modal.dart';
import 'package:linksys_app/page/components/layouts/desktop_layout.dart';
import 'package:linksys_app/page/components/layouts/mobile_layout.dart';
import 'package:linksys_app/page/components/styled/banner_provider.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/widgets/banner/banner_view.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

class AppRootContainer extends ConsumerStatefulWidget {
  final Widget? child;
  final LinksysRouteConfig? routeConfig;
  const AppRootContainer({
    super.key,
    this.child,
    this.routeConfig,
  });

  @override
  ConsumerState<AppRootContainer> createState() => _AppRootContainerState();
}

class _AppRootContainerState extends ConsumerState<AppRootContainer> {
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    logger.d('Root Container:: build: ${widget.routeConfig}');
    return LayoutBuilder(builder: ((context, constraints) {
      return Container(
        color: Theme.of(context).colorScheme.background,
        child: CompositedTransformTarget(
          link: _link,
          child: Stack(
            children: [
              _buildLayout(widget.child ?? const Center(), constraints),
              ..._handleConnectivity(ref),
              ..._handleBanner(ref),
              !showDebugPanel
                  ? const Center()
                  : CompositedTransformFollower(
                      link: _link,
                      targetAnchor: Alignment.topRight,
                      followerAnchor: Alignment.topRight,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: Utils.getTopSafeAreaPadding(context)),
                          child: const OverlayInfoView(),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    }));
  }

  Widget _buildLayout(Widget child, BoxConstraints constraints) {
    final isLoggedIn =
        (ref.watch(authProvider).value?.loginType ?? LoginType.none) !=
            LoginType.none;
    final onlyMainView = widget.routeConfig?.onlyMainView ?? false;
    final showSub = isLoggedIn && !onlyMainView;
    return ResponsiveLayout(
        desktop: DesktopLayout(
          sub: showSub ? const DashboardMenuView() : null,
          child: child,
        ),
        mobile: MobileLayout(child: child));
  }

  List<Widget> _handleBanner(WidgetRef ref) {
    final bannerInfo = ref.watch(bannerProvider);
    if (bannerInfo.isDiaplay) {
      return [
        AppBanner(
          style: bannerInfo.style,
          text: bannerInfo.text,
        )
      ];
    } else {
      return [];
    }
  }

  List<Widget> _handleConnectivity(WidgetRef ref) {
    final ignoreConnectivity =
        (widget.routeConfig?.ignoreConnectivityEvent ?? false) || kIsWeb;
    final ignoreCloudOffline =
        (widget.routeConfig?.ignoreCloudOfflineEvent ?? false) || kIsWeb;
    if (!ignoreConnectivity) {
      final connectivity = ref.watch(connectivityProvider
          .select((value) => (value.hasInternet, value.connectivityInfo.type)));
      final hasInternet = connectivity.$1;
      final connectivityType = connectivity.$2;
      if (!hasInternet || connectivityType == ConnectivityResult.none) {
        logger.i('No internet access: $hasInternet, $connectivityType');
        return [const NoInternetConnectionModal()];
      }
    }
    if (!ignoreCloudOffline) {
      final cloudOffline = ref.watch(connectivityProvider
          .select((value) => value.cloudAvailabilityInfo?.isCloudOk ?? false));
      if (!cloudOffline) {
        logger.i('cloud unavailable: $cloudOffline');
        return [const NoInternetConnectionModal()];
      }
    }
    return [];
  }
}
