import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/jnap/models/health_check_result.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';

@immutable
class DashboardManagerState {
  final String? networkId; // networkId of the managed device
  final String serialNumber; // Serial number of the managed device
  final List<String> deviceServices; // Supported services of the managed device
  final List<RouterRadioInfo> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;
  final HealthCheckResult? latestSpeedTest;

  const DashboardManagerState({
    this.networkId,
    this.serialNumber = '',
    this.deviceServices = const [],
    this.mainRadios = const [],
    this.guestRadios = const [],
    this.isGuestNetworkEnabled = false,
    this.latestSpeedTest,
  });

  DashboardManagerState copyWith({
    String? networkId,
    String? serialNumber,
    List<String>? deviceServices,
    List<RouterRadioInfo>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    bool? isGuestNetworkEnabled,
    HealthCheckResult? latestSpeedTest,
  }) {
    return DashboardManagerState(
      networkId: networkId ?? this.networkId,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceServices: deviceServices ?? this.deviceServices,
      mainRadios: mainRadios ?? this.mainRadios,
      guestRadios: guestRadios ?? this.guestRadios,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      latestSpeedTest: latestSpeedTest ?? this.latestSpeedTest,
    );
  }
}
