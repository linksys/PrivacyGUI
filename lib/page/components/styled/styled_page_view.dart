import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/customs/no_network_bottom_modal.dart';
import 'package:linksys_app/page/components/styled/banner_info.dart';
import 'package:linksys_app/page/components/styled/banner_provider.dart';
import 'package:linksys_widgets/widgets/banner/banner_view.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';

import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

import 'consts.dart';

class StyledAppPageView extends ConsumerWidget {
  static const double kDefaultToolbarHeight = 80;
  final String? title;
  final Widget? child;
  final double toolbarHeight;
  final VoidCallback? onBackTap;
  final StyledBackState backState;
  final List<Widget>? actions;
  final AppEdgeInsets? padding;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final bool? scrollable;
  final AppBarStyle appBarStyle;
  final bool handleNoConnection;
  final bool handleBanner;

  const StyledAppPageView({
    super.key,
    this.title,
    this.padding,
    this.scrollable,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.backState = StyledBackState.enabled,
    this.actions,
    this.child,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.appBarStyle = AppBarStyle.back,
    this.handleNoConnection = false,
    this.handleBanner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        AppPageView(
          appBar: _buildAppBar(context, ref),
          padding: padding,
          scrollable: scrollable,
          bottomSheet: bottomSheet,
          bottomNavigationBar: bottomNavigationBar,
          child: child,
        ),
        ..._handleBanner(ref),
        ..._handleConnectivity(ref),
      ],
    );
  }

  bool isBackEnabled() => backState == StyledBackState.enabled;

  LinksysAppBar? _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = this.title;
    switch (appBarStyle) {
      case AppBarStyle.back:
        return LinksysAppBar.withBack(
          context: context,
          title: title == null ? null : AppText.titleLarge(title),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
          trailing: actions,
        );
      case AppBarStyle.close:
        return LinksysAppBar.withClose(
          context: context,
          title: title == null ? null : AppText.titleLarge(title),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
        );
      case AppBarStyle.none:
        return null;
    }
  }

  List<Widget> _handleBanner(WidgetRef ref) {
    if (!handleBanner) {
      return [];
    }
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
    if (!kIsWeb && handleNoConnection) {
      final connectivity = ref.watch(connectivityProvider);
      if (!connectivity.hasInternet ||
          connectivity.connectivityInfo.type == ConnectivityResult.none) {
        logger.i(
            'No internet access: ${connectivity.hasInternet}, ${connectivity.connectivityInfo.type}');
        return [const NoInternetConnectionModal()];
      } else if (!(connectivity.cloudAvailabilityInfo?.isCloudOk ?? false)) {
        logger.i(
            'cloud unavailable: ${connectivity.cloudAvailabilityInfo?.isCloudOk}');
        return [const NoInternetConnectionModal()];
      }
    }
    return [];
  }
}
