// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/components/layouts/idle_checker.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';
import 'package:privacy_gui/providers/root/root_config.dart';
import 'package:privacy_gui/providers/root/root_provider.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class AppRootContainer extends ConsumerStatefulWidget {
  final Widget? child;
  final LinksysRoute? route;
  const AppRootContainer({
    super.key,
    this.child,
    this.route,
  });

  @override
  ConsumerState<AppRootContainer> createState() => _AppRootContainerState();
}

class _AppRootContainerState extends ConsumerState<AppRootContainer> {
  final _link = LayerLink();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Root Container:: build: ${widget.route}');
    final rootConfig = ref.watch(rootProvider);

    // The one way the router can go away that nothing else reports. Every
    // deliberate disappearance - a save with a DeviceRestart side effect, a
    // reboot, a firmware update - is announced by the flow that caused it; a
    // background poll that stops getting answers used to be announced by nobody,
    // and the dashboard went on presenting its last good snapshot as if it were
    // live.
    //
    // Listening to the count rather than to a settled 'unreachable' flag is
    // deliberate: a tick that lands while an exempt route is up is then not the
    // last word on it, because the next failed tick raises the count again.
    ref.listen(pollingFailureCountProvider, (previous, next) {
      if (next >= pollFailuresBeforeUnreachable) {
        _reportRouterUnreachable();
      }
    });

    return LayoutBuilder(builder: ((context, constraints) {
      return IdleChecker(
        idleTime: const Duration(minutes: 15),
        onIdle: () {
          // not for debug
          if (!kReleaseMode) {
            return;
          }
          // not log in yet
          if (ref.read(authProvider).value?.loginType == LoginType.none) {
            return;
          }
          // not go into dashboard yet
          if (shellNavigatorKey.currentContext == null) {
            return;
          }
          // white list
          final routeName = widget.route?.name;
          if (routeName != null && idleCheckWhiteList.contains(routeName)) {
            return;
          }
          // pause?
          if (ref.read(idleCheckerPauseProvider) == true) {
            return;
          }
          logger.d('Idled!');
          ref.read(authProvider.notifier).logout();
        },
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: CompositedTransformTarget(
            link: _link,
            child: Stack(
              children: [
                _buildLayout(Container(child: widget.child ?? const Center()),
                    constraints),
                _handleSpinner(rootConfig),
              ],
            ),
          ),
        ),
      );
    }));
  }

  Widget _handleSpinner(AppRootConfig config) {
    if (config.spinnerTag != null) {
      return AppFullScreenSpinner(title: config.singleMessage);
    } else {
      return const Center();
    }
  }

  Widget _buildLayout(Widget child, BoxConstraints constraints) {
    return child;
  }

  /// Tells the operator the router has stopped answering, rather than leaving a
  /// stale dashboard on screen looking live.
  ///
  /// The alert is the house pattern for 'the router is not there' and brings its
  /// own recovery: Try again re-checks the router and restarts polling, so nobody
  /// has to log in again.
  void _reportRouterUnreachable() {
    // Nothing is polling on the user's behalf before they are logged in.
    if (ref.read(authProvider).value?.loginType == LoginType.none) {
      return;
    }
    // The alert covers the dashboard, and PnP and login live outside its shell:
    // before that there is no stale dashboard to correct.
    final shellContext = shellNavigatorKey.currentContext;
    if (shellContext == null) {
      return;
    }
    // Routes that raise this alert from their own flow - PnP, login, firmware
    // update - would otherwise get a second one from behind.
    if (widget.route?.config?.ignoreConnectivityEvent ?? false) {
      logger.i(
          'Router unreachable, but <${widget.route?.name}> reports that itself');
      return;
    }
    // Poll ticks keep coming while the router is away, and other callers raise
    // the same alert; neither may stack a second copy on the first.
    if (isRouterNotFoundAlertShowing) {
      return;
    }
    logger.i('[RouterNotFound] polling stopped getting answers');
    showRouterNotFoundAlert(shellContext, ref);
  }
}
