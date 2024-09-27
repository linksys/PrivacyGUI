// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';

import 'package:privacy_gui/page/components/styled/top_bar.dart';

ValueNotifier<bool> showColumnOverlayNotifier =
    ValueNotifier(BuildConfig.showColumnOverlay);

class ColumnGrid {
  final int column;
  final bool centered;

  ColumnGrid({
    required this.column,
    this.centered = false,
  });
}

class LinksysRouteConfig extends Equatable {
  const LinksysRouteConfig({
    this.column,
    this.ignoreConnectivityEvent = false,
    this.ignoreCloudOfflineEvent = false,
    this.noNaviRail,
  });

  final ColumnGrid? column;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;
  final bool? noNaviRail;

  @override
  List<Object?> get props => [
        column,
        ignoreConnectivityEvent,
        ignoreCloudOfflineEvent,
        noNaviRail,
      ];
}

class LinksysRoute extends GoRoute {
  final LinksysRouteConfig? config;
  LinksysRoute({
    required super.path,
    super.name,
    required Widget Function(BuildContext, GoRouterState) builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    super.onExit,
    this.config,
    super.routes = const <RouteBase>[],
  }) : super(builder: (context, state) {
          return builder(context, state);
        });

  static bool isShowNaviRail(
          BuildContext context, LinksysRouteConfig? config) =>
      config == null ? !autoHideNaviRail(context) : config.noNaviRail != true;

  static bool autoHideNaviRail(BuildContext context) =>
      (GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .matches
              .lastOrNull
              ?.matchedLocation
              .split('/')
              .length ??
          0) >
      2;
}
