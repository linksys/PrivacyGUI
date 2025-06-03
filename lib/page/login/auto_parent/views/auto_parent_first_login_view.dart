import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

/// This is the view that is shown when the user is logged in for the first time
/// after auto parent login.
/// It is used to -
/// 1. Check and auto install the latest firmware.
/// 2. Set userAcknowledgedAutoConfiguration to true.
/// 3. Set firmware updatePolicy to [FirmwareUpdateSettings.firmwareUpdatePolicyAuto].
/// 4. Must connect back to the router.

class AutoParentFirstLoginView extends ArgumentsConsumerStatefulView {
  const AutoParentFirstLoginView({super.key});

  @override
  ConsumerState<AutoParentFirstLoginView> createState() =>
      _AutoParentFirstLoginViewState();
}

class _AutoParentFirstLoginViewState
    extends ConsumerState<AutoParentFirstLoginView> {
  @override
  void initState() {
    super.initState();
    logger.i('[FirstTime]: Init Auto Parent First Login');
    Future.doWhile(() => !mounted).then((_) {
      _doFirmwareUpdateCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    // When the client fails to reconnect to the router after updating the firmware
    // the retry requests will reach the max limit and the alert will pop up
    ref.listen(firmwareUpdateProvider, (prev, next) {
      if (prev?.isRetryMaxReached == false && next.isRetryMaxReached == true) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          _finishFirstTimeLogin();
        });
      } else if (prev?.isUpdating == true && next.isUpdating == false) {
        logger.d('[FirstTime]: FW update finish go to dashboard!');
        _finishFirstTimeLogin();
      }
    });

    return StyledAppPageView(
      backState: StyledBackState.none,
      scrollable: true,
      child: (context, constraints) => AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.center,
        content: Align(
          alignment: AlignmentDirectional.topCenter,
          child: SizedBox(
            width: ResponsiveLayout.isMobileLayout(context) ? 4.col : 6.col,
            child: AppCard(
              color: Theme.of(context).colorScheme.background,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AppSpinner()),
                  AppText.titleLarge(loc(context).pnpFwUpdateTitle),
                  const AppGap.medium(),
                  AppText.bodyMedium(loc(context).pnpFwUpdateDesc),
                  const AppGap.medium(),
                ],
              ),
            ),
          ),
        ),
        footer: Row(),
      ),
    );
  }

  void _doFirmwareUpdateCheck() async {
    logger.i('[FirstTime]: Do Firmware Update Check');
    await ref
        .read(autoParentFirstLoginProvider.notifier)
        .checkAndAutoInstallFirmware();
    logger.i('[FirstTime]: Firmware Update Check Done');
    _finishFirstTimeLogin();
  }

  void _finishFirstTimeLogin() async {
    await ref
        .read(autoParentFirstLoginProvider.notifier)
        .finishFirstTimeLogin();
    Future.doWhile(() => !mounted).then((_) {
      context.goNamed(RouteNamed.dashboardHome);
    });
  }
}
