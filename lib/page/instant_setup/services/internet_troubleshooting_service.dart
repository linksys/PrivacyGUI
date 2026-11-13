import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

/// The router work behind the no-internet troubleshooting flow (#1511 P1).
///
/// **The internet check is PnP's, composed in.** `PnpService.checkInternetConnected`
/// is the one question both PnP's entry and troubleshooting ask, and it stays where
/// PnP's tests mock it; this provider hands the same function to troubleshooting, so
/// no caller of troubleshooting has to run PnP to use it.
final internetTroubleshootingServiceProvider =
    Provider.autoDispose<InternetTroubleshootingService>((ref) {
  return InternetTroubleshootingService(
    internetSettings: ref.watch(uspInternetSettingsServiceProvider),
    checkInternetConnected:
        ref.watch(pnpServiceProvider).checkInternetConnected,
  );
});

/// Stateless: reads the WAN, writes what the customer chose, and asks whether the
/// router has internet.
class InternetTroubleshootingService {
  InternetTroubleshootingService({
    required UspInternetSettingsService internetSettings,
    required Future<bool> Function() checkInternetConnected,
  })  : _internetSettings = internetSettings,
        _checkInternetConnected = checkInternetConnected;

  final UspInternetSettingsService _internetSettings;
  final Future<bool> Function() _checkInternetConnected;

  /// Whether the WAN is up with an address. A failed read throws a
  /// `ServiceError` rather than answering `false`: "could not read the router"
  /// and "no internet" are different pages (#1098).
  Future<bool> checkInternetConnected() => _checkInternetConnected();

  /// The router's current WAN settings, to prefill the PPPoE and static-IP forms.
  ///
  /// `null` when they cannot be read: a form that starts empty is still usable, so
  /// a failed prefill is not worth stopping the flow for.
  Future<UspInternetSettingsForm?> fetchCurrentWanSettings() async {
    try {
      return (await _internetSettings.fetchSettings()).form;
    } catch (e) {
      logger.w('[PnP] Failed to fetch WAN settings for prefill: $e');
      return null;
    }
  }

  /// Save ISP settings by delegating to [UspInternetSettingsService].
  ///
  /// This ensures troubleshooting uses the same save logic as Advanced Settings,
  /// including PPP/VLAN instance lifecycle, result validation, and allowPartial
  /// handling.
  Future<void> saveIspSettings(PnpIspConfig config) async {
    if (config.type == IspConnectionType.dhcp) {
      await _internetSettings.renewDhcpLease();
      return;
    }

    final fetchResult = await _internetSettings.fetchSettings();

    final original = fetchResult.form;
    final edited = _applyIspConfigToForm(config, original);

    await _internetSettings.saveAll(
      original,
      edited,
      pppInstancePath: fetchResult.pppInstancePath,
      vlanInstancePath: fetchResult.vlanInstancePath,
    );
  }

  /// Map [PnpIspConfig] to [UspInternetSettingsForm].
  ///
  /// UI pre-fills fields from router's current settings, so submitted values
  /// represent the user's final intent — no need to preserve original on empty.
  /// The VLAN ID is the exception: it counts only while VLAN is on.
  UspInternetSettingsForm _applyIspConfigToForm(
    PnpIspConfig config,
    UspInternetSettingsForm original,
  ) {
    final vlanEnabled = config.type == IspConnectionType.pppoeVlan;
    // dnsServer3 intentionally omitted — no UI for it here, preserve original
    return original.copyWith(
      connectionType: _mapConnectionType(config.type),
      staticIpAddress: config.staticIpAddress,
      subnetMask: config.subnetMask,
      defaultGateway: config.defaultGateway,
      dnsServer1: config.dnsServer1,
      dnsServer2: config.dnsServer2,
      pppUsername: config.pppUsername,
      pppPassword: config.pppPassword,
      vlanEnabled: vlanEnabled,
      // With VLAN off, config.vlanId is not the user's: Static IP has no VLAN
      // field, and PPPoE's hidden field holds whatever was last typed or
      // pre-filled, or 0 when empty. Keep the router's ID: FW 2.0.4 ships the
      // WAN VLAN row with ID 1 and refuses 0 (#1072).
      vlanId: vlanEnabled ? config.vlanId : original.vlanId,
    );
  }

  UspWanConnectionType _mapConnectionType(IspConnectionType type) {
    return switch (type) {
      IspConnectionType.dhcp => UspWanConnectionType.dhcp,
      IspConnectionType.pppoe => UspWanConnectionType.pppoe,
      IspConnectionType.pppoeVlan => UspWanConnectionType.pppoe,
      IspConnectionType.staticIp => UspWanConnectionType.staticIp,
    };
  }
}
