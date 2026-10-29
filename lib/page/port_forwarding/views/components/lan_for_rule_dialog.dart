import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

/// The router's LAN address and mask, for a forwarding dialog's LAN-host check.
///
/// Awaited rather than read with `valueOrNull`, as the static routing page does
/// (#1082): a fast tap while `lanDataProvider` is still loading would otherwise
/// open the dialog with the check off. Null when it cannot be read, after
/// telling the user why; the caller then does not open the dialog.
Future<({String ip, String mask})?> lanForRuleDialog(
    BuildContext context, WidgetRef ref) async {
  try {
    final lan = await ref.read(lanDataProvider.future);
    return (ip: lan.model.ipAddress, mask: lan.model.subnetMask);
  } on ServiceError catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
    return null;
  }
}
