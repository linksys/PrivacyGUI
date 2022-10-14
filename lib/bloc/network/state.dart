import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/network.dart';

class NetworkState extends Equatable {
  const NetworkState({
    this.selected,
    this.networks = const [],
  });

  factory NetworkState.initState() {
    return const NetworkState();
  }

  final List<MoabNetwork> networks;
  final MoabNetwork? selected;

  NetworkState copyWith({
    List<MoabNetwork>? networks,
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
