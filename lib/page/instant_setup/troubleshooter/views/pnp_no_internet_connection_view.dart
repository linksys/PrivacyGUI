import 'dart:async';
import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class PnpNoInternetConnectionView extends ArgumentsConsumerStatefulView {
  const PnpNoInternetConnectionView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpNoInternetConnectionView> createState() =>
      _PnpNoInternetConnectionState();
}

class _PnpNoInternetConnectionState
    extends ConsumerState<PnpNoInternetConnectionView> {
  late final String? _ssid;
  bool _fromDashboard = false;

  @override
  void initState() {
    _ssid = widget.args['ssid'] as String?;
    _fromDashboard = (widget.args['from'] as String?) == 'dashboard';
    super.initState();
    Future.doWhile(() => !mounted).then((_) {
      ref.read(pnpProvider.notifier).setForceLogin(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: (context, constraints) => _contentView(context),
    );
  }

  Widget _contentView(BuildContext context) {
    return Center(
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon.font(
              AppFontIcons.publicOff,
              size: 48,
            ),
            AppGap.xxl(),
            _titleView(context),
            AppGap.lg(),
            AppText.bodyLarge(
              loc(context).noInternetConnectionDescription,
            ),
            AppGap.xxl(),
            AppCard(
              onTap: () {
                goRoute(RouteNamed.pnpUnplugModem);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          loc(context).pnpNoInternetConnectionRestartModem,
                        ),
                        AppGap.xs(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionRestartModemDesc,
                        ),
                      ],
                    ),
                  ),
                  AppIcon.font(AppFontIcons.chevronRight),
                ],
              ),
            ),
            AppGap.sm(),
            AppCard(
              onTap: () async {
                // Fetch device info and update better actions before start.
                await ref.read(pnpProvider.notifier).fetchDeviceInfo();
                // ALT, check router is configured and ignore the exception, check only
                try {
                  await ref.read(pnpProvider.notifier).checkRouterConfigured();
                } catch (_) {}
                final attachedPassword = ref.read(pnpProvider).attachedPassword;
                if (ref.read(pnpProvider).isRouterUnConfigured) {
                  // ALT, check router admin password is default one and ignore the exception, check only
                  try {
                    await ref
                        .read(pnpProvider.notifier)
                        .checkAdminPassword(defaultAdminPassword);
                  } catch (_) {}
                } else if (attachedPassword != null &&
                    attachedPassword.isNotEmpty) {
                  // ALT, check router admin password is attached one and ignore the exception, check only
                  try {
                    await ref
                        .read(pnpProvider.notifier)
                        .checkAdminPassword(attachedPassword);
                  } catch (_) {}
                }
                if (ref.read(pnpProvider.notifier).isLoggedIn) {
                  goRoute(RouteNamed.pnpIspTypeSelection);
                } else {
                  final isLoggedIn = await goRoute(RouteNamed.pnpIspAuth);
                  if (isLoggedIn == true) {
                    goRoute(RouteNamed.pnpIspTypeSelection);
                  }
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                          loc(context).pnpNoInternetConnectionEnterISP,
                        ),
                        AppGap.xs(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionEnterISPDesc,
                        ),
                      ],
                    ),
                  ),
                  AppIcon.font(AppFontIcons.chevronRight),
                ],
              ),
            ),
            AppGap.xxl(),
            if (!_fromDashboard) ...[
              AppButton.text(
                label: loc(context).logIntoRouter,
                onTap: () {
                  ref.read(pnpProvider.notifier).setForceLogin(true);
                  goRoute(RouteNamed.pnpConfig, true);
                },
              ),
              AppGap.xxl(),
            ],
            AppButton(
              label: loc(context).tryAgain,
              variant: SurfaceVariant.highlight,
              onTap: () {
                logger.d('[PnP Troubleshooter]: Try again internet connection');
                goRoute(RouteNamed.pnp, true);
              },
            )
          ],
        ),
      ),
    );
  }

  AppText _titleView(BuildContext context) {
    final titleString = _ssid != null
        ? loc(context).noInternetConnectionWithSSIDTitle(_ssid!)
        : loc(context).noInternetConnectionTitle;
    return AppText.headlineSmall(titleString);
  }

  FutureOr goRoute(String name, [bool push = true]) {
    if (push) {
      return context.pushNamed(name);
    } else {
      context.goNamed(name);
    }
  }
}
