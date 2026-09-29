import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A card for a single DHCP renew action (IPv4 or IPv6).
///
/// Displays the protocol label, current IP address, and a renew button.
class UspRenewActionCard extends StatelessWidget {
  final String protocolLabel;
  final String? ipAddress;

  /// What to show INSTEAD of an address when there is none to show.
  ///
  /// Exists because `ipAddress: null` and `ipAddress: ''` both rendered '--', so a caller
  /// had no way to say "we could not read this" as distinct from "there is no address"
  /// (linksys/PrivacyGUI#1613). Defaults to '--', which is the right label for a device
  /// that reported no address.
  final String? addressLabel;
  final bool isLoading;
  final VoidCallback? onRenew;

  const UspRenewActionCard({
    super.key,
    required this.protocolLabel,
    this.ipAddress,
    this.addressLabel,
    this.isLoading = false,
    this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodySmall(loc(context).protocolDhcp(protocolLabel)),
              AppGap.xs(),
              AppText.labelLarge(
                ipAddress?.isNotEmpty == true
                    ? ipAddress!
                    : (addressLabel ?? '--'),
              ),
            ],
          ),
        ),
        AppButton.secondary(
          label: loc(context).renew,
          size: AppButtonSize.small,
          isLoading: isLoading,
          onTap: onRenew,
        ),
      ],
    );
  }
}
