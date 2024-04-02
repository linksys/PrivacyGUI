import 'package:equatable/equatable.dart';

 class AvailabilityInfo extends Equatable {
  const AvailabilityInfo({required this.isCloudOk});

  factory AvailabilityInfo.init() {
    return const AvailabilityInfo(isCloudOk: true);
  }

  final bool isCloudOk;

  AvailabilityInfo copyWith({bool? isCloudOk}) {
   return AvailabilityInfo(isCloudOk: isCloudOk?? this.isCloudOk);
  }
  @override
  List<Object?> get props => [isCloudOk];


}