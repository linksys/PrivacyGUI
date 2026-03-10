import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';

/// Stateless service that wraps USP generated code for internet settings.
///
/// Provides fetch, diff-based save, and DHCP renewal operations.
class UspInternetSettingsService {
  final UspService _usp;

  UspInternetSettingsService(this._usp);

  /// Fetch both WAN and IPv6 settings in parallel.
  Future<(WanSettings, Ipv6Settings)> fetchSettings() async {
    final results = await Future.wait([
      WanSettings.fetch(_usp),
      Ipv6Settings.fetch(_usp),
    ]);
    return (results[0] as WanSettings, results[1] as Ipv6Settings);
  }

  /// Save all changed fields by comparing [original] vs [edited].
  ///
  /// Only parameters that actually differ are sent to the device.
  Future<void> saveAll(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    await _saveWanSettings(original, edited);
    await _saveIpv6Settings(original, edited);
  }

  /// Save only changed WAN (IPv4) fields.
  Future<void> _saveWanSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    // Determine if connection type changed — need to update addressingType + bridgeEnabled
    final typeChanged = original.connectionType != edited.connectionType;

    await WanSettings.save(
      _usp,
      mtu: _diff(original.mtu, edited.mtu),
      staticIpAddress: _diff(original.staticIpAddress, edited.staticIpAddress),
      subnetMask: _diff(original.subnetMask, edited.subnetMask),
      defaultGateway: _diff(original.defaultGateway, edited.defaultGateway),
      dnsServer1: _diff(original.dnsServer1, edited.dnsServer1),
      dnsServer2: _diff(original.dnsServer2, edited.dnsServer2),
      dnsServer3: _diff(original.dnsServer3, edited.dnsServer3),
      pppUsername: _diff(original.pppUsername, edited.pppUsername),
      pppPassword: _diff(original.pppPassword, edited.pppPassword),
      pppoeServiceName:
          _diff(original.pppoeServiceName, edited.pppoeServiceName),
      connectionTrigger:
          _diff(original.connectionTrigger, edited.connectionTrigger),
      idleDisconnectTime:
          _diff(original.idleDisconnectTime, edited.idleDisconnectTime),
      lcpEchoInterval: _diff(original.lcpEchoInterval, edited.lcpEchoInterval),
      vlanEnabled: _diff(original.vlanEnabled, edited.vlanEnabled),
      vlanId: _diff(original.vlanId, edited.vlanId),
      wanMacAddress: _diff(original.wanMacAddress, edited.wanMacAddress),
      bridgeEnabled: typeChanged
          ? edited.connectionType == UspWanConnectionType.bridge
          : null,
    );
  }

  /// Save only changed IPv6 fields.
  Future<void> _saveIpv6Settings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    await Ipv6Settings.save(
      _usp,
      ipv6Enabled: _diff(original.ipv6Enabled, edited.ipv6Enabled),
      dhcpv6Enabled: _diff(original.dhcpv6Enabled, edited.dhcpv6Enabled),
      ipv6rdEnabled: _diff(original.ipv6rdEnabled, edited.ipv6rdEnabled),
      ipv6rdPrefix: _diff(original.ipv6rdPrefix, edited.ipv6rdPrefix),
      ipv6rdIpv4MaskLength:
          _diff(original.ipv6rdIpv4MaskLength, edited.ipv6rdIpv4MaskLength),
      ipv6rdBorderRelay:
          _diff(original.ipv6rdBorderRelay, edited.ipv6rdBorderRelay),
    );
  }

  /// Renew DHCPv4 WAN lease.
  Future<void> renewDhcpLease() => WanOperations.renewDhcpLease(_usp);

  /// Renew DHCPv6 WAN lease.
  Future<void> renewDhcpv6Lease() => WanOperations.renewDhcpv6Lease(_usp);

  /// Returns [edited] if it differs from [original], otherwise null.
  /// This ensures only changed values are sent in the USP Set message.
  T? _diff<T>(T original, T edited) => original != edited ? edited : null;
}
