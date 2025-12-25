import 'package:grpc/grpc_connection_interface.dart';
import 'package:grpc/grpc_web.dart';
import 'transport_factory_interface.dart';

/// Web platform implementation of [TransportFactory].
///
/// Uses gRPC-Web which requires a proxy (like Envoy) to convert to standard gRPC.
class WebTransportFactory implements TransportFactory {
  @override
  ClientChannelBase createClientChannel(
      {required String host, required int port}) {
    return GrpcWebClientChannel.xhr(Uri.parse('http://$host:$port'));
  }
}

TransportFactory getTransportFactory() => WebTransportFactory();
