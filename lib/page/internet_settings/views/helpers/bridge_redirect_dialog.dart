import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows the post-save Bridge Mode dialog: the router is now a transparent
/// bridge and must be reached at `https://<hostName>.local`. The primary button
/// navigates the browser there (the browser handles DNS/cert/retry — the only
/// reliable cross-origin path for a self-signed `.local` host).
///
/// [navigate] defaults to the real web redirect and is injectable for tests.
Future<void> showBridgeRedirectDialog(
  BuildContext context, {
  required String hostName,
  void Function(String url) navigate = assignWebLocation,
}) {
  final url = 'https://$hostName.local';
  final l = loc(context);
  return showSimpleAppDialog<void>(
    context,
    dismissible: false,
    title: l.bridgeRedirectTitle,
    content: AppText(
      l.bridgeRedirectMessage(url),
      variant: AppTextVariant.bodyMedium,
      fontWeight: FontWeight.bold,
    ),
    actions: [
      AppButton.text(
        label: l.close,
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
      AppButton.primary(
        label: l.bridgeRedirectButton,
        onTap: () => navigate(url),
      ),
    ],
  );
}
