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
/// ## WASM String Contract
///
/// This function matches error strings from `usp_framework/usp-client/src/error.rs`.
/// The following strings are part of the API contract:
///
/// | Dart match string       | WASM error type                  |
/// |-------------------------|----------------------------------|
/// | `'Invalid credentials'` | `AuthError::InvalidCredentials`  |
/// | `'Session expired'`     | `AuthError::SessionExpired`      |
/// | `'Invalid token'`       | `AuthError::InvalidToken`        |
/// | `'Permission denied'`   | `AuthError::PermissionDenied`    |
/// | `'Authentication required'` | `AuthError::AuthenticationRequired` |
/// | `'Request timeout'`     | `TransportError::Timeout`        |
/// | `'Connection refused'`  | `TransportError::ConnectionRefused` |
/// | `'Path not found'`      | `OperationError::PathNotFound`   |
/// | `'read-only'`           | `OperationError::ReadOnly`       |
/// | `'Invalid value'`       | `OperationError::InvalidValue`   |
///
/// **Warning**: If WASM error messages change, this mapping will break silently.
/// Update both sides together.
ServiceError mapUspErrorToServiceError(Object error) {
  final parsed = parseUspError(error);
  if (parsed == null) {
    final result = UnexpectedError(originalError: error);
    logger.w('[USP:ServiceError] "$error" → ${result.runtimeType}');
    return result;
  }

  final result = switch (parsed.category) {
    UspErrorCategory.auth => _mapAuthError(parsed),
    UspErrorCategory.transport => _mapTransportError(parsed),
    UspErrorCategory.protocol => _mapProtocolError(parsed),
    UspErrorCategory.operation => _mapOperationError(parsed),
    UspErrorCategory.validation => InvalidInputError(message: parsed.message),
  };
  logger.w('[USP:ServiceError] "$error" → ${result.runtimeType}');
  return result;
}

ServiceError _mapAuthError(UspError e) {
  final msg = e.message;
  if (msg.contains('Invalid credentials')) {
    return const InvalidCredentialsError();
  }
  if (msg.contains('Session expired')) return const SessionTokenExpiredError();
  if (msg.contains('Invalid token')) return const InvalidSessionTokenError();
  if (msg.contains('Permission denied')) return const UnauthorizedError();
  if (msg.contains('Authentication required')) {
    return const NotAuthenticatedError();
  }
  return UnexpectedError(originalError: e.rawError, message: msg);
}

ServiceError _mapTransportError(UspError e) {
  final status = e.httpStatus;
  if (status != null) {
    return switch (status) {
      401 => const NotAuthenticatedError(),
      504 => NetworkError(message: e.message),
      _ => NetworkError(message: e.message),
    };
  }
  final msg = e.message;
  if (msg.contains('Request timeout')) {
    return NetworkError(message: msg);
  }
  if (msg.contains('Connection refused')) {
    return ConnectivityError(message: msg);
  }
  return NetworkError(message: msg);
}

ServiceError _mapProtocolError(UspError e) {
  // Protocol errors with fault codes from the router
  final code = e.faultCode;
  if (code != null) {
    return switch (code) {
      7004 => InvalidInputError(message: e.message),
      7026 => ResourceNotFoundError(),
      9001 => UnauthorizedError(),
      9005 => ResourceNotFoundError(),
      9007 => ResourceNotFoundError(),
      9008 => InvalidInputError(message: e.message),
      _ => UnexpectedError(originalError: e.rawError, message: e.message),
    };
  }
  return UnexpectedError(originalError: e.rawError, message: e.message);
}

ServiceError _mapOperationError(UspError e) {
  final msg = e.message;
  if (msg.contains('Path not found')) return const ResourceNotFoundError();
  if (msg.contains('read-only')) {
    return InvalidInputError(message: msg);
  }
  if (msg.contains('Invalid value')) {
    return InvalidInputError(message: msg);
  }
  return UnexpectedError(originalError: e.rawError, message: msg);
}
