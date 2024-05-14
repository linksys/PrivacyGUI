import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState(
      {required this.hasInternet,
      required this.connectivityInfo,
      this.cloudAvailabilityInfo});

  final bool hasInternet;
  final ConnectivityInfo connectivityInfo;
  final AvailabilityInfo? cloudAvailabilityInfo;

  ConnectivityState copyWith({
    bool? hasInternet,
    ConnectivityInfo? connectivityInfo,
    AvailabilityInfo? cloudAvailabilityInfo,
  }) {
    return ConnectivityState(
      hasInternet: hasInternet ?? this.hasInternet,
      connectivityInfo: connectivityInfo ?? this.connectivityInfo,
      cloudAvailabilityInfo:
          cloudAvailabilityInfo ?? this.cloudAvailabilityInfo,
    );
  }

  @override
  List<Object?> get props =>
      [hasInternet, connectivityInfo, cloudAvailabilityInfo];
}
