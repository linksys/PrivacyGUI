import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/network/http/model/cloud_network.dart';

class NetworkState extends Equatable {
  const NetworkState({
    this.selected,
    this.networks = const [],
  });

  factory NetworkState.initState() {
    return const NetworkState();
  }

  final List<CloudNetwork> networks;
  final MoabNetwork? selected;

  NetworkState copyWith({
    List<CloudNetwork>? networks,
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
