/// Unified response wrapper for all USP operations.
///
/// Wraps the operation-specific [data] result with optional protocol-level
/// metadata. Currently only [commandKey] is populated (for Operate responses),
/// but additional fields can be added as USP integration evolves.
class UspResponse<T> {
  /// The operation result data.
  final T data;

  /// UUID correlator assigned by the USP agent.
  ///
  /// Only present for Operate responses — used to correlate with
  /// OperationComplete SSE events. `null` for GET/SET/ADD/DELETE.
  final String? commandKey;

  const UspResponse({required this.data, this.commandKey});

  @override
  String toString() => 'UspResponse(commandKey=$commandKey, data=$data)';
}
