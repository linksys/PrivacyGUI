import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';

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

/// A [GoRoute] that adds the app's unsaved-changes guard.
///
/// ## The guard fires when the page LEAVES the stack, not when it stops being
/// visible
///
/// go_router calls `onExit` only for the matches that are exiting — the ones in
/// the current match list and not in the new one. So `go` away from a dirty page
/// runs the guard, and `push` away from it does not: the page stays underneath,
/// mounted and offstage, with its working copy alive. Measured on go_router
/// 17.5.0: `onExit` fires once on `goNamed` and zero times on `pushNamed`.
///
/// That difference is visible from #1434 onwards, because the entry-verb fixes
/// converted several controls from `go` to `push` — the global top bar and the
/// dashboard's offline banner among them, both reachable from a dirty settings
/// page. **Accepted, not overlooked**: the prompt exists so edits are not lost,
/// and a pushed-over page loses nothing. Back pops to it with the working copy
/// intact, and the guard still runs when that page finally leaves the stack.
/// Prompting on a push would ask the user to decide something they have not done
/// yet. Pinned in `test/framework/linksys_route_test.dart`.
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
              if (!context.mounted) return true;
            }

            // If dirty checking is enabled and a provider is given...
            if (enableDirtyCheck && preservableProvider != null) {
              final container = ProviderScope.containerOf(context);
              final notifier = container.read(preservableProvider);

              if (notifier.isDirty()) {
                final bool? confirmed =
                    await (showAlertForTest?.call(context) ??
                        showUnsavedAlert(context));
                if (!context.mounted) return true;
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
