import 'package:equatable/equatable.dart';
import 'package:linksys_moab/bloc/network/cloud_network_model.dart';
import 'package:linksys_moab/core/jnap/models/network.dart';

class NetworkState extends Equatable {
  const NetworkState({
    this.selected,
    this.networks = const [],
  });

  factory NetworkState.initState() {
    return const NetworkState();
  }

  final List<CloudNetworkModel> networks;
  final MoabNetwork? selected;

  NetworkState copyWith({
    List<CloudNetworkModel>? networks,
    MoabNetwork? selected,
  }) {
    return NetworkState(
      networks: networks ?? this.networks,
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [
        selected,
        networks,
      ];
}
