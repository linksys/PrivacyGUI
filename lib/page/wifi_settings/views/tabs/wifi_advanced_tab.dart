import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 2 — Advanced WiFi settings.
///
/// Implements:
///   - DFS (IEEE 802.11h): Device.WiFi.Radio.{i}.IEEE80211hEnabled
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

    if (status.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              AppGap.xl(),
              AppText.titleMedium('Unable to load advanced settings'),
              AppGap.md(),
              AppButton(
                label: 'Retry',
                onTap: () => ref
                    .read(uspWifiAdvancedProvider.notifier)
                    .fetch(forceRemote: true),
              ),
            ],
          ),
        ),
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
    final disabled = state.status.isSaving;

    if (settings.ieee80211hByRadio.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppText.bodyMedium(
            'No advanced WiFi settings available for this device.',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DFS (IEEE 802.11h) ───────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Block(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText.labelLarge(
                            'Dynamic Frequency Selection (DFS)'),
                      ),
                      AppSwitch(
                        value: settings.isDfsEnabled,
                        onChanged:
                            disabled ? null : (v) => notifier.setDfsEnabled(v),
                      ),
                    ],
                  ),
                  AppGap.md(),
                  AppText.bodyMedium(
                    'Enables IEEE 802.11h on 5 GHz radios, which activates '
                    'both Dynamic Frequency Selection (DFS) and Transmit '
                    'Power Control (TPC).\n\n'
                    'DFS allows the router to use 5 GHz channels shared with '
                    'radar systems. If a radar signal is detected, the router '
                    'will automatically switch to an unoccupied channel, which '
                    'may cause a brief interruption in connectivity.',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
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
