import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspWifiStatusCard extends ConsumerWidget {
  final WifiData? wifiData;

  const UspWifiStatusCard({super.key, this.wifiData});

  static const _cardId = 'wifi_status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = wifiData ?? ref.watch(wifiDataProvider).valueOrNull;
    if (data == null) return const CardSkeleton.list(rows: 4);
    final radios = data.radioModels;
    if (radios.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(title: 'WiFi Status'),
            AppGap.md(),
            const EmptyState(
              icon: Icons.wifi_off,
              message: 'No WiFi radios available',
            ),
          ],
        ),
      );
    }

    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));
    final safeIndex = selectedTab.clamp(0, radios.length - 1);
    final selectedRadio = radios[safeIndex];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'WiFi Status'),
          AppGap.md(),
          // Radio tabs
          AppTabs(
            tabs: radios.map((r) => TabItem(label: r.band)).toList(),
            initialIndex: safeIndex,
            displayMode: TabDisplayMode.segmented,
            showBorder: false,
            onTabChanged: (index) =>
                ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
          ),
          AppGap.md(),
          // Selected radio content
          Expanded(
            child: SingleChildScrollView(
              child: _RadioContent(radio: selectedRadio),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioContent extends ConsumerWidget {
  final WifiRadioUIModel radio;

  const _RadioContent({required this.radio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi';
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radio toggle with status
        Block(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: radio.enable
                      ? (appColors?.semanticSuccess ?? Colors.green)
                          .withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: AppIcon.font(
                  Icons.wifi,
                  color: radio.enable
                      ? (appColors?.semanticSuccess ?? Colors.green)
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(radio.band),
                    AppText.bodySmall(
                      radio.enable ? 'Enabled' : 'Disabled',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppSwitch(
                value: radio.enable,
                onChanged: isLoading
                    ? null
                    : (value) => performUspMutation(
                          context,
                          ref,
                          loadingKey: 'wifi',
                          mutation: () => ref
                              .read(uspWifiSettingsProvider.notifier)
                              .toggleRadio(radio.instancePath, value),
                        ),
              ),
            ],
          ),
        ),
        AppGap.sm(),
        // Radio specs
        InfoGrid(
          items: [
            InfoGridItem(label: 'Channel', value: radio.channelDisplay),
            InfoGridItem(label: 'Bandwidth', value: radio.channelBandwidth),
            InfoGridItem(label: 'Tx Power', value: '${radio.txPowerPercent}%'),
            InfoGridItem(label: 'Max Rate', value: '${radio.maxBitRate} Mbps'),
          ],
        ),
        AppGap.sm(),
        // Channel edit button
        Align(
          alignment: Alignment.centerRight,
          child: AppButton.text(
            label: 'Change Channel',
            onTap: isLoading
                ? null
                : () => _showWifiChannelDialog(context, ref, radio),
          ),
        ),
        // Access Points on this radio
        if (radio.accessPoints.isNotEmpty) ...[
          AppGap.md(),
          AppText.labelMedium('Access Points'),
          AppGap.sm(),
          InfoList(
            items: radio.accessPoints
                .map((ap) => InfoListItem(
                      label: ap.enable ? 'ON' : 'OFF',
                      value: '${ap.ssidName} (${ap.securityMode})',
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _showWifiChannelDialog(
      BuildContext context, WidgetRef ref, WifiRadioUIModel radio) async {
    final result = await showAppDialog<({int channel, bool autoChannel})>(
      context: context,
      builder: (_) => WifiChannelDialog(radio: radio),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'wifi',
      mutation: () =>
          ref.read(uspWifiSettingsProvider.notifier).updateRadioChannel(
                radio.instancePath,
                channel: result.channel,
                autoChannel: result.autoChannel,
              ),
      successMessage: 'Channel updated',
    );
  }
}
