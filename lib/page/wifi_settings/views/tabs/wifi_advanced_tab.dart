import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 2 — Advanced WiFi settings.
///
/// Implements:
///   - Client Steering: Device.WiFi.BandSteeringEnabled
///   - DFS (IEEE 802.11h): Device.WiFi.Radio.{i}.IEEE80211hEnabled
///
/// Node Steering and MLO require Linksys vendor extensions and are not yet
/// available via standard TR-181 paths.
class UspWifiAdvancedTab extends ConsumerWidget {
  const UspWifiAdvancedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspWifiAdvancedProvider);

    return asyncState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              AppGap.md(),
              AppText.bodyMedium(
                'Failed to load advanced settings.',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
      data: (state) => AppResponsiveLayout(
        mobile: (ctx) => _buildLayout(ctx, ref, state, width: null),
        desktop: (ctx) => _buildLayout(ctx, ref, state,
            width: ctx.colWidth(8, baseColumns: 12)),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    UspWifiAdvancedState state, {
    required double? width,
  }) {
    final notifier = ref.read(uspWifiAdvancedProvider.notifier);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DFS (IEEE 802.11h) ───────────────────────────────────────
          if (state.ieee80211hByRadio.isNotEmpty) ...[
            _AdvancedCard(
              title: 'Dynamic Frequency Selection (DFS)',
              description:
                  'Enables IEEE 802.11h on 5 GHz radios, which activates '
                  'both Dynamic Frequency Selection (DFS) and Transmit '
                  'Power Control (TPC).\n\n'
                  'DFS allows the router to use 5 GHz channels shared with '
                  'radar systems. If a radar signal is detected, the router '
                  'will automatically switch to an unoccupied channel, which '
                  'may cause a brief interruption in connectivity.',
              value: state.isDfsEnabled,
              onChanged: (v) => notifier.setIeee80211hEnabled(v),
            ),
            AppGap.lg(),
          ],
        ],
      ),
    );

    if (width != null) {
      return Center(child: SizedBox(width: width, child: content));
    }
    return content;
  }
}

// ---------------------------------------------------------------------------
// Shared advanced-setting card: title + description + toggle
// ---------------------------------------------------------------------------

class _AdvancedCard extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final void Function(bool)? onChanged;

  const _AdvancedCard({
    required this.title,
    required this.description,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText.labelLarge(title)),
              AppSwitch(value: value, onChanged: onChanged),
            ],
          ),
          AppGap.md(),
          AppText.bodyMedium(
            description,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
