import 'package:equatable/equatable.dart';

enum CloudEnvironment { dev, qa, prod }

CloudEnvironment cloudEnvTarget = CloudEnvironment.qa;

class CloudTransportConfig extends Equatable {
  const CloudTransportConfig(
      {required this.protocol, required this.mqttBroker});

  factory CloudTransportConfig.fromJson(Map<String, dynamic> json) {
    return CloudTransportConfig(
        protocol: json['protocol'], mqttBroker: json['mqttBroker']);
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'mqttBroker': mqttBroker,
    };
  }

  final String protocol;
  final String mqttBroker;

  @override
  List<Object?> get props => [protocol, mqttBroker];
}

class CloudConfig extends Equatable {
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

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'env': env,
      'apiBase': apiBase,
      'cloudConfigBaseUrl': cloudConfigBaseUrl,
      'transport': transport.toJson(),
    };
  }

  final String region;
  final String env;
  final String apiBase;
  final String cloudConfigBaseUrl;
  final CloudTransportConfig transport;

  @override
  List<Object?> get props =>
      [region, env, apiBase, cloudConfigBaseUrl, transport];
}
