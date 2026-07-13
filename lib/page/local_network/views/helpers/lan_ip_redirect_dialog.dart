import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows the post-save LAN IP dialog: the router LAN IP just changed, so the
/// old address is no longer reachable on this origin. The primary button
/// navigates the browser to `https://<hostName>.local`, letting the browser
/// handle DNS (mDNS) / cert / retry — the only reliable path to reach the
/// router at its new address once the client picks up a new DHCP lease.
///
/// [navigate] defaults to the real web redirect and is injectable for tests.
Future<void> showLanIpRedirectDialog(
  BuildContext context, {
  required String hostName,
  void Function(String url) navigate = assignWebLocation,
}) {
  final url = 'https://$hostName.local';
  final l = loc(context);
  return showSimpleAppDialog<void>(
    context,
    dismissible: false,
    title: l.lanIpRedirectTitle,
    content: AppText(
      l.lanIpRedirectMessage(url),
      variant: AppTextVariant.bodyMedium,
      fontWeight: FontWeight.bold,
    ),
    actions: [
      // No dismiss/close action: once the LAN IP changed, the router is
      // unreachable on this origin, so redirecting to https://<hostName>.local
      // is the only valid next step. The dialog is non-dismissible (above).
      AppButton.primary(
        label: l.lanIpRedirectButton,
        onTap: () => navigate(url),
      ),
    ],
  );
}
