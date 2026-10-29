/// Identifies which upload transport is being used.
enum UploadMethod {
  /// HTTP chunked push via `Device.LocalAgent.X_LINKSYS_Download()`.
  http,

  /// WebSocket binary push direct to OBUSPA.
  websocket,
}
