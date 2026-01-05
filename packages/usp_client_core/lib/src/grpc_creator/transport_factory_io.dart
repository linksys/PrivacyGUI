import 'package:grpc/grpc.dart';
import 'transport_factory_interface.dart';

/// Native platform (iOS/Android/Desktop) implementation of [TransportFactory].
class NativeTransportFactory implements TransportFactory {
  @override
  ClientChannel createClientChannel({required String host, required int port}) {
    return ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
  }
}

TransportFactory getTransportFactory() => NativeTransportFactory();
