import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/jnap/models/health_check_result.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';

@immutable
class DashboardManagerState {
  final List<RouterRadioInfo> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;
  final HealthCheckResult? latestSpeedTest;

  const DashboardManagerState({
    this.mainRadios = const [],
    this.guestRadios = const [],
    this.isGuestNetworkEnabled = false,
    this.latestSpeedTest,
  });

  DashboardManagerState copyWith({
    List<RouterRadioInfo>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    bool? isGuestNetworkEnabled,
    HealthCheckResult? latestSpeedTest,
  }) {
    return DashboardManagerState(
      mainRadios: mainRadios ?? this.mainRadios,
      guestRadios: guestRadios ?? this.guestRadios,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      latestSpeedTest: latestSpeedTest ?? this.latestSpeedTest,
    );
  }
}
