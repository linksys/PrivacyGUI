// This is a generated file - do not edit.
//
// Generated from usp_transport.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'usp_transport.pb.dart' as $0;

export 'usp_transport.pb.dart';

/// Defines the gRPC service called by the Client App
@$pb.GrpcServiceName('usp_transport.UspTransportService')
class UspTransportServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  UspTransportServiceClient(super.channel, {super.options, super.interceptors});

  /// RPC method: Used to send a USP message and await a synchronous response.
  /// The Proxy forwards this message to the internal MQTT broker.
  $grpc.ResponseFuture<$0.UspTransportResponse> sendUspMessage(
    $0.UspTransportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendUspMessage, request, options: options);
  }

  // method descriptors

  static final _$sendUspMessage =
      $grpc.ClientMethod<$0.UspTransportRequest, $0.UspTransportResponse>(
          '/usp_transport.UspTransportService/SendUspMessage',
          ($0.UspTransportRequest value) => value.writeToBuffer(),
          $0.UspTransportResponse.fromBuffer);
}

@$pb.GrpcServiceName('usp_transport.UspTransportService')
abstract class UspTransportServiceBase extends $grpc.Service {
  $core.String get $name => 'usp_transport.UspTransportService';

  UspTransportServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.UspTransportRequest, $0.UspTransportResponse>(
            'SendUspMessage',
            sendUspMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UspTransportRequest.fromBuffer(value),
            ($0.UspTransportResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.UspTransportResponse> sendUspMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UspTransportRequest> $request) async {
    return sendUspMessage($call, await $request);
  }

  $async.Future<$0.UspTransportResponse> sendUspMessage(
      $grpc.ServiceCall call, $0.UspTransportRequest request);
}
