import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
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

    return DashboardCardTemplate(
      title: loc(context).wifiStatus,
      titleBadge: AppBadge(
          label: loc(context)
              .nRadios(enabledRadios.toString(), radios.length.toString())),
      // How many radios are on, over how many there are — the same fact the
      // badge states, in the bare form the tile has room for (`nRadios` spells
      // it out in words, which at two columns would be the only thing that
      // fits). Neither number alone is a reading of the card: three of three is
      // healthy, two of three is a band switched off.
      popupValue: '$enabledRadios/${radios.length}',
      detailRoute: RouteNamed.uspWifiSettings,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: radios
            .map((radio) => _buildRadioSection(context, ref, radio))
            .toList(),
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
              AppText.labelLarge(loc(context).radioBand(radio.band)),
            ],
          ),
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: loc(context).txPower,
            value: radio.txPowerPercent / 100,
            // -1 means max; mirrors WifiRadioUIModel.txPowerDisplay but
            // localizes the "Max" label (the model getter stays raw for
            // PDF/AI export callers).
            display: radio.transmitPower == -1
                ? loc(context).maxShort
                : radio.txPowerDisplay,
          ),
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: loc(context).bitRate,
            value: radio.bitRateNormalized / 100,
            display: '${radio.maxBitRate} Mbps',
          ),
          AppGap.md(),
          // Size the label column from the width THIS ROW is given (via a
          // LayoutBuilder), not from screen width. `context.colWidth(2)`
          // answered a page-scale question (122.25px of the 260.5px this card
          // shrinks to at 601px), over-claiming the row and silently clipping
          // the value against the card surface with no overflow raised (#1251;
          // density design §2.2/§2.8). This is the same fix #1231 applied to
          // UspInfoRow; the row keeps its trailing edit button, so it reuses
          // that rule's constants rather than the UspInfoRow widget itself.
          LayoutBuilder(
            builder: (context, constraints) {
              final labelWidth = (constraints.maxWidth * kUspLabelShare)
                  .clamp(0.0, kUspLabelMaxWidth);
              return Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: AppText.labelLarge(loc(context).channel),
                  ),
                  Expanded(
                    child: AppText.bodyMedium(
                        wifiDisplayValue(context, radio.channelDisplay)),
                  ),
                  AppIconButton(
                    icon: AppIcon.font(Icons.edit, size: 18),
                    onTap: isLoading
                        ? null
                        : () => _showWifiChannelDialog(context, ref, radio),
                  ),
                ],
              );
            },
          ),
          UspInfoRow(
              label: loc(context).bandwidth,
              value: wifiDisplayValue(context, radio.channelBandwidth)),
          UspInfoRow(
              label: loc(context).standards, value: radio.supportedStandards),
          // Access Points on this radio
          if (radio.accessPoints.isNotEmpty) ...[
            AppGap.md(),
            AppText.labelLarge(loc(context).accessPoints),
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
      successMessage: loc(context).channelUpdated,
    );
  }

  Widget _buildApRow(BuildContext context, WifiAccessPointUIModel ap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      // The two trailing value columns were sized with `context.colWidth(2)` /
      // `colWidth(1)` — screen-derived, so inside this 260.5px card at 601px
      // they claimed 122.25 + 53.13 = 175px (67% of the card) and starved the
      // SSID Expanded to ~61px. Size them from the width THIS ROW is given
      // instead (#1251), keeping the SSID the dominant column. Fractions hold
      // the old ~2:1 security:encryption split; the ceilings keep a wide row
      // from opening an absurd gutter, matching the row-derived rule from #1231.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final securityWidth =
              (constraints.maxWidth * 0.28).clamp(0.0, kUspLabelMaxWidth);
          final encryptionWidth =
              (constraints.maxWidth * 0.14).clamp(0.0, kUspLabelMaxWidth / 2);
          return Row(
            children: [
              UspStatusDot(isActive: ap.enable),
              AppGap.sm(),
              Expanded(child: AppText.bodyMedium(ap.ssidName)),
              SizedBox(
                width: securityWidth,
                child: AppText.bodySmall(
                  wifiDisplayValue(context, ap.securityMode),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                width: encryptionWidth,
                child: AppText.bodySmall(
                  wifiDisplayValue(context, ap.encryptionMode),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
