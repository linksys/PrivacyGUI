import 'package:grpc/grpc_connection_interface.dart';

/// Abstract factory for creating gRPC client channels.
///
/// This allows the same code to work on both Web (gRPC-Web) and Native (gRPC) platforms.
abstract class TransportFactory {
  ClientChannelBase createClientChannel({
    required String host,
    required int port,
  });
}
