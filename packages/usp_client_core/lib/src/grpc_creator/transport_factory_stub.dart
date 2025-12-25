import 'package:grpc/grpc_connection_interface.dart';
import 'transport_factory_interface.dart';

/// Stub implementation for unsupported platforms.
class TransportFactoryStub implements TransportFactory {
  @override
  ClientChannelBase createClientChannel({
    required String host,
    required int port,
  }) {
    throw UnsupportedError(
      'ClientChannel not supported on this platform without dart:io or dart:html.',
    );
  }
}

TransportFactory getTransportFactory() => TransportFactoryStub();
