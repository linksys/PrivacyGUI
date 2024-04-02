// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class DeviceFilterConfigState extends Equatable {
  final bool connectionFilter;
  final List<String> nodeFilter;
  final List<String> bandFilter;

  const DeviceFilterConfigState({
    required this.connectionFilter,
    required this.nodeFilter,
    required this.bandFilter,
  });

  DeviceFilterConfigState copyWith({
    bool? connectionFilter,
    List<String>? nodeFilter,
    List<String>? bandFilter,
  }) {
    return DeviceFilterConfigState(
      connectionFilter: connectionFilter ?? this.connectionFilter,
      nodeFilter: nodeFilter ?? this.nodeFilter,
      bandFilter: bandFilter ?? this.bandFilter,
    );
  }

  @override
  List<Object> get props => [
        connectionFilter,
        nodeFilter,
        bandFilter,
      ];
}
