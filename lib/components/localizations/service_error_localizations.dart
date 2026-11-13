import 'package:flutter/widgets.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// Central mapper: turns a [ServiceError] into a localized, user-facing message.
///
/// This is the ONLY place error types become display strings. The Service layer
/// produces typed [ServiceError]s (carrying diagnostic `code`/`detail`); the
/// Provider layer passes them through untouched; the View calls this with a
/// [BuildContext] to localize.
///
/// Design:
/// - Most subtypes map purely by TYPE → one l10n string. `detail`/`code` are
///   diagnostic only and are NOT shown (they are firmware/WASM technical text).
/// - Batch errors ([UspPartialFailureError]/[UspCompleteFailureError]) are
///   containers; we localize the reason the router named
///   ([UspErrorDetail.refusalReason]), else the FIRST failure's code, so the
///   user sees a concrete, actionable message (not a vague "N items failed").
/// - [UnexpectedError] is the one fallback type with no type-specific meaning,
///   so its `detail` is surfaced when present.
///
/// The `switch` is exhaustive over the sealed hierarchy — adding a new
/// [ServiceError] subtype will produce a compile-time warning here, forcing a
/// localization decision.
String localizeServiceError(BuildContext context, Object error) {
  final l = loc(context);
  // Non-ServiceError (shouldn't normally reach here, but be defensive).
  if (error is! ServiceError) return l.errorUnexpected;
  return switch (error) {
    NotAuthenticatedError() => l.errorNotAuthenticated,
    InvalidCredentialsError() => l.errorInvalidCredentials,
    SessionTokenExpiredError() => l.errorSessionExpired,
    InvalidSessionTokenError() => l.errorInvalidSessionToken,
    UnauthorizedError() => l.errorUnauthorized,
    ResourceNotFoundError() => l.errorResourceNotFound,
    InvalidInputError() => l.errorInvalidInput,
    NetworkError() => l.errorNetwork,
    ConnectivityError() => l.errorConnectivity,
    TimeoutError() => l.errorTimeout,
    SavedButUnconfirmedError() => l.errorSavedButUnconfirmed,
    SaveDiscardedForRouterRowsError() => l.errorSaveDiscardedForRouterRows,
    ServiceNotInitializedError() => l.errorServiceNotReady,
    // Batch: show the first failure's concrete message (actionable).
    UspPartialFailureError(:final failures) =>
      _localizeBatch(context, failures),
    UspCompleteFailureError(:final failures) =>
      _localizeBatch(context, failures),
    // Fallback: no type-specific semantics — surface detail if present.
    UnexpectedError(:final detail) => detail ?? l.errorUnexpected,
    // Infrastructure-level: caught at session/auth layer, never reaches UI.
    StorageError() => l.errorUnexpected,
    SerialNumberMismatchError() => l.errorUnexpected,
    // The user's own cancel: callers return before localizing it.
    OperationCancelledError() => l.errorUnexpected,
  };
}

/// Localizes a batch failure: by the reason the router named, else by the
/// FIRST entry's fault code.
///
/// Rationale: "N settings failed" is unactionable. Showing the first concrete
/// error lets the user fix it; the next save surfaces the next failure.
///
/// A refused Set lists every leaf it carried under the same code, and only the
/// refused leaf names the reason; it need not be listed first (bench
/// 2026-10-12, FWDEV#204). So every entry is looked at for a reason before the
/// first entry's code is used. The reason is [UspErrorDetail.refusalReason],
/// read in the USP layer; this file does not read `errorMessage`.
String _localizeBatch(BuildContext context, List<UspErrorDetail> failures) {
  final l = loc(context);
  if (failures.isEmpty) return l.errorUnexpected;
  for (final failure in failures) {
    final refusal = _localizeRefusalReason(l, failure.refusalReason);
    if (refusal != null) return refusal;
  }
  return _localizeFaultCode(context, failures.first.errorCode);
}

/// The message for the reason a refusal named; null for
/// [UspRefusalReason.unknown], which falls back to the fault code.
String? _localizeRefusalReason(AppLocalizations l, UspRefusalReason reason) =>
    switch (reason) {
      UspRefusalReason.rulesOverlap => l.errorRefusedRulesOverlap,
      UspRefusalReason.tooManyRules => l.errorRefusedTooManyRules,
      UspRefusalReason.invalidInternalServerIpAddress =>
        l.errorRefusedInvalidInternalServerIpAddress,
      UspRefusalReason.descriptionTooLong => l.errorRefusedDescriptionTooLong,
      UspRefusalReason.invalidDestinationIpAddress =>
        l.errorRefusedInvalidDestinationIpAddress,
      UspRefusalReason.invalidDestinationMacAddress =>
        l.errorRefusedInvalidDestinationMacAddress,
      UspRefusalReason.multipleDestinations =>
        l.errorRefusedMultipleDestinations,
      UspRefusalReason.invalidSourceRestriction =>
        l.errorRefusedInvalidSourceRestriction,
      UspRefusalReason.noPortRanges => l.errorRefusedNoPortRanges,
      UspRefusalReason.invalidPortRange => l.errorRefusedInvalidPortRange,
      UspRefusalReason.invalidPort => l.errorRefusedInvalidPort,
      UspRefusalReason.descriptionInUse => l.errorRefusedDescriptionInUse,
      UspRefusalReason.unknown => null,
    };

/// Maps a single USP fault code to a localized message.
///
/// Mirrors the fault-code arm of `_mapProtocolError` in
/// `lib/core/usp/errors/usp_error.dart` — the two MUST stay in sync. The fetch
/// path (string → `mapUspErrorToServiceError`) and the write path (envelope →
/// this batch localizer) otherwise disagree on the same firmware code (e.g. a
/// 9001 would localize differently depending on which path produced it).
///
/// Codes:
/// - 7004/7005/7006 (TR-369) + 9008 (bbfdm non-writable) → invalid input
/// - 7016/7026/7027 (TR-369 not found) + 9005/9007 (bbfdm) → resource not found
/// - 9001 (bbfdm request denied) → unauthorized
/// - 7022 (TR-369 command failure — the agent refused the command) → command
///   refused. Reached via `_mapOperationError`, not `_mapProtocolError`, which is
///   the one asymmetry in the "mirrors" rule above; see PrivacyGUI#1533.
/// - 9999 (WASM client transport failure — never reached the router) → network
/// - 9997 (input the WASM client refused before sending) → invalid input, as
///   `mapUspErrorToServiceError` reads a `Validation error:`
/// - 9998 (an answer the WASM client could not decode) → generic, named so the
///   mirror of `_mapProtocolError`'s 9998 arm is visible (#1787)
/// - anything else → generic fallback (firmware vendor codes are an open set;
///   we deliberately do NOT surface the raw firmware `errorMessage` here).
String _localizeFaultCode(BuildContext context, int code) {
  final l = loc(context);
  return switch (code) {
    7004 || 7005 || 7006 || 9008 || 9997 => l.errorInvalidInput,
    7016 || 7026 || 7027 || 9005 || 9007 => l.errorResourceNotFound,
    7022 => l.errorCommandRefused,
    9001 => l.errorUnauthorized,
    9998 => l.errorUnexpected,
    9999 => l.errorNetwork,
    _ => l.errorUnexpected,
  };
}
