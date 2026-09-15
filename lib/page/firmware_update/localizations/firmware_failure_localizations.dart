import 'package:flutter/widgets.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';

/// Turns a [FirmwareFailure] into the sentence shown under "Update failed".
///
/// The one place that happens, which is the point of the file. Before this, the
/// notifier built the sentence itself at thirteen `_fail()` call sites — and the
/// notifier is the layer with no `BuildContext`, so every one of those sentences
/// was English and **twenty-five of twenty-six locales read English**. Moving the
/// wording here moves it to the only layer that can translate it.
///
/// The `switch` is exhaustive over [FirmwareFailureReason] and has no `default`, so
/// a new reason is a compile error rather than a fourteenth English literal. That
/// mirrors `localizeServiceError`, and the two compose rather than compete:
/// [FirmwareFailureReason.serviceError] delegates, so a `ServiceError` still becomes
/// a string in exactly one place in this repo.
///
/// Two things deliberately reach the screen untranslated, and both are placeholders
/// rather than fragments of the sentence:
///
///   * **the raw `fwup_state`**, for the two router-reported failures. `5` is the
///     only failure value this firmware publishes and it carries no reason, so it is
///     the whole diagnostic a support call has to work from.
///   * **a TR-181 bank status** (`Standby`, `Available`), for
///     [FirmwareFailureReason.bootedOldImage]. It is a data-model token, not copy;
///     translating it would make it unsearchable against the router's own output.
///
/// Sizes are the opposite case — [UspFormatters.formatBytes] runs first, because
/// `314572800` is not a size a user can read and the byte count was never the
/// diagnostic.
///
/// **The numeric placeholders are declared `String`, not `int`**, and that is the
/// same decision rather than a missed one. `instance` is a TR-181 bank number and
/// `count` is a diagnostic tally, so both have to read the way the router prints
/// them — an `int` would give `ar` and `th` locale digits for an identifier you are
/// meant to match against router output. The repo does use `int` placeholders (32 of
/// them) where the number is a real user-facing quantity; none of these three is.
String localizeFirmwareFailure(BuildContext context, FirmwareFailure? failure) {
  final l = loc(context);
  if (failure == null) return l.unknownError;

  return switch (failure.reason) {
    FirmwareFailureReason.serviceError =>
      localizeServiceError(context, failure.error!),
    FirmwareFailureReason.fileEmpty => l.firmwareFileEmpty,
    FirmwareFailureReason.fileTooSmall =>
      l.firmwareFileTooSmall(UspFormatters.formatBytes(failure.number ?? 0)),
    FirmwareFailureReason.fileTooLarge =>
      l.firmwareFileTooLarge(UspFormatters.formatBytes(failure.number ?? 0)),
    FirmwareFailureReason.fileTypeUnsupported => l.firmwareFileTypeUnsupported,
    // Reuses the picker's own empty-state sentence rather than adding a twelfth
    // key: "no image selected" is the same fact in both places, and that sentence
    // already names the two extensions that work.
    FirmwareFailureReason.noImageSelected => l.noFirmwareImageSelected,
    FirmwareFailureReason.routerReportedFailure =>
      l.firmwareRouterReportedFailure(failure.detail ?? ''),
    FirmwareFailureReason.progressStalled =>
      l.firmwareProgressStalled(failure.detail ?? ''),
    FirmwareFailureReason.progressStalledNoReading =>
      l.firmwareProgressStalledNoReading,
    FirmwareFailureReason.banksUnreadableAfterReboot =>
      l.firmwareBanksUnreadableAfterReboot,
    FirmwareFailureReason.multipleActiveBanks =>
      l.firmwareMultipleActiveBanks('${failure.number ?? 0}'),
    FirmwareFailureReason.expectedBankMissing =>
      l.firmwareExpectedBankMissing('${failure.number ?? 0}'),
    FirmwareFailureReason.bootedOldImage => l.firmwareBootedOldImage(
        '${failure.number ?? 0}',
        failure.detail ?? '',
      ),
  };
}
