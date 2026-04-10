import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspWifiStatusCard extends ConsumerWidget {
  final WifiData? wifiData;

  const UspWifiStatusCard({super.key, this.wifiData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = wifiData ?? ref.watch(wifiDataProvider).valueOrNull;
    if (data == null) return const CardSkeleton.list(rows: 4);
    final radios = data.radioModels;
    final enabledRadios = radios.where((r) => r.enable).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('WiFi Status'),
              AppText.labelLarge('$enabledRadios / ${radios.length} radios'),
            ],
          ),
          AppGap.xl(),
          ...radios.map((radio) => _buildRadioSection(context, ref, radio)),
        ],
      ),
    );
  }

  Widget _buildRadioSection(
    BuildContext context,
    WidgetRef ref,
    WifiRadioUIModel radio,
  ) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UspStatusDot(isActive: radio.enable),
              AppGap.sm(),
              AppText.labelLarge('Radio: ${radio.band}'),
              const Spacer(),
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
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: 'Tx Power',
            value: radio.txPowerPercent / 100,
            display: radio.txPowerDisplay,
          ),
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: 'Bit Rate',
            value: radio.bitRateNormalized / 100,
            display: '${radio.maxBitRate} Mbps',
          ),
          AppGap.md(),
          Row(
            children: [
              SizedBox(
                width: context.colWidth(2),
                child: AppText.labelLarge('Channel'),
              ),
              Expanded(
                child: AppText.bodyMedium(radio.channelDisplay),
              ),
              AppIconButton(
                icon: AppIcon.font(Icons.edit, size: 18),
                onTap: isLoading
                    ? null
                    : () => _showWifiChannelDialog(context, ref, radio),
              ),
            ],
          ),
          UspInfoRow(label: 'Bandwidth', value: radio.channelBandwidth),
          UspInfoRow(label: 'Standards', value: radio.supportedStandards),
          // Access Points on this radio
          if (radio.accessPoints.isNotEmpty) ...[
            AppGap.md(),
            AppText.labelLarge('Access Points'),
            AppGap.sm(),
            ...radio.accessPoints.map((ap) => _buildApRow(context, ap)),
          ],
        ],
      ),
    );
  }

  Widget _buildLinearBar(
    BuildContext context, {
    required String label,
    required double value,
    required String display,
  }) {
    return Row(
      children: [
        SizedBox(
          width: context.colWidth(1),
          child: AppText.labelLarge(label),
        ),
        Expanded(
          child: AppLoader(
            variant: LoaderVariant.linear,
            value: value.clamp(0.0, 1.0),
          ),
        ),
        AppGap.sm(),
        SizedBox(
          width: context.colWidth(1),
          child: AppText.bodySmall(display, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Future<void> _showWifiChannelDialog(
      BuildContext context, WidgetRef ref, WifiRadioUIModel radio) async {
    final result = await showDialog<({int channel, bool autoChannel})>(
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

  Widget _buildApRow(BuildContext context, WifiAccessPointUIModel ap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          UspStatusDot(isActive: ap.enable),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(ap.ssidName)),
          SizedBox(
            width: context.colWidth(2),
            child: AppText.bodySmall(
              ap.securityMode,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: context.colWidth(1),
            child: AppText.bodySmall(
              ap.encryptionMode,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
