import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Error categories from the Rust WASM client's UspError hierarchy.
enum UspErrorCategory {
  transport,
  protocol,
  auth,
  operation,
  validation,
}

/// Parsed representation of a USP error string thrown by the WASM client.
///
/// The WASM client throws plain Dart [String] values (not [Exception]) with
/// a consistent format: `"{Op} failed: {category}: {detail}"`.
///
/// This class extracts structured fields from that string so the Service layer
/// can map it to the appropriate [ServiceError] subtype.
class UspError {
  /// The USP operation that failed (e.g., "Get", "Set", "Add", "Delete",
  /// "Operate", "Login").
  final String operation;

  /// High-level error category.
  final UspErrorCategory category;

  /// Human-readable detail message (everything after the category prefix).
  final String message;

  /// USP fault code from the router, if present (e.g., 7004, 7026).
  /// Extracted from `(code: XXXX)` suffix in Protocol errors.
  final int? faultCode;

  /// HTTP status code, if this is a Transport/HTTP error (e.g., 401, 504).
  final int? httpStatus;

  /// The original raw error string from WASM.
  final String rawError;

  const UspError({
    required this.operation,
    required this.category,
    required this.message,
    required this.rawError,
    this.faultCode,
    this.httpStatus,
  });

  @override
  String toString() => rawError;
}

// =============================================================================
// Parser
// =============================================================================

final _opPrefix = RegExp(r'^(\w+) failed: (.+)$', dotAll: true);
final _faultCode = RegExp(r'\(code:\s*(\d+)\)');
final _httpStatus = RegExp(r'HTTP error: HTTP (\d+)');

/// Attempts to parse a raw USP error string into a structured [UspError].
///
/// Returns `null` if the string does not match the expected USP error format.
UspError? parseUspError(Object error) {
  final raw = error.toString();
  final opMatch = _opPrefix.firstMatch(raw);
  if (opMatch == null) return null;

  final operation = opMatch.group(1)!;
  final rest = opMatch.group(2)!;

  final (category, message) = _parseCategoryAndMessage(rest);

  final faultCodeMatch = _faultCode.firstMatch(raw);
  final httpStatusMatch = _httpStatus.firstMatch(raw);

  return UspError(
    operation: operation,
    category: category,
    message: message,
    rawError: raw,
    faultCode:
        faultCodeMatch != null ? int.parse(faultCodeMatch.group(1)!) : null,
    httpStatus:
        httpStatusMatch != null ? int.parse(httpStatusMatch.group(1)!) : null,
  );
}

(UspErrorCategory, String) _parseCategoryAndMessage(String rest) {
  if (rest.startsWith('Transport error: ')) {
    return (UspErrorCategory.transport, rest.substring(17));
  }
  if (rest.startsWith('Protocol error: ')) {
    return (UspErrorCategory.protocol, rest.substring(16));
  }
  if (rest.startsWith('Authentication error: ')) {
    return (UspErrorCategory.auth, rest.substring(22));
  }
  if (rest.startsWith('Operation error: ')) {
    return (UspErrorCategory.operation, rest.substring(17));
  }
  if (rest.startsWith('Validation error: ')) {
    return (UspErrorCategory.validation, rest.substring(18));
  }
  // Fallback — treat entire rest as message under protocol (most common
  // for error strings that don't perfectly match a known prefix).
  return (UspErrorCategory.protocol, rest);
}

// =============================================================================
// ServiceError mapping
// =============================================================================

/// Converts any caught error from a USP codegen call into a [ServiceError].
///
/// ## Error Contract (the match points this function depends on)
///
/// Errors reach this function from THREE sources. Each match point below is a
/// brittle coupling — if the source string/code changes, the mapping silently
/// breaks. This table lists ONLY the values actually compared against (not the
/// full set of strings the sources can emit). Keep it in sync with the sources.
///
/// ### Source 1 — Rust WASM client string `Display` (`usp-client/src/error.rs`)
///
/// | Dart match string         | Rust variant (error.rs)              | → ServiceError              |
/// |---------------------------|--------------------------------------|-----------------------------|
/// | `'Invalid credentials'`   | `AuthError::InvalidCredentials`      | InvalidCredentialsError     |
/// | `'Session expired'`       | `AuthError::SessionExpired`          | SessionTokenExpiredError    |
/// | `'Invalid token'`         | `AuthError::InvalidToken`            | InvalidSessionTokenError    |
/// | `'Permission denied'`     | `AuthError::PermissionDenied`        | UnauthorizedError           |
/// | `'Authentication required'`| `AuthError::AuthenticationRequired` | NotAuthenticatedError       |
/// | `'Request timeout'`       | `TransportError::Timeout`            | NetworkError                |
/// | `'Connection refused'`    | `TransportError::ConnectionRefused`  | ConnectivityError           |
/// | HTTP status `401`         | `HTTP error: HTTP 401` (regex)       | NotAuthenticatedError       |
///
/// ### Source 2 — fault codes in `(code: XXXX)`, passed through from firmware
/// (7xxx = TR-369 standard; 9xxx = bbfdm vendor). Rust only relays these.
///
/// | code | meaning                          | → ServiceError          |
/// |------|----------------------------------|-------------------------|
/// | 7004 | parameter not writable           | InvalidInputError       |
/// | 7005 | invalid parameter name           | InvalidInputError       |
/// | 7006 | invalid parameter value          | InvalidInputError       |
/// | 7026 | parameter (path) not found       | ResourceNotFoundError   |
/// | 7027 | object not found                 | ResourceNotFoundError   |
/// | 9001 | bbfdm: request denied            | UnauthorizedError       |
/// | 9005 | bbfdm: invalid/unimplemented param | ResourceNotFoundError |
/// | 9007 | bbfdm: (resource not found)      | ResourceNotFoundError   |
/// | 9008 | bbfdm: non-writable parameter    | InvalidInputError       |
///
/// ### Source 3 — Dart codegen (`lib/generated/*.g.dart`), NOT from Rust
///
/// | Dart match  | emitted by                                          | → ServiceError    |
/// |-------------|-----------------------------------------------------|-------------------|
/// | code `9998` | codegen "Required fields missing from response"     | InvalidInputError |
/// |             | (category=validation → handled by the validation arm)|                  |
///
/// ### Dead match points (kept for completeness / contract tests only)
/// `_mapOperationError` strings — `'Path not found'`, `'read-only'`,
/// `'Invalid value'` — map `OperationError::*`, which is constructed ONLY in the
/// Rust `ffi` module (native, `#[cfg(not(target_arch = "wasm32"))]`). They never
/// fire in the production WASM build. See [_mapOperationError].
///
/// **Warning**: anything not matched above falls through to NetworkError
/// (transport) or UnexpectedError (auth/protocol/unparseable). If source
/// strings/codes change, update this table AND the contract tests together.
ServiceError mapUspErrorToServiceError(Object error) {
  final parsed = parseUspError(error);
  if (parsed == null) {
    final result = UnexpectedError(originalError: error);
    logger.w('[USP][ServiceError]: "$error" → ${result.runtimeType}');
    return result;
  }

  final result = switch (parsed.category) {
    UspErrorCategory.auth => _mapAuthError(parsed),
    UspErrorCategory.transport => _mapTransportError(parsed),
    UspErrorCategory.protocol => _mapProtocolError(parsed),
    UspErrorCategory.operation => _mapOperationError(parsed),
    UspErrorCategory.validation =>
      InvalidInputError(code: parsed.faultCode, detail: parsed.message),
  };
  logger.w('[USP][ServiceError]: "$error" → ${result.runtimeType}');
  return result;
}

ServiceError _mapAuthError(UspError e) {
  final msg = e.message;
  final code = e.faultCode;
  if (msg.contains('Invalid credentials')) {
    return InvalidCredentialsError(code: code, detail: msg);
  }
  if (msg.contains('Session expired')) {
    return SessionTokenExpiredError(code: code, detail: msg);
  }
  if (msg.contains('Invalid token')) {
    return InvalidSessionTokenError(code: code, detail: msg);
  }
  if (msg.contains('Permission denied')) {
    return UnauthorizedError(code: code, detail: msg);
  }
  if (msg.contains('Authentication required')) {
    return NotAuthenticatedError(code: code, detail: msg);
  }
  return UnexpectedError(originalError: e.rawError, detail: msg);
}

ServiceError _mapTransportError(UspError e) {
  final status = e.httpStatus;
  if (status != null) {
    return switch (status) {
      401 => NotAuthenticatedError(code: status, detail: e.message),
      _ => NetworkError(code: status, detail: e.message),
    };
  }
  final msg = e.message;
  if (msg.contains('Request timeout')) {
    return NetworkError(detail: msg);
  }
  if (msg.contains('Connection refused')) {
    return ConnectivityError(detail: msg);
  }
  return NetworkError(detail: msg);
}

ServiceError _mapProtocolError(UspError e) {
  // Protocol errors with fault codes from the router
  final code = e.faultCode;
  if (code != null) {
    return switch (code) {
      7004 => InvalidInputError(code: code, detail: e.message), // not writable
      7005 =>
        InvalidInputError(code: code, detail: e.message), // bad param name
      7006 => InvalidInputError(code: code, detail: e.message), // bad value
      7026 => ResourceNotFoundError(code: code, detail: e.message), // path 404
      7027 =>
        ResourceNotFoundError(code: code, detail: e.message), // object 404
      9001 => UnauthorizedError(code: code, detail: e.message), // bbfdm denied
      9005 =>
        ResourceNotFoundError(code: code, detail: e.message), // unimplemented
      9007 => ResourceNotFoundError(code: code, detail: e.message),
      9008 => InvalidInputError(code: code, detail: e.message), // non-writable
      _ => UnexpectedError(originalError: e.rawError, detail: e.message),
    };
  }
  return UnexpectedError(originalError: e.rawError, detail: e.message);
}

/// Maps `Operation error:` category strings (e.g. "Path not found: ...",
/// "Parameter is read-only: ...", "Invalid value '...' for '...': ...").
///
/// Two things to know about this mapper:
///
/// 1. **Effectively dead in production.** `UspError::OperationError` variants
///    are constructed ONLY in the Rust `ffi` module, gated behind
///    `#[cfg(not(target_arch = "wasm32"))]` — native FFI only, stripped from the
///    WASM binary the app actually runs. (The one WASM-side `OperationError`,
///    `OperateFailed` from subscribe/unsubscribe, surfaces as a thrown string
///    via Promise reject and never reaches codegen's catch, so it skips here.)
///    Kept only for completeness + the existing contract tests; don't rely on
///    it firing in prod.
///
/// 2. **No `code` is passed — by design.** Unlike protocol errors, the Rust
///    `OperationError` Display strings carry NO `(code: XXXX)` suffix (they are
///    path/reason text only). So `parseUspError`'s regex never extracts a
///    faultCode here — `e.faultCode` is always null. Passing `code:` would just
///    forward null, so it's omitted. Only `detail` (the raw message) is kept.
ServiceError _mapOperationError(UspError e) {
  final msg = e.message;
  if (msg.contains('Path not found')) return const ResourceNotFoundError();
  if (msg.contains('read-only')) {
    return InvalidInputError(detail: msg);
  }
  if (msg.contains('Invalid value')) {
    return InvalidInputError(detail: msg);
  }
  return UnexpectedError(originalError: e.rawError, detail: msg);
}
