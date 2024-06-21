// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import 'package:privacy_gui/page/components/styled/top_bar.dart';

sealed class PageWidth {}

class FullPageWidth extends PageWidth {}

class SpecificPageWidth extends PageWidth {
  final double width;
  SpecificPageWidth({
    required this.width,
  });
}

class ColumnPageWidth extends PageWidth {
  static const maxColumn = 12;
  final int column;

  ColumnPageWidth({required this.column}) : assert(column <= 12);
}

class LinksysRouteConfig extends Equatable {
  const LinksysRouteConfig({
    this.pageWidth,
    this.ignoreConnectivityEvent = false,
    this.ignoreCloudOfflineEvent = false,
    this.noNaviRail,
    this.pageAlignment,
  });

  final PageWidth? pageWidth;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;
  final bool? noNaviRail;
  final CrossAxisAlignment? pageAlignment;

  @override
  List<Object?> get props => [
        pageWidth,
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
          final pagePadding = ResponsiveLayout.pageHorizontalPadding(context);
          final pageWidth = config?.pageWidth;
          final screenWidth = MediaQuery.of(context).size.width;
          final mainPageWidth = ResponsiveLayout.pageMainWidth(context);

          bool? isFullWidth;
          double? specificWidth;
          (isFullWidth, specificWidth) = switch (pageWidth) {
            FullPageWidth() => (true, null),
            SpecificPageWidth() => (false, pageWidth.width),
            ColumnPageWidth() => (
                false,
                ResponsiveLayout.isMobileLayout(context)
                    ? mainPageWidth
                    : mainPageWidth *
                        pageWidth.column /
                        ColumnPageWidth.maxColumn
              ),
            _ => (false, null),
          };

          return Container(
            color: Theme.of(context).colorScheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment:
                  config?.pageAlignment ?? CrossAxisAlignment.start,
              children: [
                const TopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // if (increase()) {
                          //   context.pushNamed(RouteNamed.debug);
                          // }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isFullWidth ? 0 : pagePadding,
                            vertical: 0,
                          ),
                          child: Container(
                              width: specificWidth,
                              constraints: isFullWidth
                                  ? null
                                  : BoxConstraints(
                                      maxWidth:
                                          ((specificWidth ?? 0) > mainPageWidth
                                                  ? specificWidth
                                                  : mainPageWidth) ??
                                              mainPageWidth),
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
