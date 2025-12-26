import 'dart:async';
import 'package:logging/logging.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart' hide Set;

import '../connection/usp_grpc_client_service.dart';

/// Service responsible for discovering and caching the device's supported Data Model.
///
/// This service encapsulates the [UspGetSupportedDMRequest] logic and provides
/// efficient lookups to check if specific paths, commands, or events are supported
/// by the connected Agent.
class UspCapabilityService {
  final UspGrpcClientService _grpcService;
  final Logger _logger = Logger('UspCapabilityService');

  // Set of supported paths (Objects and Commands)
  final Set<String> _supportedSchema = {};

  UspCapabilityService(this._grpcService);

  /// Initializes the capability cache by querying the device.
  ///
  /// This should be called after the gRPC connection is established.
  Future<void> initialize() async {
    _supportedSchema.clear();

    // Query for the entire Device model.
    // We use UspPath.parse to ensure correct type usage for the request.
    final request = UspGetSupportedDMRequest(
      [UspPath.parse('Device.')],
      firstLevelOnly: false,
      returnCommands: true,
      returnEvents: true,
      returnParams: true,
    );

    try {
      _logger.info('Querying Device model capabilities...');
      final response = await _grpcService.sendRequest(request);

      if (response is UspGetSupportedDMResponse) {
        _parseResponse(response);
        _logger.info(
            'Capabilities loaded: ${_supportedSchema.length} schema items found.');
      }
    } catch (e) {
      _logger.severe('Failed to get capabilities', e);
      // We don't rethrow here to allow partial app function,
      // but in a strict mode we might want to.
    }
  }

  void _parseResponse(UspGetSupportedDMResponse response) {
    for (final entry in response.results.entries) {
      final path = entry.key;
      final def = entry.value;

      _supportedSchema.add(path);

      // Supported Commands
      // Note: USP Command paths often look like "Device.WiFi.Reset()"
      // The definition provides just the command name "Reset".
      // We store the fully qualified path for easier verification.
      for (final cmdName in def.supportedCommands.keys) {
        _supportedSchema.add('$path$cmdName()');
      }

      // Supported Events
      // (If available in your UspObjectDefinition structure)
    }
  }

  /// Checks if a raw TR-181 path (Object, Param, or Command) is supported.
  ///
  /// Supports partial matches for objects (e.g. searching for "Device.WiFi."
  /// might match "Device.WiFi.SSID.").
  bool isPathSupported(String path) {
    if (_supportedSchema.contains(path)) return true;

    // Check if the schema contains any path that implies this path
    // OR if this path is a parent of something in the schema (less likely for features).
    // Usually we check: "Do we have Device.WiFi.?" -> yes.
    return _supportedSchema
        .any((s) => s.startsWith(path) || path.startsWith(s));
  }

  /// Returns simple stats about the loaded schema.
  int get schemaSize => _supportedSchema.length;
}
