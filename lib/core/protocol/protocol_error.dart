/// Identifies the protocol source of an error.
enum Protocol { jnap, usp }

/// Unified exception type for protocol-level errors.
///
/// Wraps errors from either JNAP or USP into a common type so that
/// service-layer code can handle both protocols uniformly.
class ProtocolException implements Exception {
  final String message;
  final String? protocolErrorCode;
  final Protocol source;
  final Object? originalError;

  const ProtocolException({
    required this.message,
    required this.source,
    this.protocolErrorCode,
    this.originalError,
  });

  @override
  String toString() => 'ProtocolException(${source.name}): $message'
      '${protocolErrorCode != null ? ' [$protocolErrorCode]' : ''}';
}
