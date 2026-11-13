import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/internet_troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';

/// An [InternetTroubleshootingNotifier] frozen at one phase (#1511 P1).
///
/// Every transition a troubleshooting page triggers is overridden — the hub's
/// "Try again", the waiting page's confirm, the three ISP saves — because the
/// real ones reach `internetTroubleshootingServiceProvider`, whose
/// `uspInternetSettingsServiceProvider` throws on a null USP client. A test that
/// taps stays inside the fixture.
class FixedInternetTroubleshootingNotifier
    extends InternetTroubleshootingNotifier {
  FixedInternetTroubleshootingNotifier(this._fixedPhase);

  final TroubleshootingPhase _fixedPhase;

  @override
  TroubleshootingPhase build() => _fixedPhase;

  @override
  Future<void> retryInternetCheck() async {}

  @override
  Future<void> startModemRestartCountdown() async {}

  @override
  Future<void> saveIspWithProgress(PnpIspConfig config) async {}
}

/// Overrides pinning the troubleshooting run to [phase], with [wanPrefill] as
/// the router's WAN for the ISP forms.
///
/// The prefill is overridden even where it is `null`: the hub watches it, and the
/// real read reaches the same throwing service as the transitions above.
List<Override> internetTroubleshootingOverrides({
  TroubleshootingPhase phase = const TroubleshootingNoInternet(),
  UspInternetSettingsForm? wanPrefill,
}) =>
    [
      internetTroubleshootingProvider
          .overrideWith(() => FixedInternetTroubleshootingNotifier(phase)),
      troubleshootingWanPrefillProvider.overrideWith((ref) => wanPrefill),
    ];
