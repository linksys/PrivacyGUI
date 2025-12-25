/// USP Connection Configuration
///
/// Configuration for connecting to a USP Agent via gRPC.
library;

import 'package:equatable/equatable.dart';

/// Configuration for connecting to a USP Agent.
class UspConnectionConfig extends Equatable {
  /// The host address of the gRPC-Web proxy (Envoy).
  final String host;

  /// The port number of the gRPC-Web proxy.
  final int port;

  /// Creates a new [UspConnectionConfig].
  ///
  /// Default values match the Envoy proxy configuration:
  /// - host: 'localhost'
  /// - port: 8090 (Envoy gRPC-Web port)
  const UspConnectionConfig({
    this.host = 'localhost',
    this.port = 8090,
  });

  @override
  List<Object?> get props => [host, port];

  @override
  String toString() => 'UspConnectionConfig(host: $host, port: $port)';
}
