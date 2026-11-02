import 'package:flutter/widgets.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_form_validator.dart';

/// A [WanFieldErrors] key, or one of [WanRefusalNames] a refused save
/// carries, as the message the page shows. A field check and the same check
/// the firmware makes read the same.
///
/// [min] and [max] are the range a [WanFieldErrors.outOfRange] or
/// [WanFieldErrors.tooLong] key was checked against.
String localizeWanFieldError(BuildContext context, String key,
    {int? min, int? max}) {
  final l = loc(context);
  return switch (key) {
    WanFieldErrors.required => l.invalidInput,
    WanFieldErrors.invalidIp ||
    WanRefusalNames.invalidServer ||
    WanRefusalNames.invalidIpAddress =>
      l.invalidIpAddress,
    WanFieldErrors.reservedIp => l.reservedIpNotAllowed,
    WanFieldErrors.invalidMask ||
    WanRefusalNames.invalidPrefixLength =>
      l.invalidSubnetMask,
    WanFieldErrors.invalidGateway ||
    WanRefusalNames.invalidGateway =>
      l.invalidGatewayIpAddress,
    WanRefusalNames.invalidDns ||
    WanRefusalNames.invalidPrimaryDns =>
      l.invalidDns,
    WanFieldErrors.outOfRange when min != null && max != null =>
      l.valueOutOfRange(min, max),
    WanFieldErrors.tooLong when max != null => l.maxCharacters(max),
    _ => l.invalidInput,
  };
}

/// The message for a failed WAN save: a refusal the firmware named (an
/// [InvalidInputError] whose `field` is one of [WanRefusalNames]) reads as
/// that check, anything else as [localizeServiceError] reads it.
String localizeWanSaveError(BuildContext context, Object error) =>
    error is InvalidInputError && WanRefusalNames.all.contains(error.field)
        ? localizeWanFieldError(context, error.field!)
        : localizeServiceError(context, error);

/// [localizeWanFieldError] for a nullable [key]: null when the field passes.
String? wanFieldErrorText(BuildContext context, String? key,
        {int? min, int? max}) =>
    key == null
        ? null
        : localizeWanFieldError(context, key, min: min, max: max);
