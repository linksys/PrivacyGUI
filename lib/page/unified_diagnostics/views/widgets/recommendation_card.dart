import 'package:flutter/material.dart';
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
      child: AppCard(
        child: Padding(
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
                    AppText.titleSmall(_getRecTitle(rec.titleKey)),
                    AppGap.xs(),
                    AppText.bodySmall(_getRecDescription(rec.descriptionKey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecTitle(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_title' => 'WAN Connection Down',
      'diagnostics_rec_no_ip_title' => 'No IP Address',
      'diagnostics_rec_dhcp_fail_title' => 'DHCP Failed',
      'diagnostics_rec_gateway_title' => 'Gateway Unreachable',
      'diagnostics_rec_dns_fail_title' => 'DNS Not Responding',
      'diagnostics_rec_dns_lookup_fail_title' => 'DNS Resolution Failed',
      'diagnostics_rec_internet_title' => 'Internet Unreachable',
      'diagnostics_rec_slow_download_title' => 'Slow Download Speed',
      'diagnostics_rec_slow_upload_title' => 'Slow Upload Speed',
      'diagnostics_rec_weak_wifi_title' => 'Weak WiFi Signal',
      'diagnostics_rec_many_devices_title' => 'Too Many Devices',
      'diagnostics_rec_bandwidth_hog_title' => 'High Bandwidth Devices',
      'diagnostics_rec_bottleneck_title' => 'Network Bottleneck Detected',
      _ => key,
    };
  }

  String _getRecDescription(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_desc' =>
        'Check your modem connection and restart if needed.',
      'diagnostics_rec_no_ip_desc' =>
        'Try renewing DHCP lease or configure static IP.',
      'diagnostics_rec_dhcp_fail_desc' =>
        'Renew DHCP lease or check ISP settings.',
      'diagnostics_rec_gateway_desc' =>
        'Check cable connections between router and modem.',
      'diagnostics_rec_dns_fail_desc' =>
        'Try using alternate DNS servers like 8.8.8.8.',
      'diagnostics_rec_dns_lookup_fail_desc' =>
        'DNS servers reachable but cannot resolve names. Try alternate DNS like 8.8.8.8 or 1.1.1.1.',
      'diagnostics_rec_internet_desc' =>
        'Contact your ISP — the issue may be on their end.',
      'diagnostics_rec_slow_download_desc' =>
        'Contact your ISP about download speed issues.',
      'diagnostics_rec_slow_upload_desc' =>
        'Check for devices uploading large files.',
      'diagnostics_rec_weak_wifi_desc' =>
        'Move closer to router or add a mesh node.',
      'diagnostics_rec_many_devices_desc' =>
        'Consider enabling QoS or disconnecting unused devices.',
      'diagnostics_rec_bandwidth_hog_desc' =>
        'Some devices are using a lot of bandwidth.',
      'diagnostics_rec_bottleneck_desc' =>
        'Network latency detected at a specific hop.',
      _ => key,
    };
  }
}
