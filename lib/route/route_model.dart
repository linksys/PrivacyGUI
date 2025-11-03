import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';

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
    required super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    FutureOr<bool> Function(BuildContext, GoRouterState)? onExit,
    this.config,
    super.routes = const <RouteBase>[],
    // New parameters for dirty checking
    ProviderBase<PreservableContract>? preservableProvider,
    bool enableDirtyCheck = false,
    Future<bool?> Function(BuildContext)? showAlertForTest,
  }) : super(
          onExit: (context, state) async {
            // First, run any custom onExit logic provided by the developer.
            if (onExit != null) {
              if (!await onExit(context, state)) {
                return false; // Custom logic blocked navigation.
              }
            }

            // If dirty checking is enabled and a provider is given...
            if (enableDirtyCheck && preservableProvider != null) {
              // If the view is destroyed, return true
              if (!context.mounted) return true;
              final container = ProviderScope.containerOf(context);
              final notifier = container.read(preservableProvider);

              if (notifier.isDirty()) {
                final bool? confirmed =
                    await (showAlertForTest?.call(context) ??
                        showUnsavedAlert(context));
                if (confirmed == true) {
                  // User wants to discard, so revert the state.
                  notifier.revert();
                  return true; // Allow navigation
                } else {
                  return false; // User cancelled, block navigation.
                }
              }
            }

            // Allow navigation to proceed.
            return true;
          },
        );

  static bool isShowNaviRail(
          BuildContext context, LinksysRouteConfig? config) =>
      config == null ? true : config.noNaviRail != true;

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
