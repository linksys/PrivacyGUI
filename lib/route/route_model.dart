import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/bottom_bar.dart';
import 'package:linksys_app/page/components/styled/top_bar.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

class LinksysRouteConfig extends Equatable {
  const LinksysRouteConfig({
    this.onlyMainView = false,
    this.ignoreConnectivityEvent = false,
    this.ignoreCloudOfflineEvent = false,
  });
  final bool onlyMainView;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;

  @override
  List<Object?> get props => [
        onlyMainView,
        ignoreConnectivityEvent,
        ignoreCloudOfflineEvent,
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
          final pagePadding = ResponsiveLayout.pageHorizontalPadding(context);

          return Container(
            color: Theme.of(context).extension<ColorSchemeExt>()?.surfaceBright,
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // if (increase()) {
                          //   logger.d('Triggered!');
                          //   context.pushNamed(RouteNamed.debug);
                          // }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: pagePadding, vertical: 0),
                          child: Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      ResponsiveLayout.pageMainWidth(context)),
                              child: builder(context, state)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!ResponsiveLayout.isLayoutBreakpoint(context))
                  const BottomBar(),
              ],
            ),
          );
        });
}
