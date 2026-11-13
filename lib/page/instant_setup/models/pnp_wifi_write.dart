import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/preservable.dart';

import 'pnp_probe_settings.dart';
import 'pnp_wifi_band.dart';
import 'pnp_wifi_settings.dart';

/// What one PnP save writes: the Wi-Fi step's draft and the guest step's, each
/// as the router had it and as edited (#1511 P4).
///
/// The two go out in **one** SET (`PnpService.saveWifi`), because any Wi-Fi
/// write restarts every radio. [guest] is `null` when the flow has no guest
/// step.
class PnpWifiWrite extends Equatable {
  const PnpWifiWrite({required this.main, this.guest, this.probe});

  final Preservable<PnpMainWifiSettings> main;
  final Preservable<PnpGuestWifiSettings>? guest;

  /// **#1511 P6's probe — test-only.**
  final Preservable<PnpProbeSettings>? probe;

  /// The name the reconnect step and the completion screen show.
  ///
  /// Split mode: the first band whose name or password was edited, or the
  /// first band when none was. Unified: the one name.
  String get reconnectSsid => _reconnectBand?.ssid ?? main.current.ssid;

  /// The password beside [reconnectSsid].
  String get reconnectPassword =>
      _reconnectBand?.password ?? main.current.password;

  PnpWifiBand? get _reconnectBand {
    final now = main.current;
    if (!now.splitMode || now.bands.isEmpty) return null;
    return now.bands
            .where((b) => b != bandAsRead(main.original.bands, b))
            .firstOrNull ??
        now.bands.first;
  }

  @override
  List<Object?> get props => [main, guest, probe];
}
