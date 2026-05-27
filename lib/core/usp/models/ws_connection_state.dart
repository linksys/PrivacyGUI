/// WebSocket connection states reported by UspWsClient.
enum WsConnectionState {
  /// Connection is being established.
  connecting,

  /// WebSocket is open and ready for communication.
  open,

  /// Connection has been closed (gracefully or due to error).
  closed,
}

/// Parse state string from WASM callback to enum.
WsConnectionState parseWsConnectionState(String state) {
  switch (state.toLowerCase()) {
    case 'open':
      return WsConnectionState.open;
    case 'closed':
      return WsConnectionState.closed;
    case 'connecting':
      return WsConnectionState.connecting;
    default:
      return WsConnectionState.closed;
  }
}
