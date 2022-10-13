import 'package:equatable/equatable.dart';

class CloudTransportConfig extends Equatable {
  const CloudTransportConfig(
      {required this.protocol, required this.mqttBroker, required this.port});

  factory CloudTransportConfig.fromJson(Map<String, dynamic> json) {
    return CloudTransportConfig(
        protocol: json['protocol'], mqttBroker: json['mqttBroker'], port: json['port']);
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'mqttBroker': mqttBroker,
      'port': port,
    };
  }

  final String protocol;
  final String mqttBroker;
  final int port;

  @override
  List<Object?> get props => [protocol, mqttBroker, port];
}

class CloudConfig extends Equatable {
  const CloudConfig({
    required this.region,
    required this.env,
    required this.apiBase,
    required this.cloudConfigBaseUrl,
    required this.resourceBaseUrl,
    required this.transport,
  });

  factory CloudConfig.fromJson(Map<String, dynamic> json) {
    return CloudConfig(
        region: json['region'],
        env: json['env'],
        apiBase: json['apiBase'],
        cloudConfigBaseUrl: json['cloudConfigBaseUrl'],
        resourceBaseUrl: json['resourceBaseUrl'],
        transport: CloudTransportConfig.fromJson(json['transport']));
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'env': env,
      'apiBase': apiBase,
      'cloudConfigBaseUrl': cloudConfigBaseUrl,
      'resourceBaseUrl': resourceBaseUrl,
      'transport': transport.toJson(),
    };
  }

  final String region;
  final String env;
  final String apiBase;
  final String cloudConfigBaseUrl;
  final String resourceBaseUrl;
  final CloudTransportConfig transport;

  @override
  List<Object?> get props =>
      [region, env, apiBase, resourceBaseUrl, cloudConfigBaseUrl, transport];
}
