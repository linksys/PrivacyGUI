import 'package:flutter/material.dart';

/// Tab 3 — MAC Filtering (placeholder).
///
/// TR-181 standard only supports allow-list mode (AllowedMACAddress), not
/// the deny-list (block specific devices) functionality required here.
/// Deny-list mode requires Linksys vendor-specific TR-181 extensions which
/// are not yet confirmed. This tab is reserved for future implementation.
class UspWifiMacFilteringTab extends StatelessWidget {
  const UspWifiMacFilteringTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
