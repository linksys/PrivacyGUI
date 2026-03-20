import 'package:flutter/material.dart';
import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A simple tile displaying a device's display name and MAC address.
/// Used for both the connected-devices list (feature OFF) and
/// the allowed-devices list (feature ON).
class InstantPrivacyDeviceTile extends StatelessWidget {
  final InstantPrivacyDeviceUIModel device;

  const InstantPrivacyDeviceTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppIcon.font(
            Icons.devices,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(device.displayName),
                AppText.bodySmall(
                  device.mac,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
