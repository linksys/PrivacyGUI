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
class PnpNoInternetView extends ConsumerStatefulWidget {
  const PnpNoInternetView({super.key});

  @override
  ConsumerState<PnpNoInternetView> createState() => _PnpNoInternetViewState();
}

class _PnpNoInternetViewState extends ConsumerState<PnpNoInternetView> {
  bool _retrying = false;
  bool _bypassing = false;

  /// True while either action is in flight. Both buttons guard on this so a
  /// retry and a bypass can never run concurrently and race their navigation.
  bool get _busy => _retrying || _bypassing;

  Future<void> _onRetry() async {
    if (_busy) return;
    setState(() => _retrying = true);
    try {
      await ref.read(pnpProvider.notifier).retryInternetCheck();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  /// "Log into router" escape hatch — acknowledge PnP and enter the dashboard
  /// without waiting for internet. See [PnpNotifier.bypassToDashboard].
  Future<void> _onLogIntoRouter() async {
    if (_busy) return;
    setState(() => _bypassing = true);
    try {
      await ref.read(pnpProvider.notifier).bypassToDashboard();
      if (mounted) context.go(RoutePath.uspDashboard);
    } finally {
      if (mounted) setState(() => _bypassing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for internet recovery → auto-navigate back to wizard.
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      } else if (next.phase is AdminReadFailure) {
        // "Try again" hit a read failure (router state unreadable) rather than a
        // confirmed no-internet. Route back to the entry view, which re-runs the
        // flow (implicit retry) and renders the read-failure card if it persists.
        context.go(RoutePath.pnp);
      }
    });

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      onBackTap: () => context.go(RoutePath.pnp),
      child: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Assets.images.noInternetConnection.svg(width: 160),
                  ),
                  AppGap.lg(),
                  AppText.headlineSmall(
                    loc(context).pnpErrorForStaticIpAndDhcp,
                    textAlign: TextAlign.center,
                  ),
                  AppGap.xxxl(),
                  _OptionCard(
                    icon: Icons.power_settings_new,
                    title: loc(context).pnpNoInternetConnectionRestartModem,
                    description:
                        loc(context).pnpNoInternetConnectionRestartModemDesc,
                    onTap: () => context.goNamed(RouteNamed.pnpUnplugModem),
                  ),
                  AppGap.lg(),
                  _OptionCard(
                    icon: Icons.settings_ethernet,
                    title: loc(context).pnpNoInternetConnectionEnterISP,
                    description:
                        loc(context).pnpNoInternetConnectionEnterISPDesc,
                    onTap: () =>
                        context.goNamed(RouteNamed.pnpIspTypeSelection),
                  ),
                  AppGap.xxxl(),
                  Center(
                    child: AppButton.text(
                      label: loc(context).logIntoRouter,
                      isLoading: _bypassing,
                      onTap: _busy ? null : _onLogIntoRouter,
                    ),
                  ),
                  AppGap.lg(),
                  Center(
                    child: AppButton.text(
                      label: loc(context).tryAgain,
                      isLoading: _retrying,
                      onTap: _busy ? null : _onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              AppIcon.font(icon),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(title),
                    AppGap.xs(),
                    AppText.bodySmall(description),
                  ],
                ),
              ),
              AppIcon.font(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
