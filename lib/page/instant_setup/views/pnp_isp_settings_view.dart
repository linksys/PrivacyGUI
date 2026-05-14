import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// ISP type selection hub — navigate to PPPoE, Static IP, or trigger DHCP.
class PnpIspSettingsView extends ConsumerWidget {
  const PnpIspSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pnpState = ref.watch(pnpProvider);
    final phase = pnpState.phase;

    // Listen for internet recovery or ISP save progress
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      }
    });

    // Show save progress if ISP is being saved
    if (phase is IspSaving) {
      return UiKitPageView(
        appBarStyle: UiKitAppBarStyle.none,
        title: loc(context).pnpIspTypeSelectionTitle,
        child: (context, constraints) => Center(
          child: _buildSaveProgress(context, phase),
        ),
      );
    }

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.headlineSmall(loc(context).pnpIspTypeSelectionTitle),
            AppGap.xxxl(),

            // DHCP
            _buildTypeCard(
              context,
              icon: Icons.refresh,
              title: 'DHCP',
              description: loc(context).pnpIspTypeSelectionDhcpDesc,
              onTap: () {
                ref.read(pnpProvider.notifier).saveIspWithProgress(
                      const PnpIspConfig(type: IspConnectionType.dhcp),
                    );
              },
            ),
            AppGap.md(),

            // PPPoE
            _buildTypeCard(
              context,
              icon: Icons.vpn_key_outlined,
              title: 'PPPoE',
              description: loc(context).pnpIspTypeSelectionPppoeDesc,
              onTap: () => context.goNamed(RouteNamed.pnpPPPOE),
            ),
            AppGap.md(),

            // Static IP
            _buildTypeCard(
              context,
              icon: Icons.pin_outlined,
              title: loc(context).ipAddress,
              description: loc(context).pnpIspTypeSelectionStaticDesc,
              onTap: () => context.goNamed(RouteNamed.pnpStaticIp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              AppIcon.font(icon, size: 28),
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

  Widget _buildSaveProgress(BuildContext context, IspSaving phase) {
    final steps = [
      (IspSaveStep.saving, loc(context).save),
      (IspSaveStep.checkingSettings, loc(context).pnpIspTypeSelectionTitle),
      (
        IspSaveStep.checkingInternet,
        loc(context).pnpWaitingModemCheckingInternet
      ),
    ];
    final currentIdx = IspSaveStep.values.indexOf(phase.step);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLoader(),
        AppGap.xxxl(),
        ...steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final (_, label) = entry.value;
          final isActive = idx == currentIdx;
          final isDone = idx < currentIdx;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.font(
                  isDone
                      ? Icons.check_circle
                      : isActive
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                  size: 20,
                  color: isDone || isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                AppGap.sm(),
                AppText.bodyMedium(label),
              ],
            ),
          );
        }),
      ],
    );
  }
}
