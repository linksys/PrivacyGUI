import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/cloud/model/cloud_network_model.dart';

class CloudNetworkModel extends Equatable {
  final Network network;
  final bool isOnline;

  const CloudNetworkModel({
    required this.network,
    required this.isOnline,
  });

  Map<String, dynamic> toJson() {
    return {
      'network': network.toJson(),
      'isOnline': isOnline,
    };
  }

  static CloudNetworkModel fromJson(Map<String, dynamic> json) {
    return CloudNetworkModel(
      network: json['networkId'],
      isOnline: json['friendlyName'],
    );
  }

  @override
  List<Object?> get props => [
        network,
        isOnline,
      ];
}
