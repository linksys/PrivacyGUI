import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

 class AvailabilityInfo extends Equatable {
  const AvailabilityInfo({required this.isCloudOk});

  factory AvailabilityInfo.init() {
    return const AvailabilityInfo(isCloudOk: true);
  }

  final bool isCloudOk;

  @override
  List<Object?> get props => [isCloudOk];


}