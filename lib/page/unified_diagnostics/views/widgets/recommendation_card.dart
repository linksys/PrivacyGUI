import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_state.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationUIModel rec;

  const RecommendationCard({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: colorScheme.tertiary,
              size: 24,
            ),
            AppGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall(_getTitle(context, rec.titleKey)),
                  AppGap.xs(),
                  AppText.bodySmall(
                      _getDescription(context, rec.descriptionKey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(BuildContext context, String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_title' =>
        loc(context).diagnosticsRecWanDownTitle,
      'diagnostics_rec_no_ip_title' => loc(context).diagnosticsRecNoIpTitle,
      'diagnostics_rec_dhcp_fail_title' =>
        loc(context).diagnosticsRecDhcpFailTitle,
      'diagnostics_rec_gateway_title' =>
        loc(context).diagnosticsRecGatewayTitle,
      'diagnostics_rec_dns_fail_title' =>
        loc(context).diagnosticsRecDnsFailTitle,
      'diagnostics_rec_dns_lookup_fail_title' =>
        loc(context).diagnosticsRecDnsLookupFailTitle,
      'diagnostics_rec_internet_title' =>
        loc(context).diagnosticsRecInternetTitle,
      'diagnostics_rec_slow_download_title' =>
        loc(context).diagnosticsRecSlowDownloadTitle,
      'diagnostics_rec_slow_upload_title' =>
        loc(context).diagnosticsRecSlowUploadTitle,
      'diagnostics_rec_weak_wifi_title' =>
        loc(context).diagnosticsRecWeakWifiTitle,
      'diagnostics_rec_many_devices_title' =>
        loc(context).diagnosticsRecManyDevicesTitle,
      'diagnostics_rec_bandwidth_hog_title' =>
        loc(context).diagnosticsRecBandwidthHogTitle,
      'diagnostics_rec_bottleneck_title' =>
        loc(context).diagnosticsRecBottleneckTitle,
      _ => key,
    };
  }

  String _getDescription(BuildContext context, String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_desc' => loc(context).diagnosticsRecWanDownDesc,
      'diagnostics_rec_no_ip_desc' => loc(context).diagnosticsRecNoIpDesc,
      'diagnostics_rec_dhcp_fail_desc' =>
        loc(context).diagnosticsRecDhcpFailDesc,
      'diagnostics_rec_gateway_desc' => loc(context).diagnosticsRecGatewayDesc,
      'diagnostics_rec_dns_fail_desc' => loc(context).diagnosticsRecDnsFailDesc,
      'diagnostics_rec_dns_lookup_fail_desc' =>
        loc(context).diagnosticsRecDnsLookupFailDesc,
      'diagnostics_rec_internet_desc' =>
        loc(context).diagnosticsRecInternetDesc,
      'diagnostics_rec_slow_download_desc' =>
        loc(context).diagnosticsRecSlowDownloadDesc,
      'diagnostics_rec_slow_upload_desc' =>
        loc(context).diagnosticsRecSlowUploadDesc,
      'diagnostics_rec_weak_wifi_desc' =>
        loc(context).diagnosticsRecWeakWifiDesc,
      'diagnostics_rec_many_devices_desc' =>
        loc(context).diagnosticsRecManyDevicesDesc,
      'diagnostics_rec_bandwidth_hog_desc' =>
        loc(context).diagnosticsRecBandwidthHogDesc,
      'diagnostics_rec_bottleneck_desc' =>
        loc(context).diagnosticsRecBottleneckDesc,
      _ => key,
    };
  }
}
