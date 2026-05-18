import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// No-internet troubleshooter hub — restart modem or enter ISP settings.
class PnpNoInternetView extends ConsumerWidget {
  const PnpNoInternetView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for internet recovery → auto-navigate back to wizard.
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      }
    });

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      onBackTap: () => context.go(RoutePath.pnp),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Assets.images.noInternetConnection.svg(width: 200)),
            AppGap.lg(),
            AppText.headlineSmall(loc(context).pnpErrorForStaticIpAndDhcp),
            AppGap.xxxl(),

            // Option 1: Restart modem
            AppCard(
              child: InkWell(
                onTap: () => context.goNamed(RouteNamed.pnpUnplugModem),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      AppIcon.font(Icons.power_settings_new),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(
                              loc(context).pnpNoInternetConnectionRestartModem,
                            ),
                            AppGap.xs(),
                            AppText.bodySmall(
                              loc(context)
                                  .pnpNoInternetConnectionRestartModemDesc,
                            ),
                          ],
                        ),
                      ),
                      AppIcon.font(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            AppGap.lg(),

            // Option 2: Enter ISP settings
            AppCard(
              child: InkWell(
                onTap: () => context.goNamed(RouteNamed.pnpIspTypeSelection),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      AppIcon.font(Icons.settings_ethernet),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(
                              loc(context).pnpNoInternetConnectionEnterISP,
                            ),
                            AppGap.xs(),
                            AppText.bodySmall(
                              loc(context).pnpNoInternetConnectionEnterISPDesc,
                            ),
                          ],
                        ),
                      ),
                      AppIcon.font(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            AppGap.xxxl(),

            // Retry button
            Center(
              child: AppButton.text(
                label: loc(context).tryAgain,
                onTap: () =>
                    ref.read(pnpProvider.notifier).retryInternetCheck(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
