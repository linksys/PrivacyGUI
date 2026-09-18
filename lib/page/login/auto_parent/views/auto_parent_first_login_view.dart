import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/arguments_view.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    return UiKitPageView(
      backState: UiKitBackState.none,
      scrollable: true,
      child: (context, constraints) => Center(
        child: SizedBox(
          width: context.colWidth(4),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: AppLoader()),
                // The gap this screen was missing. Every other `AppLoader`-then-text
                // pairing in `lib/page` has one — the wizard's own saving overlay and
                // its reconnect poll both use `AppGap.lg()`, and five more sites agree —
                // so this page was the single outlier, at exactly 0.0px: measured
                // `title.top - loader.bottom == 0.0` at 320, 480 and 1280. No gate cell
                // could report it, because nothing overflowed and nothing clipped; the
                // golden added for this screen in #1554 is what showed the spinner
                // sitting on the title's first line.
                AppGap.lg(),
                AppText.titleLarge(loc(context).pnpFwUpdateTitle),
                AppGap.lg(),
                AppText.bodyMedium(loc(context).pnpFwUpdateDesc),
                AppGap.lg(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _doFirmwareUpdateCheck() async {
    logger.i('[FirstTime]: Do Firmware Update Check');
    bool failCheck = false;
    final isNewFwAvailable = await ref
        .read(autoParentFirstLoginProvider.notifier)
        .checkAndAutoInstallFirmware()
        .onError((e, _) {
      logger.e('[FirstTime]: Failed to check firmware update');
      failCheck = true;
      return false;
    });
    if (isNewFwAvailable) {
      logger.i('[FirstTime]: Firmware Updateing...');
    } else {
      logger.i(
          '[FirstTime]: ${failCheck ? 'Fw check failed' : 'No available FW'}, ready to go.');
      _finishFirstTimeLogin(failCheck);
    }
  }

  void _finishFirstTimeLogin([bool failCheck = false]) async {
    await ref
        .read(autoParentFirstLoginProvider.notifier)
        .finishFirstTimeLogin(failCheck);
    Future.doWhile(() => !mounted).then((_) {
      if (!mounted) return;
      context.goNamed(RouteNamed.dashboardHome);
    });
  }
}
