// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/layouts/idle_checker.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// How long an unattended session stays logged in.
///
/// Matches 1.x, which uses the same 15 minutes at
/// `lib/page/components/layouts/root_container.dart` on `dev-1.3.1` (#1454).
/// The two trees ship the same product, so an operator should not get a shorter
/// leash for being on the newer one.
///
/// Named rather than inlined because it is a security-relevant policy value:
/// `test/components/layouts/root_container_test.dart` pins it, so shortening or
/// lengthening it has to be deliberate.
const Duration kIdleLogoutWindow = Duration(minutes: 15);

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
    logger.t('[App]: Root Container build: ${widget.route}');

    return LayoutBuilder(builder: ((context, constraints) {
      return IdleChecker(
        idleTime: kIdleLogoutWindow,
        onIdle: () {
          // not for debug
          if (!kReleaseMode) {
            return;
          }
          // not log in yet
          if (!(ref.read(authProvider).value?.isLoggedIn ?? false)) {
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
          logger.t('[App]: Idled!');
          ref.read(authProvider.notifier).logout();
        },
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: CompositedTransformTarget(
            link: _link,
            child: _buildLayout(
                Container(child: widget.child ?? const Center()), constraints),
          ),
        ),
      );
    }));
  }

  Widget _buildLayout(Widget child, BoxConstraints constraints) {
    return child;
  }
}
