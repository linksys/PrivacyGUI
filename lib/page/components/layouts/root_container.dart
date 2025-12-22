// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/layouts/idle_checker.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

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

    return LayoutBuilder(builder: ((context, constraints) {
      return IdleChecker(
        idleTime: const Duration(minutes: 5),
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
          color: Theme.of(context).colorScheme.surface,
          child: CompositedTransformTarget(
            link: _link,
            child: Stack(
              children: [
                _buildLayout(Container(child: widget.child ?? const Center()),
                    constraints),
                ..._handleConnectivity(ref),
              ],
            ),
          ),
        ),
      );
    }));
  }

  Widget _buildLayout(Widget child, BoxConstraints constraints) {
    return child;
  }

  List<Widget> _handleConnectivity(WidgetRef ref) {
    // final ignoreConnectivity =
    //     (widget.routeConfig?.ignoreConnectivityEvent ?? false) || kIsWeb;
    // final ignoreCloudOffline =
    //     (widget.routeConfig?.ignoreCloudOfflineEvent ?? false) || kIsWeb;
    // if (!ignoreConnectivity) {
    //   final connectivity = ref.watch(connectivityProvider
    //       .select((value) => (value.hasInternet, value.connectivityInfo.type)));
    //   final hasInternet = connectivity.$1;
    //   final connectivityType = connectivity.$2;
    //   if (!hasInternet || connectivityType == ConnectivityResult.none) {
    //     logger.i('No internet access: $hasInternet, $connectivityType');
    //     return [const NoInternetConnectionModal()];
    //   }
    // }
    // if (!ignoreCloudOffline) {
    //   final cloudOffline = ref.watch(connectivityProvider
    //       .select((value) => value.cloudAvailabilityInfo?.isCloudOk ?? false));
    //   if (!cloudOffline) {
    //     logger.i('cloud unavailable: $cloudOffline');
    //     return [const NoInternetConnectionModal()];
    //   }
    // }
    return [];
  }
}
