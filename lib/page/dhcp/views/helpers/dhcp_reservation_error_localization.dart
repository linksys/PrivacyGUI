import 'package:flutter/widgets.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

/// The message for a failed reservation save: a refusal dhcpmngr named (an
/// [InvalidInputError] whose `field` is one of [DhcpReservationRefusalNames],
/// linksys/FWDEV#211) reads as that check, anything else as
/// [localizeServiceError] reads it.
String localizeDhcpReservationSaveError(BuildContext context, Object error) {
  if (error is! InvalidInputError ||
      !DhcpReservationRefusalNames.all.contains(error.field)) {
    return localizeServiceError(context, error);
  }
  final l = loc(context);
  return switch (error.field) {
    DhcpReservationRefusalNames.invalidMac => l.invalidMacAddressFormat,
    DhcpReservationRefusalNames.invalidIp => l.invalidIpAddress,
    DhcpReservationRefusalNames.ipConflict => l.duplicateIpAddress,
    DhcpReservationRefusalNames.invalidName => l.reservationNameInvalid,
    _ => localizeServiceError(context, error),
  };
}
