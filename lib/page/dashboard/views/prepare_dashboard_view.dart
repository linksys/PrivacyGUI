import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class PrepareDashboardView extends ArgumentsConsumerStatefulView {
  const PrepareDashboardView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PrepareDashboardView> createState() =>
      _PrepareDashboardViewState();
}

class _PrepareDashboardViewState extends ConsumerState<PrepareDashboardView> {
  @override
  void initState() {
    super.initState();
    _checkSelfNetworks();
  }

  @override
  Widget build(BuildContext context) =>
      AppFullScreenSpinner(text: loc(context).processing);

  _checkSelfNetworks() async {
    final router = GoRouter.of(context);
    logger.d('Go to dashboard');
    // Only PnP opens this page, once it has logged in locally; the router's
    // redirect starts a remote login's session itself. Both run the same
    // start (#1904). PnP held polling while it set the router up, so polling
    // starts again even on the router it had.
    final nodeDeviceInfo = await ref
        .read(dashboardManagerProvider.notifier)
        .startSession(forcePolling: true);
    if (nodeDeviceInfo != null) {
      router.goNamed(RouteNamed.dashboardHome);
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
      logger.i('PREPARE :: Error handling for unable to get deviceinfo');
      // A login that can write goes where the router sends a logged-out user
      // (#1849). One that may not write goes back to the session login, which
      // shows the error.
      if (ref.read(accessPolicyProvider).canWrite) {
        router.goNamed(_loginRouteName(),
            queryParameters: {'error': 'Unexpected'});
      } else {
        router.goNamed(RouteNamed.cloudLoginAuth,
            queryParameters: {'error': 'Unexpected'});
      }
    }
  }

  /// The login the router's `_home()` picks: the local one on a local build,
  /// the Guardian one otherwise.
  String _loginRouteName() => BuildConfig.forceCommandType == ForceCommand.local
      ? RouteNamed.localLoginPassword
      : RouteNamed.cloudLoginAuth;
}
