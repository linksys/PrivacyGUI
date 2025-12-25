/// gRPC Creator - Cross-platform gRPC client channel factory.
///
/// Automatically selects the correct implementation based on platform:
/// - Web: Uses gRPC-Web (requires Envoy proxy)
/// - Native (iOS/Android/Desktop): Uses standard gRPC
library;

export 'transport_factory_interface.dart';

export 'transport_factory_stub.dart'
    if (dart.library.io) 'transport_factory_io.dart'
    if (dart.library.html) 'transport_factory_web.dart';
