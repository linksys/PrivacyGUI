import 'package:equatable/equatable.dart';

enum CloudEnvironment { dev, qa, prod }

CloudEnvironment cloudEnvTarget = CloudEnvironment.dev;

class CloudTransportConfig extends Equatable{
  const CloudTransportConfig(
      {required this.protocol, required this.mqttBroker});

  factory CloudTransportConfig.fromJson(Map<String, dynamic> json) {
    return CloudTransportConfig(
        protocol: json['protocol'], mqttBroker: json['mqttBroker']);
  }

  final String protocol;
  final String mqttBroker;

  @override
  List<Object?> get props => [protocol, mqttBroker];
}

class CloudConfig extends Equatable{
  const CloudConfig({
    required this.region,
    required this.env,
    required this.apiBase,
    required this.cloudConfigBaseUrl,
    required this.transport,
  });

  factory CloudConfig.fromJson(Map<String, dynamic> json) {
    return CloudConfig(
        region: json['region'],
        env: json['env'],
        apiBase: json['apiBase'],
        cloudConfigBaseUrl: json['cloudConfigBaseUrl'],
        transport: CloudTransportConfig.fromJson(json['transport']));
  }

  final String region;
  final String env;
  final String apiBase;
  final String cloudConfigBaseUrl;
  final CloudTransportConfig transport;

  @override
  List<Object?> get props => [region, env, apiBase, cloudConfigBaseUrl, transport];
}
