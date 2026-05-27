import 'dart:typed_data';

/// Progress callback for firmware upload.
///
/// [sentChunks] - Number of chunks sent so far (0-based).
/// [totalChunks] - Total number of chunks to send.
typedef FirmwareUploadProgressCallback = void Function(
    int sentChunks, int totalChunks);

/// Abstract interface for firmware upload strategies.
///
/// Implementations handle the transport-specific details of pushing
/// firmware chunks to the router. The service layer selects the appropriate
/// strategy based on availability and preferences.
///
/// ## Lifecycle
/// ```
/// 1. prepare()      — Acquire resources (connections, locks)
/// 2. uploadChunk()  — Called for each chunk (with progress callback)
/// 3. finalize()     — Release resources (always call, even on error)
/// ```
abstract class FirmwareUploadStrategy {
  /// Human-readable name for logging.
  String get name;

  /// Whether this strategy is currently available.
  ///
  /// May perform lightweight checks (e.g., WebSocket endpoint reachable).
  Future<bool> isAvailable();

  /// Prepare resources before upload begins.
  ///
  /// For HTTP: No-op (stateless).
  /// For WebSocket: turboStart → WS connect → send WebSocketConnect frame.
  ///
  /// Throws on failure.
  Future<void> prepare();

  /// Upload a single chunk.
  ///
  /// [chunk] - Raw chunk data (will be base64 encoded as needed).
  /// [sequenceNumber] - 1-based sequence number.
  /// [totalChunks] - Total number of chunks.
  /// [md5] - MD5 checksum of the entire file.
  /// [fileSize] - Total file size in bytes.
  /// [commandKey] - Unique command key (must be numeric string).
  ///
  /// Throws [ServiceError] on failure.
  Future<void> uploadChunk({
    required Uint8List chunk,
    required int sequenceNumber,
    required int totalChunks,
    required String md5,
    required int fileSize,
    required String commandKey,
  });

  /// Release resources after upload completes or fails.
  ///
  /// For HTTP: No-op (stateless).
  /// For WebSocket: WS close → turboRelease.
  ///
  /// This method should not throw — cleanup failures are logged but don't
  /// propagate. Always call this, even if prepare() or uploadChunk() failed.
  Future<void> finalize();
}

/// Identifies which upload transport is being used.
enum UploadMethod {
  /// HTTP chunked push via `Device.LocalAgent.X_LINKSYS_Download()`.
  http,

  /// WebSocket binary push direct to OBUSPA.
  websocket,
}
