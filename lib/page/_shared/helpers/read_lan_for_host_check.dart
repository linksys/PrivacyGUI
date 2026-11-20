import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

/// The router's LAN address and mask, for the LAN-host check of an address
/// the app writes as a LAN host's (`lanHostIpv4Problem`, #1838): a DHCP
/// reservation, a port-forwarding target, the DMZ host.
///
/// Awaited rather than read with `valueOrNull`, as the static routing page does
/// (#1082): a fast tap while `lanDataProvider` is still loading would otherwise
/// run the check with the LAN part off. Null when it cannot be read, after
/// telling the user why; the caller then does not open its dialog or write.
///
/// Also null, at once and silently, while an earlier call is still reading:
/// the button that started it stays enabled during the read, so a second tap
/// would otherwise open a second dialog or send Reserve twice (#1838).
Future<({String ip, String mask})?> readLanForHostCheck(
    BuildContext context, WidgetRef ref) async {
  if (_reading) return null;
  _reading = true;
  try {
    final lan = await ref.read(lanDataProvider.future);
    return (ip: lan.model.ipAddress, mask: lan.model.subnetMask);
  } on ServiceError catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
    return null;
  } finally {
    _reading = false;
  }
}

/// Whether a [readLanForHostCheck] is reading. One flag for every caller, so
/// any second tap during a read does nothing, on whichever form. The read is
/// short: the dashboard reads the LAN at sign-in, so it is normally answered
/// at once.
bool _reading = false;
