import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

/// Localized display label for a [UspWanConnectionType].
///
/// Single source of truth for the connection-type label so every view renders
/// the same text and a new enum value only has to be handled once. All labels
/// (including PPTP / L2TP) resolve through the l10n keys rather than hardcoded
/// strings.
extension UspWanConnectionTypeLabel on UspWanConnectionType {
  String localizedLabel(BuildContext context) {
    final l = loc(context);
    return switch (this) {
      UspWanConnectionType.dhcp => l.connectionTypeDhcp,
      UspWanConnectionType.staticIp => l.staticIp,
      UspWanConnectionType.pppoe => l.connectionTypePppoe,
      UspWanConnectionType.pptp => l.connectionTypePptp,
      UspWanConnectionType.l2tp => l.connectionTypeL2tp,
      UspWanConnectionType.bridge => l.connectionTypeBridge,
    };
  }
}
