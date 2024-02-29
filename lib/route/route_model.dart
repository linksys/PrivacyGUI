import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/top_bar.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

class LinksysRouteConfig extends Equatable {
  const LinksysRouteConfig({
    this.fullWidth = false,
    this.ignoreConnectivityEvent = false,
    this.ignoreCloudOfflineEvent = false,
  });
  final bool fullWidth;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;

  @override
  List<Object?> get props => [
        fullWidth,
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
          final isFullWidth = config?.fullWidth ?? false;
          return Container(
            color: Theme.of(context).colorScheme.background,
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
                              horizontal: isFullWidth ? 0 : pagePadding,
                              vertical: 0),
                          child: Container(
                              constraints: isFullWidth
                                  ? null
                                  : BoxConstraints(
                                      maxWidth: ResponsiveLayout.pageMainWidth(
                                          context)),
                              child: builder(context, state)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
}
