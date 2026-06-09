import 'package:flutter/material.dart';
import '../ai_info_row.dart';

/// WiFi network settings section.
///
/// Displays SSID, password (masked), security mode, and band.
class WifiSection extends StatelessWidget {
  final String ssid;
  final String? password;
  final String? securityMode;
  final String? band;

  const WifiSection({
    super.key,
    required this.ssid,
    this.password,
    this.securityMode,
    this.band,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AiInfoRow(label: 'SSID', value: ssid),
        if (password != null)
          AiInfoRow(label: 'Password', value: _maskPassword(password!)),
        if (securityMode != null)
          AiInfoRow(label: 'Security', value: securityMode!),
        if (band != null) AiInfoRow(label: 'Band', value: band!),
      ],
    );
  }

  String _maskPassword(String password) {
    return '********';
  }
}
