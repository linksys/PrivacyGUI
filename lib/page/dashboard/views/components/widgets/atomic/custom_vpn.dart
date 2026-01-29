import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying VPN status.
///
/// For custom layout (Bento Grid) only.
class CustomVPN extends DisplayModeConsumerWidget {
  const CustomVPN({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 230,
        DisplayMode.expanded => 230,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Simple toggle row
    final vpnState = ref.watch(vpnProvider);
    final isEnabled = vpnState.settings.serviceSettings.enabled;
    final status = vpnState.status.tunnelStatus;
    final isConnected = status == IPsecStatus.connected;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      onTap: () {
        context.pushNamed(RouteNamed.settingsVPN);
      },
      child: Row(
        children: [
          Icon(
            Icons.vpn_key,
            color: isConnected
                ? Theme.of(context).extension<AppColorScheme>()!.semanticSuccess
                : Theme.of(context).colorScheme.onSurface,
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).vpn),
                AppText.labelSmall(
                  isConnected ? 'Connected' : 'Disconnected',
                  color: isConnected
                      ? Theme.of(context)
                          .extension<AppColorScheme>()!
                          .semanticSuccess
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppSwitch(
            value: isEnabled,
            onChanged: (value) {
              final settings = vpnState.settings.serviceSettings;
              final notifier = ref.read(vpnProvider.notifier);
              notifier.setVPNService(settings.copyWith(enabled: value));

              doSomethingWithSpinner(context, notifier.save());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return const VPNStatusTile();
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return const VPNStatusTile();
  }
}
