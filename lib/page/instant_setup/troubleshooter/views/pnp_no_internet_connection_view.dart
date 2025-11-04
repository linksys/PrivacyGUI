import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

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
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: (context, constraints) => _contentView(context),
    );
  }

  Widget _contentView(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.large3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LinksysIcons.publicOff,
              semanticLabel: 'public Off icon',
              size: 48,
            ),
            const AppGap.large3(),
            _titleView(context),
            const AppGap.medium(),
            AppText.bodyLarge(
              loc(context).noInternetConnectionDescription,
            ),
            const AppGap.large3(),
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
                        const AppGap.small3(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionRestartModemDesc,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            const AppGap.small2(),
            AppCard(
              onTap: () async {
                // Fetch device info and update better actions before start.
                await ref.read(pnpProvider.notifier).fetchDeviceInfo();
                // ALT, check router is configured and ignore the exception, check only
                await ref
                    .read(pnpProvider.notifier)
                    .checkRouterConfigured()
                    .onError((_, __) {});
                final attachedPassword = ref.read(pnpProvider).attachedPassword;
                if (ref.read(pnpProvider).isRouterUnConfigured) {
                  // ALT, check router admin password is default one and ignore the exception, check only
                  await ref
                      .read(pnpProvider.notifier)
                      .checkAdminPassword(defaultAdminPassword)
                      .onError((_, __) {});
                } else if (attachedPassword != null &&
                    attachedPassword.isNotEmpty) {
                  // ALT, check router admin password is attached one and ignore the exception, check only
                  await ref
                      .read(pnpProvider.notifier)
                      .checkAdminPassword(attachedPassword)
                      .onError((_, __) {});
                }
                if (ref.read(routerRepositoryProvider).isLoggedIn()) {
                  goRoute(RouteNamed.pnpIspTypeSelection);
                } else {
                  final isLoggedIn = await goRoute(RouteNamed.pnpIspAuth);
                  if (isLoggedIn) {
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
                        const AppGap.small3(),
                        AppText.bodyMedium(
                          loc(context).pnpNoInternetConnectionEnterISPDesc,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LinksysIcons.chevronRight),
                ],
              ),
            ),
            const AppGap.large3(),
            if (!_fromDashboard) ...[
              AppTextButton.noPadding(
                loc(context).logIntoRouter,
                onTap: () {
                  ref.read(pnpProvider.notifier).setForceLogin(true);
                  goRoute(RouteNamed.pnpConfig, true);
                },
              ),
              const AppGap.large3(),
            ],
            AppFilledButton(
              loc(context).tryAgain,
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
