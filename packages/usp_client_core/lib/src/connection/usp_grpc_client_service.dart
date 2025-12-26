/// USP gRPC Client Service
///
/// Provides gRPC communication with the USP Simulator.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:meta/meta.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../grpc_creator/grpc_creator.dart';
import 'usp_connection_config.dart';

/// Simple logger for USP operations.
void _log(String message) {
  developer.log(message, name: 'USP');
}

/// Service for communicating with USP Agent via gRPC.
///
/// This service handles:
/// - Connection management (connect/disconnect)
/// - USP message encoding/decoding
/// - gRPC transport layer
class UspGrpcClientService {
  // Dependencies
  final TransportFactory _transportFactory;
  final UspProtobufConverter _converter;
  final UspRecordHelper _recordHelper;

  // State
  ClientChannelBase? _channel;
  UspTransportServiceClient? _stub;
  bool _isConnected = false;

  // Configuration
  final String _controllerId = "proto::privacygui-client";
  final String _agentId = "proto::agent";

  /// Creates a new [UspGrpcClientService].
  ///
  /// Dependencies can be injected for testing.
  UspGrpcClientService({
    TransportFactory? transportFactory,
    UspProtobufConverter? converter,
    UspRecordHelper? recordHelper,
  })  : _transportFactory = transportFactory ?? getTransportFactory(),
        _converter = converter ?? UspProtobufConverter(),
        _recordHelper = recordHelper ?? UspRecordHelper();

  /// Whether the service is connected to the USP Agent.
  bool get isConnected => _isConnected;

  /// Connects to the USP Agent at the specified host and port.
  Future<void> connect(UspConnectionConfig config) async {
    // Avoid duplicate connections
    await disconnect();

    _log('🔌 USP: Connecting to ${config.host}:${config.port}...');

    try {
      // Create cross-platform gRPC channel
      _channel = _transportFactory.createClientChannel(
        host: config.host,
        port: config.port,
      );

      // Create gRPC stub
      _stub = UspTransportServiceClient(_channel!);

      _isConnected = true;
      _log('✅ USP: Connected successfully');
    } catch (e) {
      _log('❌ USP: Connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Sends a USP request and returns the response.
  ///
  /// Throws [UspException] if not connected or on communication error.
  Future<UspResponse> sendRequest(UspRequest requestDto) async {
    if (_stub == null || !_isConnected) {
      throw UspException(
        7000,
        'USP Client is not connected. Call connect() first.',
      );
    }

    try {
      _log('📤 USP: Sending ${requestDto.runtimeType}...');

      // 1. Pack request into USP Record
      final msgId = 'req-${DateTime.now().millisecondsSinceEpoch}';
      final reqMsg = _converter.toProto(requestDto, msgId: msgId);
      final reqRecord = _recordHelper.wrap(
        reqMsg,
        fromId: _controllerId,
        toId: _agentId,
      );

      // 2. Send via gRPC transport
      final transportReq = UspTransportRequest()
        ..uspRecordPayload = reqRecord.writeToBuffer();

      final transportRes = await _stub!.sendUspMessage(transportReq);

      // 3. Unpack response
      final resBytes = transportRes.uspRecordResponse;
      if (resBytes.isEmpty) {
        throw UspException(7002, "Received empty response from Gateway");
      }

      final resMsg = _recordHelper.unwrap(resBytes);
      final resDto = _converter.fromProto(resMsg);

      _log('📩 USP: Received ${resDto.runtimeType}');

      if (resDto is UspResponse) {
        return resDto;
      } else {
        throw UspException(
          7000,
          "Unexpected response type: ${resDto.runtimeType}",
        );
      }
    } catch (e) {
      _log('❌ USP: Request failed: $e');
      if (e is UspException) rethrow;
      throw UspException(7000, "Communication Error: $e");
    }
  }

  /// Disconnects from the USP Agent.
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.shutdown();
      _channel = null;
      _stub = null;
      _isConnected = false;
      _log('🔌 USP: Disconnected');
    }
  }

  // --- Testing Helpers ---

  /// Allows tests to inject a mock stub.
  @visibleForTesting
  void setMockStub(UspTransportServiceClient stub) {
    _stub = stub;
    _isConnected = true;
  }

  /// Allows tests to inject a mock channel.
  @visibleForTesting
  void setMockChannel(ClientChannelBase channel) {
    _channel = channel;
  }
}
