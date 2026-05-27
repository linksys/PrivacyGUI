/// Represents a decoded USP Record received over WebSocket.
///
/// Fields are parsed from the WASM `decodeRecord()` output:
/// ```javascript
/// { from_id, to_id, version, msg_type, msg_id, command?, output_args?, error? }
/// ```
class UspWsMessage {
  const UspWsMessage({
    required this.fromId,
    required this.toId,
    required this.version,
    required this.msgType,
    required this.msgId,
    this.command,
    this.outputArgs,
    this.error,
  });

  /// Sender endpoint ID (e.g., "os::router-001122334455").
  final String fromId;

  /// Receiver endpoint ID (e.g., "controller::localui-turbo").
  final String toId;

  /// USP protocol version (typically "1.3").
  final String version;

  /// Message type: "Get", "GetResp", "Operate", "OperateResp", "Error", etc.
  final String msgType;

  /// Unique message identifier for request/response correlation.
  final String msgId;

  /// Command path for Operate responses (e.g., "Device.LocalAgent.X_LINKSYS_Download()").
  final String? command;

  /// Output arguments from Operate response.
  final Map<String, dynamic>? outputArgs;

  /// Error details if the message is an error response.
  final UspWsError? error;

  /// Whether this message indicates success (no error present).
  bool get isSuccess => error == null;

  /// Whether this is an error response.
  bool get isError => error != null;

  /// Parse from the decoded JS object returned by WASM decodeRecord().
  factory UspWsMessage.fromJs(Map<String, dynamic> js) {
    UspWsError? error;
    if (js['error'] != null) {
      final errData = js['error'];
      if (errData is Map) {
        error = UspWsError(
          code: errData['code']?.toString() ?? '',
          message: errData['message']?.toString() ?? '',
        );
      }
    }

    Map<String, dynamic>? outputArgs;
    if (js['output_args'] != null && js['output_args'] is Map) {
      outputArgs = Map<String, dynamic>.from(js['output_args'] as Map);
    }

    return UspWsMessage(
      fromId: js['from_id']?.toString() ?? '',
      toId: js['to_id']?.toString() ?? '',
      version: js['version']?.toString() ?? '',
      msgType: js['msg_type']?.toString() ?? '',
      msgId: js['msg_id']?.toString() ?? '',
      command: js['command']?.toString(),
      outputArgs: outputArgs,
      error: error,
    );
  }

  @override
  String toString() =>
      'UspWsMessage(msgType: $msgType, msgId: $msgId, from: $fromId, to: $toId)';
}

/// Error details from a USP error response.
class UspWsError {
  const UspWsError({
    required this.code,
    required this.message,
  });

  /// USP error code (e.g., "7001", "7004").
  final String code;

  /// Human-readable error message.
  final String message;

  @override
  String toString() => 'UspWsError(code: $code, message: $message)';
}
