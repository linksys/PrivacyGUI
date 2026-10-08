import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Describe the ISP limitation without changing or disabling saved rules.
class TunnelForwardingNotice extends ConsumerWidget {
  const TunnelForwardingNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE))
      return const SizedBox.shrink();
    final kind = ref.watch(wanDataProvider).valueOrNull?.model.addressingType;
    final message = switch (kind) {
      'MAP-E' => loc(context).autoIpoeMapeForwardingNotice,
      'DS-Lite' => loc(context).autoIpoeDsliteForwardingNotice,
      'IPIP' => loc(context).autoIpoeIpipForwardingNotice,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AppText.bodyMedium(message));
  }
}
