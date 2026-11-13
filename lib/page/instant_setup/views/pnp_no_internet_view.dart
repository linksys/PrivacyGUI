import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_ending.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/instant_setup/views/components/troubleshooting_navigation.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// No-internet troubleshooter hub — restart modem or enter ISP settings.
///
/// **The one page that hands a finished run over (#1511 P1).** It is the root of
/// the troubleshooting tree, so it sits under every other page of it in the
/// navigator stack, and its listener is the only place a recovery or a read
/// failure becomes a destination: [ending]'s. It also watches the run's state and
/// the WAN prefill, which is what keeps both alive for the length of the run.
class PnpNoInternetView extends ConsumerStatefulWidget {
  const PnpNoInternetView({super.key, required this.ending});

  /// How whoever entered troubleshooting wants it to end.
  final TroubleshootingEnding ending;

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
      await ref
          .read(internetTroubleshootingProvider.notifier)
          .retryInternetCheck();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  /// "Log into router" escape hatch — whatever the caller does to let the user
  /// in without internet, then where it says to go.
  Future<void> _onLogIntoRouter() async {
    final continueWithoutInternet = widget.ending.continueWithoutInternet;
    if (_busy || continueWithoutInternet == null) return;
    setState(() => _bypassing = true);
    try {
      final destination = await continueWithoutInternet();
      if (mounted) context.go(destination);
    } finally {
      if (mounted) setState(() => _bypassing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read when the hub opens, for the ISP forms; watching it keeps it for the run.
    ref.watch(troubleshootingWanPrefillProvider);

    // The run is over — on this page or on any page above it — so the caller's
    // ending takes over. A read failure goes there too: the router did not
    // confirm "no internet", so the caller looks again (PnP's entry re-runs its
    // check and renders its read-failure card if it persists).
    ref.listen(internetTroubleshootingProvider, (prev, next) {
      if (next is TroubleshootingRecovered ||
          next is TroubleshootingReadFailure) {
        context.go(widget.ending.exitLocation);
      }
    });

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      onBackTap: () => context.go(widget.ending.exitLocation),
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
                    onTap: () => context
                        .goWithinTroubleshooting(RouteNamed.pnpUnplugModem),
                  ),
                  AppGap.lg(),
                  _OptionCard(
                    icon: Icons.settings_ethernet,
                    title: loc(context).pnpNoInternetConnectionEnterISP,
                    description:
                        loc(context).pnpNoInternetConnectionEnterISPDesc,
                    onTap: () => context.goWithinTroubleshooting(
                        RouteNamed.pnpIspTypeSelection),
                  ),
                  AppGap.xxxl(),
                  if (widget.ending.continueWithoutInternet != null) ...[
                    Center(
                      child: AppButton.text(
                        label: loc(context).logIntoRouter,
                        isLoading: _bypassing,
                        onTap: _busy ? null : _onLogIntoRouter,
                      ),
                    ),
                    AppGap.lg(),
                  ],
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
