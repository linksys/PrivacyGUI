// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/components/views/write_flow_blocked_view.dart';

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
    this.writeFlow = false,
  });

  final ColumnGrid? column;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;
  final bool? noNaviRail;

  /// A flow whose only purpose is to write to the router. A login that may not
  /// write sees [WriteFlowBlockedView] in its place.
  ///
  /// For a flow pushed from a page the viewer can still reach, whose caller
  /// awaits a result: the route stays, and the blocked page pops with null.
  /// A tree that must not be entered at all goes through writeFlowRedirect.
  final bool writeFlow;

  @override
  List<Object?> get props => [
        column,
        ignoreConnectivityEvent,
        ignoreCloudOfflineEvent,
        noNaviRail,
        writeFlow,
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
          // Swapped rather than redirected: callers push these flows and await
          // a typed result, and the blocked page pops with null, which every
          // such caller already handles.
          if (config?.writeFlow == true &&
              !ProviderScope.containerOf(context)
                  .read(accessPolicyProvider)
                  .canWrite) {
            return const WriteFlowBlockedView();
          }
          return builder(context, state);
        });

  static bool isShowNaviRail(
          BuildContext context, LinksysRouteConfig? config) =>
      config == null ? true : config.noNaviRail != true;

  //

  static bool autoHideNaviRail(BuildContext context) =>
      (GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .lastOrNull
              ?.matchedLocation
              .split('/')
              .length ??
          0) >
      2;
}
