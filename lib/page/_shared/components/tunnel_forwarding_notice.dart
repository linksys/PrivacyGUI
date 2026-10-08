import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Describe the ISP limitation without changing or disabling saved rules.
class TunnelForwardingNotice extends ConsumerWidget {
  const TunnelForwardingNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(wanDataProvider).valueOrNull?.model.addressingType;
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final message = switch (kind) {
      'MAP-E' => ja
          ? 'MAP-Eでは、ISPから割り当てられたポートのみIPv4の着信に利用できます。'
          : 'MAP-E: only ports assigned by your ISP can receive inbound IPv4 connections.',
      'DS-Lite' => ja
          ? 'DS-LiteのIPv4着信はISP側のNATに依存します。ルーターのポート設定だけでは開放できません。'
          : 'DS-Lite: inbound IPv4 access is controlled by your ISP’s NAT. Local port rules alone cannot open it.',
      'IPIP' => ja
          ? 'IPIPのIPv4着信は、ISPが提供するアドレスとサービスの条件に依存します。'
          : 'IPIP: inbound IPv4 access depends on the address and service supplied by your ISP.',
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AppText.bodyMedium(message));
  }
}
