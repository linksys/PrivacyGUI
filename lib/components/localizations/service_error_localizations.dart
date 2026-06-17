import 'package:flutter/widgets.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
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
///   containers; we localize the FIRST failure's code so the user sees a
///   concrete, actionable message (not a vague "N items failed").
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
  };
}

/// Localizes a batch failure by its FIRST entry's fault code.
///
/// Rationale: "N settings failed" is unactionable. Showing the first concrete
/// error lets the user fix it; the next save surfaces the next failure.
String _localizeBatch(BuildContext context, List<UspErrorDetail> failures) {
  final l = loc(context);
  if (failures.isEmpty) return l.errorUnexpected;
  final first = failures.first;
  // Map the fault code to a typed l10n string using UspErrorDetail helpers.
  if (first.isParameterNotFound || first.isObjectNotFound) {
    return l.errorResourceNotFound;
  }
  if (first.isInvalidParameterName ||
      first.isInvalidParameterValue ||
      first.isParameterNotWritable) {
    return l.errorInvalidInput;
  }
  return l.errorUnexpected;
}
