import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/ppp_interface.g.dart';
import 'package:privacy_gui/generated/vlan_termination.g.dart';
import 'package:privacy_gui/generated/wan_bridge.g.dart';
import 'package:privacy_gui/generated/wan_dhcp.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_pppoe.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/generated/wan_static_ip.g.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

/// Stateless service that wraps USP generated code for internet settings.
///
/// Provides fetch, diff-based save, and DHCP renewal operations.
/// Handles PPP/VLAN multi-instance lifecycle (Add/Delete) and
/// DNS comma-separated conversion.
class UspInternetSettingsService {
  final UspClient _usp;

  UspInternetSettingsService(this._usp);

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch WAN, IPv6, PPP, and VLAN settings in parallel.
  Future<InternetSettingsFetchResult> fetchSettings() async {
    try {
      final results = await Future.wait([
        WanSettings.fetch(_usp),
        Ipv6Settings.fetch(_usp),
        PppInterface.fetch(_usp),
        VlanTermination.fetch(_usp),
      ]);
      final wan = results[0] as WanSettings;
      final ipv6 = results[1] as Ipv6Settings;
      final ppp = results[2] as PppInterface;
      final vlan = results[3] as VlanTermination;

      final pppInstance = ppp.items.isNotEmpty ? ppp.items.first : null;
      final vlanInstance = vlan.items.isNotEmpty ? vlan.items.first : null;

      return InternetSettingsFetchResult(
        form: _buildForm(wan, ipv6, pppInstance, vlanInstance),
        readOnlyInfo: _buildReadOnlyInfo(wan, pppInstance),
        pppInstancePath: pppInstance?.instancePath,
        vlanInstancePath: vlanInstance?.instancePath,
        debugAddressingType: wan.addressingType,
        debugBridgeEnabled: wan.bridgeEnabled,
        debugMtu: wan.mtu,
        debugIpv6Enabled: ipv6.ipv6Enabled,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Build form — DNS comma-separated split happens here
  // ---------------------------------------------------------------------------

  UspInternetSettingsForm _buildForm(
    WanSettings wan,
    Ipv6Settings ipv6,
    PppInterfaceInstance? ppp,
    VlanTerminationInstance? vlan,
  ) {
    // Split comma-separated DNS into 3 fields
    final dnsParts = wan.dnsServers
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return UspInternetSettingsForm(
      connectionType: UspWanConnectionType.fromRawFields(
        addressingType: wan.addressingType,
        bridgeEnabled: wan.bridgeEnabled,
      ),
      staticIpAddress: wan.staticIpAddress,
      subnetMask: wan.subnetMask,
      defaultGateway: wan.defaultGateway,
      dnsServer1: dnsParts.isNotEmpty ? dnsParts[0] : '',
      dnsServer2: dnsParts.length > 1 ? dnsParts[1] : '',
      dnsServer3: dnsParts.length > 2 ? dnsParts[2] : '',
      pppUsername: ppp?.username ?? '',
      pppPassword: ppp?.password ?? '',
      pppoeServiceName: ppp?.pppoeServiceName ?? '',
      connectionTrigger: ppp?.connectionTrigger ?? 'AlwaysOn',
      idleDisconnectTime: ppp?.idleDisconnectTime ?? 0,
      lcpEchoInterval: ppp?.lcpEcho ?? 0,
      vlanEnabled: vlan?.enable ?? false,
      vlanId: vlan?.vlanId ?? 0,
      mtu: wan.mtu,
      wanMacAddress: '',
      ipv6Enabled: ipv6.ipv6Enabled,
      dhcpv6Enabled: ipv6.dhcpv6Enabled,
      ipv6rdEnabled: ipv6.ipv6rdEnabled,
      ipv6rdPrefix: ipv6.ipv6rdPrefix,
      ipv6rdIpv4MaskLength: ipv6.ipv6rdIpv4MaskLength,
      ipv6rdBorderRelay: ipv6.ipv6rdBorderRelay,
    );
  }

  InternetSettingsReadOnlyInfo _buildReadOnlyInfo(
    WanSettings wan,
    PppInterfaceInstance? ppp,
  ) {
    return InternetSettingsReadOnlyInfo(
      currentMacAddress: '', // MAC Clone disabled
      pppConnectionStatus: ppp?.connectionStatus ?? '',
      staticIpAddress: wan.staticIpAddress,
    );
  }

  // ---------------------------------------------------------------------------
  // Save — orchestrates lifecycle + diff-based updates
  // ---------------------------------------------------------------------------

  /// Save all changed fields by comparing [original] vs [edited].
  ///
  /// Orchestration order:
  /// 1. Handle PPP instance lifecycle (Add/Delete)
  /// 2. Handle VLAN instance lifecycle (Add/Delete)
  /// 3. Save singleton WAN fields
  /// 4. Save PPP instance fields (if instance exists)
  /// 5. Save VLAN instance fields (if instance exists)
  /// 6. Save IPv6 fields
  Future<void> saveAll(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited, {
    String? pppInstancePath,
    String? vlanInstancePath,
  }) async {
    try {
      // Step 1: PPP lifecycle
      final pppPath = await _handlePppLifecycle(
        edited,
        currentInstancePath: pppInstancePath,
      );

      // Step 2: VLAN lifecycle
      final vlanPath = await _handleVlanLifecycle(
        original,
        edited,
        currentInstancePath: vlanInstancePath,
      );

      // Step 3: WAN mode switch or field edit (per-mode dispatch)
      final typeChanged = original.connectionType != edited.connectionType;
      final switchingToPppoe =
          typeChanged && edited.connectionType == UspWanConnectionType.pppoe;
      await _saveWanSettings(original, edited);

      // Step 4: PPP instance fields (skip username/password if already sent
      // in the ordered Set above)
      if (pppPath != null &&
          edited.connectionType == UspWanConnectionType.pppoe) {
        await _savePppSettings(original, edited, pppPath,
            skipCredentials: switchingToPppoe);
      }

      // Step 5: VLAN instance fields
      if (vlanPath != null && edited.vlanEnabled) {
        await _saveVlanSettings(original, edited, vlanPath);
      }

      // Step 6: IPv6 fields
      await _saveIpv6Settings(original, edited);
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // PPP Lifecycle — Add-only: create instance when entering PPPoE if missing
  // ---------------------------------------------------------------------------

  /// Returns the PPP instance path to use for subsequent Set operations,
  /// or null if no PPP instance exists after this step.
  ///
  /// Only creates a new instance when switching TO PPPoE and none exists.
  /// Never deletes — the instance persists across mode switches.
  Future<String?> _handlePppLifecycle(
    UspInternetSettingsForm edited, {
    String? currentInstancePath,
  }) async {
    final isPppoe = edited.connectionType == UspWanConnectionType.pppoe;

    if (isPppoe && currentInstancePath == null) {
      logger.d('[USP][WAN]: Adding PPP.Interface instance for PPPoE');
      final result = await PppInterface.add(_usp, [{}]);
      final parsedResult = UspResultParser.parseAddResult(result);
      if (parsedResult is UspSuccess<List<String>>) {
        final createdInstances = parsedResult.allCreatedInstances;
        if (createdInstances.isNotEmpty) {
          return createdInstances.first.affectedPath;
        }
      }
      return null;
    }

    return currentInstancePath;
  }

  // ---------------------------------------------------------------------------
  // VLAN Lifecycle (DD-2: Match toggle — Add when enabling, Delete when disabling)
  // ---------------------------------------------------------------------------

  /// Returns the VLAN instance path to use for subsequent Set operations,
  /// or null if no VLAN instance exists after this step.
  Future<String?> _handleVlanLifecycle(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited, {
    String? currentInstancePath,
  }) async {
    final wasEnabled = original.vlanEnabled;
    final isEnabled = edited.vlanEnabled;

    if (!wasEnabled && isEnabled && currentInstancePath == null) {
      // Enabling VLAN and no instance exists — Add
      logger.d('[USP][WAN]: Adding VLANTermination instance');
      final result = await VlanTermination.add(_usp, [{}]);
      // Extract instance path from structured response
      final parsedResult = UspResultParser.parseAddResult(result);
      if (parsedResult is UspSuccess<List<String>>) {
        final createdInstances = parsedResult.allCreatedInstances;
        if (createdInstances.isNotEmpty) {
          return createdInstances.first.affectedPath;
        }
      }
      return null;
    } else if (wasEnabled && !isEnabled && currentInstancePath != null) {
      // Disabling VLAN — Delete
      logger.d(
          '[USP][WAN]: Deleting VLANTermination instance $currentInstancePath');
      final deleteResult =
          await VlanTermination.delete(_usp, [currentInstancePath]);
      _handleDeleteResult(deleteResult);
      return null;
    }

    // No lifecycle change — return current path
    return currentInstancePath;
  }

  // ---------------------------------------------------------------------------
  // WAN singleton save — DNS merge happens here
  // ---------------------------------------------------------------------------

  Future<void> _saveWanSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    final typeChanged = original.connectionType != edited.connectionType;

    if (typeChanged) {
      switch (edited.connectionType) {
        case UspWanConnectionType.dhcp:
          _handleSetResult(await WanDhcp.update(_usp, addressingType: 'DHCP'));

        case UspWanConnectionType.staticIp:
          final dns = _mergeDns(
              edited.dnsServer1, edited.dnsServer2, edited.dnsServer3);
          _handleSetResult(await WanStaticIp.updateOrdered(
            _usp,
            WanStaticIp(
              addressingType: 'Static',
              staticIpAddress: edited.staticIpAddress,
              subnetMask: edited.subnetMask,
              defaultGateway: edited.defaultGateway,
              dnsServers: dns,
            ),
          ));

        case UspWanConnectionType.pppoe:
          _handleSetResult(await WanPppoe.update(
            _usp,
            pppUsername: edited.pppUsername,
            pppPassword: edited.pppPassword,
            addressingType: 'IPCP',
            allowPartial: true,
          ));

        case UspWanConnectionType.bridge:
          _handleSetResult(await WanBridge.update(_usp, addressingType: ''));
      }
    } else {
      switch (edited.connectionType) {
        case UspWanConnectionType.staticIp:
          final originalDns = _mergeDns(
              original.dnsServer1, original.dnsServer2, original.dnsServer3);
          final editedDns = _mergeDns(
              edited.dnsServer1, edited.dnsServer2, edited.dnsServer3);
          _handleSetResult(await WanStaticIp.update(
            _usp,
            staticIpAddress:
                _diff(original.staticIpAddress, edited.staticIpAddress),
            subnetMask: _diff(original.subnetMask, edited.subnetMask),
            defaultGateway:
                _diff(original.defaultGateway, edited.defaultGateway),
            dnsServers: _diff(originalDns, editedDns),
          ));

        case UspWanConnectionType.dhcp:
        case UspWanConnectionType.bridge:
          break;

        case UspWanConnectionType.pppoe:
          break;
      }
    }

    // MTU is mode-independent — update via WanSettings if changed
    final mtuDiff = _diff(original.mtu, edited.mtu);
    if (mtuDiff != null) {
      _handleSetResult(await WanSettings.update(_usp, mtu: mtuDiff));
    }
  }

  // ---------------------------------------------------------------------------
  // PPP instance save
  // ---------------------------------------------------------------------------

  Future<void> _savePppSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath, {
    bool skipCredentials = false,
  }) async {
    _handleSetResult(await PppInterface.update(
      _usp,
      [
        PppInterfaceInstanceUpdate(
          instancePath: instancePath,
          username: skipCredentials
              ? null
              : _diff(original.pppUsername, edited.pppUsername),
          password: skipCredentials
              ? null
              : _diff(original.pppPassword, edited.pppPassword),
          // pppoeServiceName — disabled: bbfdm rejects SET (fault 9001)
          // pppoeServiceName:
          //     _diff(original.pppoeServiceName, edited.pppoeServiceName),
          connectionTrigger:
              _diff(original.connectionTrigger, edited.connectionTrigger),
          idleDisconnectTime:
              _diff(original.idleDisconnectTime, edited.idleDisconnectTime),
        )
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // VLAN instance save
  // ---------------------------------------------------------------------------

  Future<void> _saveVlanSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath,
  ) async {
    _handleSetResult(await VlanTermination.update(
      _usp,
      [
        VlanTerminationInstanceUpdate(
          instancePath: instancePath,
          enable: _diff(original.vlanEnabled, edited.vlanEnabled),
          vlanId: _diff(original.vlanId, edited.vlanId),
        )
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // IPv6 save
  // ---------------------------------------------------------------------------

  Future<void> _saveIpv6Settings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    _handleSetResult(await Ipv6Settings.update(
      _usp,
      ipv6Enabled: _diff(original.ipv6Enabled, edited.ipv6Enabled),
      dhcpv6Enabled: _diff(original.dhcpv6Enabled, edited.dhcpv6Enabled),
      ipv6rdEnabled: _diff(original.ipv6rdEnabled, edited.ipv6rdEnabled),
      ipv6rdPrefix: _diff(original.ipv6rdPrefix, edited.ipv6rdPrefix),
      ipv6rdIpv4MaskLength:
          _diff(original.ipv6rdIpv4MaskLength, edited.ipv6rdIpv4MaskLength),
      ipv6rdBorderRelay:
          _diff(original.ipv6rdBorderRelay, edited.ipv6rdBorderRelay),
    ));
  }

  // ---------------------------------------------------------------------------
  // DHCP Renewal
  // ---------------------------------------------------------------------------

  Future<void> renewDhcpLease() async {
    try {
      final result = await WanOperations.renewDhcpLease(_usp);
      _handleOperateResult(result);
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<void> renewDhcpv6Lease() async {
    try {
      final result = await WanOperations.renewDhcpv6Lease(_usp);
      _handleOperateResult(result);
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Merge 3 DNS fields into comma-separated string.
  String _mergeDns(String dns1, String dns2, String dns3) {
    return [dns1, dns2, dns3].where((s) => s.isNotEmpty).join(',');
  }

  /// Returns [edited] if it differs from [original], otherwise null.
  T? _diff<T>(T original, T edited) => original != edited ? edited : null;

  /// Parse and validate SET result using standard UspResultParser (Strict mode).
  ///
  /// WAN settings are critical — any failure (including partial) should be
  /// reported to the user.
  void _handleSetResult(Map<String, dynamic> result) {
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'WAN update partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'WAN update failed: $errorSummary',
          failures: errors,
        );
    }
  }

  /// Parse and validate DELETE result using standard UspResultParser (Strict mode).
  void _handleDeleteResult(Map<String, dynamic> result) {
    final parsed = UspResultParser.parseDeleteResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'WAN delete partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'WAN delete failed: $errorSummary',
          failures: errors,
        );
    }
  }

  /// Parse and validate OPERATE result using standard UspResultParser (Strict mode).
  void _handleOperateResult(Map<String, dynamic> result) {
    final parsed = UspResultParser.parseOperateResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'WAN operation partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'WAN operation failed: $errorSummary',
          failures: errors,
        );
    }
  }
}

/// Result of [UspInternetSettingsService.fetchSettings].
class InternetSettingsFetchResult {
  final UspInternetSettingsForm form;
  final InternetSettingsReadOnlyInfo readOnlyInfo;

  /// Instance paths for lifecycle management — tracked by state/notifier.
  final String? pppInstancePath;
  final String? vlanInstancePath;

  /// Debug fields for logging — not exposed to UI.
  final String debugAddressingType;
  final bool debugBridgeEnabled;
  final int debugMtu;
  final bool debugIpv6Enabled;

  const InternetSettingsFetchResult({
    required this.form,
    required this.readOnlyInfo,
    this.pppInstancePath,
    this.vlanInstancePath,
    this.debugAddressingType = '',
    this.debugBridgeEnabled = false,
    this.debugMtu = 0,
    this.debugIpv6Enabled = false,
  });
}
