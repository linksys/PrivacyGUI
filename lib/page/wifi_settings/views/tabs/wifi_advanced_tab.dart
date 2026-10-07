import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 2 — Advanced WiFi settings.
///
/// Implements:
///   - Client steering: Device.X_LINKSYS_Mesh.ClientSteeringEnabled (#1661)
///   - Node steering: Device.X_LINKSYS_Mesh.NodeSteeringEnabled (#1661)
///   - DFS (IEEE 802.11h): Device.WiFi.Radio.{i}.IEEE80211hEnabled
///
/// In 1.x's order: the two steering switches, then DFS.
///
/// Uses buffered save (Type A pattern): toggle updates local state only,
/// user must press Save (page-level bottom bar) to persist changes.
class UspWifiAdvancedTab extends ConsumerWidget {
  const UspWifiAdvancedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspWifiAdvancedProvider);
    final status = state.status;

    if (status.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxxl),
          child: AppLoader(),
        ),
      );
    }

    if (status.error != null) {
      return ServiceErrorView(
        error: status.error,
        title: loc(context).failedToLoadSettings,
        onRetry: () =>
            ref.read(uspWifiAdvancedProvider.notifier).fetch(forceRemote: true),
      );
    }

    return _buildContent(context, ref, state);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    WifiAdvancedFeatureState state,
  ) {
    final notifier = ref.read(uspWifiAdvancedProvider.notifier);
    final settings = state.settings.current;
    final busy = state.status.isSaving;

    // No "nothing here" state any more: a fetch that succeeded read both
    // steering switches (the definition requires them), so the tab always has
    // those two rows. A firmware whose radios report no IEEE 802.11h drops the
    // DFS card only.
    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdvancedSwitchCard(
            identifier: 'wifi-advanced-client-steering',
            title: loc(context).clientSteering,
            description: loc(context).clientSteeringDesc,
            value: settings.clientSteering,
            busy: busy,
            onChanged: notifier.setClientSteering,
          ),
          AppGap.md(),
          _AdvancedSwitchCard(
            identifier: 'wifi-advanced-node-steering',
            title: loc(context).nodeSteering,
            description: loc(context).nodeSteeringDesc,
            value: settings.nodeSteering,
            busy: busy,
            onChanged: notifier.setNodeSteering,
          ),
          if (settings.ieee80211hByRadio.isNotEmpty) ...[
            AppGap.md(),
            _AdvancedSwitchCard(
              identifier: 'wifi-advanced-dfs',
              title: loc(context).dynamicFrequencySelection,
              description: loc(context).dfsDescription,
              value: settings.isDfsEnabled,
              busy: busy,
              onChanged: notifier.setDfsEnabled,
            ),
          ],
        ],
      ),
    );

    return AppResponsiveLayout(
      mobile: (ctx) => content,
      desktop: (ctx) => Center(
          child: SizedBox(
              width: ctx.colWidth(8, baseColumns: 12), child: content)),
    );
  }
}

/// One card per switch: the title beside the switch, the description under
/// both. The DFS card's shape, now shared by the two steering cards.
///
/// Not `SwitchBlock`: it has no busy state, and every switch on this tab shows
/// the save in flight (#1542).
class _AdvancedSwitchCard extends StatelessWidget {
  final String identifier;
  final String title;
  final String description;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _AdvancedSwitchCard({
    required this.identifier,
    required this.title,
    required this.description,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBlock(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: AppText.labelLarge(title)),
                AppSwitch(
                  identifier: identifier,
                  value: value,
                  // Same busy treatment the rule rows carry — see
                  // `usp_single_port_tab.dart` for why a null `onChanged` was
                  // not one (#1542). `busy` here *is* `status.isSaving`.
                  isLoading: busy,
                  busySemanticLabel: busy ? loc(context).processing : null,
                  onChanged: busy ? null : onChanged,
                ),
              ],
            ),
            AppGap.md(),
            AppText.bodyMedium(
              description,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
