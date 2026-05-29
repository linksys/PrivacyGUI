import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_isp_saving_progress.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// ISP type selection hub — navigate to PPPoE, Static IP, or trigger DHCP.
///
/// Owns the save flow only when DHCP is chosen (DHCP saves inline on this
/// page). For PPPoE/Static IP, the corresponding form view owns the flow,
/// so this page must not react to those save outcomes — otherwise the
/// SnackBar / navigation would fire from two pages at once.
class PnpIspSettingsView extends ConsumerStatefulWidget {
  const PnpIspSettingsView({super.key});

  @override
  ConsumerState<PnpIspSettingsView> createState() => _PnpIspSettingsViewState();
}

class _PnpIspSettingsViewState extends ConsumerState<PnpIspSettingsView> {
  bool _dhcpSaving = false;

  Future<void> _onDhcpTap() async {
    setState(() => _dhcpSaving = true);
    await ref.read(pnpProvider.notifier).saveIspWithProgress(
          const PnpIspConfig(type: IspConnectionType.dhcp),
        );
    if (!mounted) return;
    setState(() => _dhcpSaving = false);

    final state = ref.read(pnpProvider);
    final phase = state.phase;
    if (phase is WizardConfiguring || phase is WizardInitializing) {
      context.go(RoutePath.pnp);
    } else if (state.errorMessage != null) {
      showFailedSnackBar(context, state.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While DHCP is saving, render saving progress driven by the global phase.
    // We only watch the phase when _dhcpSaving is true — this guarantees that
    // PPPoE/Static IP save flows do not cause this page to rebuild.
    final ispSavingPhase = _dhcpSaving
        ? ref.watch(
            pnpProvider.select(
              (s) => s.phase is IspSaving ? s.phase as IspSaving : null,
            ),
          )
        : null;

    if (ispSavingPhase != null) {
      return UiKitPageView(
        scrollable: false,
        appBarStyle: UiKitAppBarStyle.none,
        useMainPadding: false,
        child: (context, constraints) => PnpIspSavingProgress(
          phase: ispSavingPhase,
        ),
      );
    }

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      child: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildTypeSelection(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.headlineSmall(loc(context).pnpIspTypeSelectionTitle),
        AppGap.xxxl(),
        _buildTypeCard(
          context,
          icon: Icons.refresh,
          title: 'DHCP',
          description: loc(context).pnpIspTypeSelectionDhcpDesc,
          onTap: _onDhcpTap,
        ),
        AppGap.md(),
        _buildTypeCard(
          context,
          icon: Icons.vpn_key_outlined,
          title: 'PPPoE',
          description: loc(context).pnpIspTypeSelectionPppoeDesc,
          onTap: () => context.goNamed(RouteNamed.pnpPPPOE),
        ),
        AppGap.md(),
        _buildTypeCard(
          context,
          icon: Icons.pin_outlined,
          title: loc(context).ipAddress,
          description: loc(context).pnpIspTypeSelectionStaticDesc,
          onTap: () => context.goNamed(RouteNamed.pnpStaticIp),
        ),
      ],
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
}
