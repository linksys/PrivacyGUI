import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/provider/connectivity/connectivity_state.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/core/http/linksys_http_client.dart';
import 'package:linksys_moab/core/cloud/model/error_response.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_bottom_tab_container.dart';
import 'package:linksys_moab/core/jnap/providers/side_effect_provider.dart';
import 'package:linksys_moab/route/linksys_page.dart';
import 'package:linksys_moab/route/model/_model.dart';

import 'package:linksys_moab/util/analytics.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:linksys_widgets/theme/responsive_theme.dart';
import 'package:universal_link_plugin/universal_link_plugin.dart';

import '../page/dashboard/view/_view.dart';
import 'navigations_notifier.dart';

final routerDelegateProvider = Provider((ref) => LinksysRouterDelegate(ref));

class LinksysRouterDelegate extends RouterDelegate<List<BasePath>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<BasePath>> {
  LinksysRouterDelegate(Ref ref) : navigatorKey = GlobalKey() {
    _ref = ref;
    final navigationSubscription =
        _ref.listen(navigationsProvider, (_, __) => notifyListeners());
    final sideEffectSubscription =
        _ref.listen(sideEffectProvider, _listenSideEffect);
    final connectivitySubscription = _ref.listen(connectivityProvider,
        (previous, next) => _listenForConnectivity(previous, next));
    final authSubscription = _ref.listen(
        authProvider, (previous, next) => _listenForAuth(previous, next));
    final errorRequestSubscription =
        linksysErrorResponseStream.listen(_handleForErrorRequest);
    _ref.onDispose(() {
      navigationSubscription.close();
      sideEffectSubscription.close();
      connectivitySubscription.close();
      authSubscription.close();
      errorRequestSubscription.cancel();
    });
    _universalLinkSubscription =
        UniversalLinkPlugin().universalLinkStream.listen(_handleUniversalLink);
  }

  late StreamSubscription _universalLinkSubscription;
  late final Ref _ref;

  @override
  List<BasePath> get currentConfiguration => _ref.read(navigationsProvider);

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    // logger.d("Route Delegate Rebuild! ${describeIdentity(this)}");
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: (context) {
          return AppResponsiveTheme(
            backgroundColor: Colors.transparent,
            child: DashboardBottomTabContainer(
              navigator: Navigator(
                  key: navigatorKey,
                  pages: [
                    for (final path in currentConfiguration)
                      LinksysPage(
                        name: path.name,
                        key: ValueKey(path.name),
                        fullscreenDialog: path.pageConfig.isFullScreenDialog,
                        opaque: path.pageConfig.isOpaque,
                        // child: Theme(
                        //   data: path.pageConfig.themeData,
                        //   child: path.pageConfig.isBackAvailable ? _buildPageView(path) : WillPopScope(child: _buildPageView(path), onWillPop: () async => true),
                        // ),
                        child: AppResponsiveTheme(
                            backgroundColor: path.pageConfig.isOpaque
                                ? null
                                : Colors.transparent,
                            child: path.pageConfig.isBackAvailable
                                ? _buildPageView(path)
                                : WillPopScope(
                                    child: _buildPageView(path),
                                    onWillPop: () async => true)),
                      ),
                  ],
                  onPopPage: _onPopPage),
            ),
          );
        })
      ],
    );
  }

  @override
  Future<void> setInitialRoutePath(List<BasePath> configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(List<BasePath> configuration) async {
    _ref.read(navigationsProvider.notifier).clearAndPushAll(configuration);
    return SynchronousFuture(null);
  }

  Widget _buildPageView(BasePath path) {
    return path.buildPage();
  }

  @override
  void dispose() {
    _universalLinkSubscription.cancel();
    super.dispose();
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    logger.d('MoabRouterDelegate:: onPopPage: $result');

    bool didPop = route.didPop(result);
    if (didPop) {
      if (_ref.read(navigationsProvider.notifier).canPop()) {
        _ref.read(navigationsProvider.notifier).pop();
        didPop = true;
      } else {
        didPop = false;
      }
    }
    logger.d('Navigation Back:: current:${currentConfiguration.last.name}');
    logEvent(eventName: "NavigationBack", parameters: {
      'currentPage': currentConfiguration.last.name,
    });
    return didPop;
  }

  _listenSideEffect(JNAPSideEffect? previous, JNAPSideEffect current) {
    logger.d('router_delegate:: $previous, $current');
  }

  _listenForAuth(AsyncValue<AuthState>? previous, AsyncValue<AuthState> next) {
    final previousData = previous?.value;
    final nextData = next.value;
    logger.d("Auth Listener: $nextData");
    if (previousData == nextData) {
      return;
    }
    if (currentConfiguration.last.pageConfig.ignoreAuthChanged) {
      return;
    }
    final loginType = nextData?.loginType ?? LoginType.none;
    switch (loginType) {
      case LoginType.remote:
        _ref
            .read(navigationsProvider.notifier)
            .clearAndPush(PrepareDashboardPath());
        break;
      case LoginType.local:
        _ref
            .read(navigationsProvider.notifier)
            .clearAndPush(PrepareDashboardPath());
        break;
      default:
        _ref.read(navigationsProvider.notifier).clearAndPush(HomePath());
    }
  }

  _listenForConnectivity(ConnectivityState? previous, ConnectivityState next) {
    if (currentConfiguration.last.pageConfig.ignoreConnectivityChanged) {
      return;
    }
    logger.d(
        "Connectivity Listener: ${next.connectivityInfo.type}, ${next.connectivityInfo.ssid}");
    if (next.connectivityInfo.type == ConnectivityResult.none &&
        currentConfiguration is! NoInternetConnectionPath) {
      _ref.read(navigationsProvider.notifier).push(NoInternetConnectionPath());
    } else {
      if (currentConfiguration.last is NoInternetConnectionPath) {
        _ref.read(navigationsProvider.notifier).pop();
      }
    }
  }

  _handleForErrorRequest(ErrorResponse error) {
    if (error.code == errorInvalidSessionToken) {
      _ref.read(authProvider.notifier).logout();
    }
  }

  _handleUniversalLink(dynamic event) {
    logger.d('received an universal link: $event');
  }
}
