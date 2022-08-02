import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/bloc/connectivity/connectivity_info.dart';
import 'package:moab_poc/bloc/connectivity/cubit.dart';
import 'package:moab_poc/route/moab_page.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/analytics.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:universal_link_plugin/universal_link_plugin.dart';

class MoabRouterDelegate extends RouterDelegate<BasePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BasePath> {

  MoabRouterDelegate(this._cubit) : navigatorKey = GlobalKey() {
    _universalLinkSubscription = UniversalLinkPlugin().universalLinkStream.listen(_handleUniversalLink);
  }
  late StreamSubscription _universalLinkSubscription;
  final NavigationCubit _cubit;
  //
  // static MoabRouterDelegate of(BuildContext context) {
  //   final delegate = Router.of(context).routerDelegate;
  //   assert(delegate is MoabRouterDelegate, 'Delegate type must match');
  //   return delegate as MoabRouterDelegate;
  // }

  @override
  BasePath get currentConfiguration => _cubit.state.last;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    logger.d("Route Delegate Rebuild! ${describeIdentity(this)}");
    return MultiBlocListener(
      listeners: [_listenForAuth(), _listenForConnectivity()],
      child: BlocConsumer<NavigationCubit, NavigationStack>(
        builder: (context, stack) => Navigator(
            key: navigatorKey,
            pages: [
              for (final path in stack.configs)
                MoabPage(
                  name: path.name,
                  key: ValueKey(path.name),
                  fullscreenDialog: path.pageConfig.isFullScreenDialog,
                  opaque: path.pageConfig.isOpaque,
                  child: Theme(
                      data: path.pageConfig.themeData,
                      child: path.buildPage(_cubit)),
                ),
            ],
            onPopPage: _onPopPage),
        listener: (context, stack) {},
      ),
    );
  }

  @override
  Future<void> setInitialRoutePath(BasePath configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(BasePath configuration) async {
    print('MoabRouterDelegate::setNewRoutePath:${configuration.name}');
    _cubit.clearAndPush(configuration);
    return SynchronousFuture(null);
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
      if (_cubit.canPop()) {
        _cubit.pop();
        didPop = true;
      } else {
        didPop = false;
      }
    }
    logger.d('Navigation Back:: current:${currentConfiguration.name}');
    logEvent(eventName: "NavigationBack", parameters: {
      'currentPage': currentConfiguration.name,
    });
    return didPop;
  }

  BlocListener _listenForAuth() {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          !currentConfiguration.pageConfig.ignoreAuthChanged,
      listener: (context, state) {
        logger.d("Auth Listener: $state}");
        if (state.status == AuthStatus.unAuthorized) {
          _cubit.clearAndPush(HomePath());
        } else if (state.status == AuthStatus.authorized) {
          _cubit.clearAndPush(PrepareDashboardPath());
        }
      },
    );
  }

  BlocListener _listenForConnectivity() {
    return BlocListener<ConnectivityCubit, ConnectivityInfo>(
      listenWhen: (previous, current) =>
          !currentConfiguration.pageConfig.ignoreConnectivityChanged,
      listener: (context, state) {
        logger.d("Connectivity Listener: ${state.type}, ${state.ssid}");
        if (state.type == ConnectivityResult.none &&
            currentConfiguration is! NoInternetConnectionPath) {
          _cubit.push(NoInternetConnectionPath());
        } else {
          if (currentConfiguration is NoInternetConnectionPath) {
            _cubit.pop();
          }
        }
      },
    );
  }

  _handleUniversalLink(dynamic event) {
    logger.d('received an universal link: $event');
  }
}
