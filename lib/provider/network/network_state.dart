import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/network.dart';

class NetworkState extends Equatable {
  const NetworkState({
    this.selected,
  });

  factory NetworkState.initState() {
    return const NetworkState();
  }

  final MoabNetwork? selected;

  NetworkState copyWith({
    MoabNetwork? selected,
  }) {
    return NetworkState(
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [
        selected,
      ];
}
