import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import '../ai_info_row.dart';

/// LAN configuration section.
///
/// Displays LAN IP, subnet mask, DHCP settings, DNS servers, and IPv6 info.
class LanSection extends StatelessWidget {
  final String ipAddress;
  final String subnetMask;
  final bool? dhcpEnabled;
  final String? dhcpRange;
  final String? dnsServers;
  final bool? ipv6Enabled;
  final List<String>? ipv6Addresses;

  const LanSection({
    super.key,
    required this.ipAddress,
    required this.subnetMask,
    this.dhcpEnabled,
    this.dhcpRange,
    this.dnsServers,
    this.ipv6Enabled,
    this.ipv6Addresses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AiInfoRow(label: loc(context).lanIpAddress, value: ipAddress),
        AiInfoRow(label: loc(context).subnetMask, value: subnetMask),
        if (dhcpEnabled != null)
          AiInfoRow(
            label: loc(context).dhcpServer,
            value: dhcpEnabled! ? loc(context).enabled : loc(context).disabled,
          ),
        if (dhcpEnabled == true && dhcpRange != null)
          AiInfoRow(label: loc(context).dhcpIpRange, value: dhcpRange!),
        if (dnsServers != null && dnsServers!.isNotEmpty)
          AiInfoRow(label: loc(context).dnsServers, value: dnsServers!),
        if (ipv6Addresses != null && ipv6Addresses!.isNotEmpty)
          for (final addr in ipv6Addresses!)
            AiInfoRow(label: loc(context).lanIpv6, value: addr),
        if ((ipv6Addresses == null || ipv6Addresses!.isEmpty) &&
            ipv6Enabled == true)
          AiInfoRow(
              label: loc(context).ipv6, value: loc(context).enabledNoAddress),
      ],
    );
  }
}
