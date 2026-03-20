import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

/// Stateless service that wraps USP generated code for internet settings.
///
/// Provides fetch, diff-based save, and DHCP renewal operations.
class UspInternetSettingsService {
  final UspService _usp;

  UspInternetSettingsService(this._usp);

  /// Fetch both WAN and IPv6 settings in parallel, returning the form
  /// and read-only info needed by the notifier.
  Future<InternetSettingsFetchResult> fetchSettings() async {
    final results = await Future.wait([
      WanSettings.fetch(_usp),
      Ipv6Settings.fetch(_usp),
    ]);
    final wan = results[0] as WanSettings;
    final ipv6 = results[1] as Ipv6Settings;
    return InternetSettingsFetchResult(
      form: _buildForm(wan, ipv6),
      readOnlyInfo: _buildReadOnlyInfo(wan, ipv6),
      debugAddressingType: wan.addressingType,
      debugBridgeEnabled: wan.bridgeEnabled,
      debugMtu: wan.mtu,
      debugIpv6Enabled: ipv6.ipv6Enabled,
    );
  }

  /// Build a [UspInternetSettingsForm] from raw codegen models.
  UspInternetSettingsForm _buildForm(WanSettings wan, Ipv6Settings ipv6) {
    return UspInternetSettingsForm(
      connectionType: UspWanConnectionType.fromRawFields(
        addressingType: wan.addressingType,
        bridgeEnabled: wan.bridgeEnabled,
      ),
      staticIpAddress: wan.staticIpAddress,
      subnetMask: wan.subnetMask,
      defaultGateway: wan.defaultGateway,
      dnsServer1: wan.dnsServer1,
      dnsServer2: wan.dnsServer2,
      dnsServer3: wan.dnsServer3,
      pppUsername: wan.pppUsername,
      pppPassword: wan.pppPassword,
      pppoeServiceName: wan.pppoeServiceName,
      connectionTrigger: wan.connectionTrigger,
      idleDisconnectTime: wan.idleDisconnectTime,
      lcpEchoInterval: wan.lcpEchoInterval,
      vlanEnabled: wan.vlanEnabled,
      vlanId: wan.vlanId,
      mtu: wan.mtu,
      wanMacAddress: wan.wanMacAddress,
      ipv6Enabled: ipv6.ipv6Enabled,
      dhcpv6Enabled: ipv6.dhcpv6Enabled,
      ipv6rdEnabled: ipv6.ipv6rdEnabled,
      ipv6rdPrefix: ipv6.ipv6rdPrefix,
      ipv6rdIpv4MaskLength: ipv6.ipv6rdIpv4MaskLength,
      ipv6rdBorderRelay: ipv6.ipv6rdBorderRelay,
    );
  }

  /// Build read-only display info from raw codegen models.
  InternetSettingsReadOnlyInfo _buildReadOnlyInfo(
    WanSettings wan,
    Ipv6Settings ipv6,
  ) {
    return InternetSettingsReadOnlyInfo(
      currentMacAddress: wan.currentMacAddress,
      pppConnectionStatus: wan.pppConnectionStatus,
      dhcpv6Duid: ipv6.dhcpv6Duid,
      staticIpAddress: wan.staticIpAddress,
    );
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

/// Result of [UspInternetSettingsService.fetchSettings].
class InternetSettingsFetchResult {
  final UspInternetSettingsForm form;
  final InternetSettingsReadOnlyInfo readOnlyInfo;

  /// Debug fields for logging — not exposed to UI.
  final String debugAddressingType;
  final bool debugBridgeEnabled;
  final int debugMtu;
  final bool debugIpv6Enabled;

  const InternetSettingsFetchResult({
    required this.form,
    required this.readOnlyInfo,
    this.debugAddressingType = '',
    this.debugBridgeEnabled = false,
    this.debugMtu = 0,
    this.debugIpv6Enabled = false,
  });
}
