import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
        AiInfoRow(label: loc(context).ssid, value: ssid),
        if (password != null)
          AiInfoRow(
              label: loc(context).password, value: _maskPassword(password!)),
        if (securityMode != null)
          AiInfoRow(label: loc(context).security, value: securityMode!),
        if (band != null) AiInfoRow(label: loc(context).band, value: band!),
      ],
    );
  }

  String _maskPassword(String password) {
    return '********';
  }
}
