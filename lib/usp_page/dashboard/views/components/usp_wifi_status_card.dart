import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_provider.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspWifiStatusCard extends ConsumerWidget {
  final UspDashboardState state;

  const UspWifiStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radios = state.wifiRadios.items;
    final ssids = state.wifiSsids.items;
    final aps = state.wifiAccessPoints.items;
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
          if (aps.isNotEmpty) ...[
            AppText.labelLarge('Access Points'),
            AppGap.sm(),
            ...aps.asMap().entries.map(
                  (entry) =>
                      _buildApRow(context, entry.key + 1, entry.value, ssids),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioSection(
      BuildContext context, WidgetRef ref, WiFiRadio radio) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi';
    final txPower = radio.transmitPower == -1 ? 100 : radio.transmitPower.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UspStatusDot(isActive: radio.enable),
              AppGap.sm(),
              AppText.labelLarge('Radio: ${radio.operatingFrequencyBand}'),
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
                              .read(uspDashboardProvider.notifier)
                              .toggleWifiRadio(radio.instancePath, value),
                        ),
              ),
            ],
          ),
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: 'Tx Power',
            value: txPower / 100,
            display: radio.transmitPower == -1 ? 'Max' : '$txPower%',
          ),
          AppGap.sm(),
          _buildLinearBar(
            context,
            label: 'Bit Rate',
            value: _normalizeBitRate(radio.maxBitRate, radio.operatingFrequencyBand) / 100,
            display: '${radio.maxBitRate} Mbps',
          ),
          AppGap.md(),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: AppText.labelLarge('Channel'),
              ),
              Expanded(
                child: AppText.bodyMedium(
                  '${radio.channel}${radio.autoChannelEnable ? ' (Auto)' : ''}',
                ),
              ),
              AppIconButton(
                icon: AppIcon.font(Icons.edit, size: 18),
                onTap: isLoading
                    ? null
                    : () => _showWifiChannelDialog(context, ref, radio),
              ),
            ],
          ),
          UspInfoRow(label: 'Bandwidth', value: radio.operatingChannelBandwidth),
          UspInfoRow(label: 'Standards', value: radio.supportedStandards),
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
          width: 80,
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
          width: 80,
          child: AppText.bodySmall(display, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  /// Normalize bit rate to a 0–100 scale based on band theoretical max.
  double _normalizeBitRate(int bitRate, String band) {
    final maxForBand = band.contains('6') ? 9600
        : band.contains('5') ? 4800
        : 600; // 2.4 GHz
    return (bitRate / maxForBand * 100).clamp(0, 100).toDouble();
  }

  Future<void> _showWifiChannelDialog(
      BuildContext context, WidgetRef ref, WiFiRadio radio) async {
    final result = await showDialog<({int channel, bool autoChannel})>(
      context: context,
      builder: (_) => WifiChannelDialog(radio: radio),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'wifi',
      mutation: () => ref.read(uspDashboardProvider.notifier).updateWifiRadioChannel(
            radio.instancePath,
            result.channel,
            result.autoChannel,
          ),
      successMessage: 'Channel updated',
    );
  }

  Widget _buildApRow(BuildContext context, int index, WiFiAccessPoint ap,
      List<WiFiSsid> ssids) {
    final ssidName = _resolveSsidName(ap.ssidReference, ssids);
    final label = ssidName ?? 'AP $index';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          UspStatusDot(isActive: ap.enable),
          AppGap.sm(),
          Expanded(child: AppText.bodyMedium(label)),
          SizedBox(
            width: 160,
            child: AppText.bodySmall(
              ap.securityModeEnabled,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 60,
            child: AppText.bodySmall(
              ap.encryptionMode,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveSsidName(String ssidReference, List<WiFiSsid> ssids) {
    if (ssidReference.isEmpty) return null;
    final normalizedRef = ssidReference.endsWith('.')
        ? ssidReference
        : '$ssidReference.';
    for (final ssid in ssids) {
      if (ssid.instancePath == normalizedRef) {
        return ssid.ssid.isNotEmpty ? ssid.ssid : null;
      }
    }
    return null;
  }
}
