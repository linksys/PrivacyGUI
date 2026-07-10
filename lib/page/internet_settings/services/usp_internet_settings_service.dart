import 'dart:async';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/gre_tunnel.g.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/l2tp_tunnel.g.dart';
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
/// Handles PPP instance lifecycle (Add) and VLAN enable/disable via SET on an
/// existing instance, plus DNS comma-separated conversion.
class UspInternetSettingsService {
  final UspClient _usp;

  UspInternetSettingsService(this._usp);

  /// Timeout for the terminal bridge-mode SET.
  ///
  /// Entering bridge is terminal-by-design: on receiving the
  /// `AddressingType=""` SET the firmware applies bridge mode and bounces the
  /// LAN link (fw >= 1.2.2.26070203) / reloads the network within ~2s, which
  /// tears down the very connection carrying this request's response. Verified
  /// on-device: obuspa applies the SET and returns a SET_RESP over its local
  /// UDS (rc=0), but the app never receives the HTTP response because the
  /// transport is already gone. 4s leaves headroom over the observed ~2s
  /// disconnect without making the user wait the full 15s throttler timeout on
  /// a SET that has already succeeded. See [_applyBridgeMode].
  static const _bridgeSetTimeout = Duration(seconds: 4);

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch WAN, IPv6, PPP, VLAN, and tunnel settings in parallel.
  Future<InternetSettingsFetchResult> fetchSettings() async {
    try {
      final results = await Future.wait([
        WanSettings.fetch(_usp),
        Ipv6Settings.fetch(_usp),
        PppInterface.fetch(_usp),
        VlanTermination.fetch(_usp),
        GreTunnel.fetch(_usp),
        L2tpTunnel.fetch(_usp),
        _fetchHostName(),
      ]);
      final wan = results[0] as WanSettings;
      final ipv6 = results[1] as Ipv6Settings;
      final ppp = results[2] as PppInterface;
      final vlan = results[3] as VlanTermination;
      final gre = results[4] as GreTunnel;
      final l2tp = results[5] as L2tpTunnel;
      final hostName = results[6] as String;

      final pppInstance = ppp.items.isNotEmpty ? ppp.items.first : null;
      final vlanInstance = vlan.items.isNotEmpty ? vlan.items.first : null;

      return InternetSettingsFetchResult(
        form: _buildForm(wan, ipv6, pppInstance, vlanInstance, gre, l2tp),
        readOnlyInfo: _buildReadOnlyInfo(wan, pppInstance, hostName),
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

  /// Targeted GET of the router hostname. Returns '' on any missing value so a
  /// hostname-less device degrades gracefully (no bridge redirect target).
  Future<String> _fetchHostName() async {
    const path = 'Device.DeviceInfo.HostName';
    final response = await _usp.get([path]);
    return (response[path] ?? '') as String;
  }

  // ---------------------------------------------------------------------------
  // Build form — DNS comma-separated split happens here
  // ---------------------------------------------------------------------------

  UspInternetSettingsForm _buildForm(
    WanSettings wan,
    Ipv6Settings ipv6,
    PppInterfaceInstance? ppp,
    VlanTerminationInstance? vlan,
    GreTunnel gre,
    L2tpTunnel l2tp,
  ) {
    // Split comma-separated DNS into 3 fields
    final dnsParts = wan.dnsServers
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final lowerLayers = ppp?.lowerLayers ?? '';
    final connectionType = UspWanConnectionType.fromRawFields(
      addressingType: wan.addressingType,
      lowerLayers: lowerLayers,
    );

    // Resolve server address from the appropriate tunnel
    final serverAddress = switch (connectionType) {
      UspWanConnectionType.pptp => gre.remoteEndpoints,
      UspWanConnectionType.l2tp => l2tp.remoteEndpoints,
      _ => '',
    };

    return UspInternetSettingsForm(
      connectionType: connectionType,
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
      serverAddress: serverAddress,
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
    String hostName,
  ) {
    return InternetSettingsReadOnlyInfo(
      currentMacAddress: '', // MAC Clone disabled
      pppConnectionStatus: ppp?.connectionStatus ?? '',
      staticIpAddress: wan.staticIpAddress,
      hostName: hostName,
    );
  }

  // ---------------------------------------------------------------------------
  // Save — orchestrates lifecycle + diff-based updates
  // ---------------------------------------------------------------------------

  /// Save all changed fields by comparing [original] vs [edited].
  ///
  /// Orchestration order:
  /// 1. Handle PPP instance lifecycle (Add if needed)
  /// 2. Save singleton WAN fields (mode switch or field edit) — must precede
  ///    tunnel writes so the firmware syncs `proto` and the GRE/L2TPv2 tunnel
  ///    instance becomes valid (per Architecture issue #119)
  /// 3. Set PPP LowerLayers (tunnel type selection)
  /// 4. Set tunnel RemoteEndpoints (server address)
  /// 5. Save PPP instance fields (credentials, connection mode)
  /// 6. Save VLAN instance fields (if instance exists)
  /// 7. Save IPv6 fields
  /// 8. Apply terminal bridge SET last (drops the connection; see
  ///    [_applyBridgeMode]) so every other SET lands on a live connection
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

      // Step 2: WAN mode switch or field edit (per-mode dispatch). Setting
      // AddressingType=IPCP first lets the firmware sync proto=pptp/l2tp so the
      // tunnel instance becomes valid before its RemoteEndpoints is written.
      //
      // Entering bridge is terminal: the bridge SET drops this connection (see
      // _applyBridgeMode). Defer it so the FW-spec VLAN/IPv6 SETs below still
      // land on a live connection; it is sent last, in Step 6.
      final typeChanged = original.connectionType != edited.connectionType;
      final switchingToPppBased =
          typeChanged && edited.connectionType.isPppBased;
      final enteringBridge =
          typeChanged && edited.connectionType == UspWanConnectionType.bridge;
      await _saveWanSettings(original, edited, deferBridge: enteringBridge);

      // Step 3: Set LowerLayers on PPP instance (tunnel type selection)
      if (pppPath != null && edited.connectionType.isPppBased) {
        await _savePppLowerLayers(original, edited, pppPath);
      }

      // Step 4: Set tunnel RemoteEndpoints (server address)
      await _saveTunnelRemoteEndpoints(original, edited);

      // Step 5: PPP instance fields (skip username/password if already sent
      // in the ordered Set above)
      if (pppPath != null && edited.connectionType.isPppBased) {
        await _savePppSettings(original, edited, pppPath,
            skipCredentials: switchingToPppBased);
      }

      // Step 6: VLAN settings (always use SET on existing instance)
      if (vlanInstancePath != null) {
        await _saveVlanSettings(original, edited, vlanInstancePath);
      }

      // Step 7: IPv6 fields
      await _saveIpv6Settings(original, edited);

      // Step 8: terminal bridge SET — last, once every other SET has landed.
      if (enteringBridge) {
        await _applyBridgeMode();
      }
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
  /// Only creates a new instance when switching TO a PPP-based type and none
  /// exists. Never deletes — the instance persists across mode switches.
  Future<String?> _handlePppLifecycle(
    UspInternetSettingsForm edited, {
    String? currentInstancePath,
  }) async {
    final isPppBased = edited.connectionType.isPppBased;

    if (isPppBased && currentInstancePath == null) {
      logger.d('[USP][WAN]: Adding PPP.Interface instance for '
          '${edited.connectionType.name}');
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
  // WAN singleton save — DNS merge happens here
  // ---------------------------------------------------------------------------

  /// Saves the WAN singleton fields for the target mode.
  ///
  /// When [deferBridge] is true and the edit is an entering-bridge transition,
  /// the terminal bridge SET is skipped here so [saveAll] can send it last,
  /// after the FW-spec VLAN/IPv6 SETs have landed on a still-live connection.
  Future<void> _saveWanSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited, {
    bool deferBridge = false,
  }) async {
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

        case UspWanConnectionType.pptp:
        case UspWanConnectionType.l2tp:
          _handleSetResult(await WanPppoe.update(
            _usp,
            pppUsername: edited.pppUsername,
            pppPassword: edited.pppPassword,
            addressingType: 'IPCP',
            allowPartial: true,
          ));

        case UspWanConnectionType.bridge:
          // When deferred, saveAll sends the terminal bridge SET last (after
          // VLAN/IPv6) via _applyBridgeMode(); otherwise apply it here.
          if (!deferBridge) await _applyBridgeMode();
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
        case UspWanConnectionType.pptp:
        case UspWanConnectionType.l2tp:
          break;
      }
    }

    // MTU is mode-independent — update via WanSettings if changed.
    //
    // Bridge is the exception: switching to bridge resets the form's mtu to 0
    // as a sentinel, and the FW rejects MaxMTUSize=0 (valid range 64..65535,
    // errorCode 7012) — confirmed with the FW team that 0 is NOT a valid "auto"
    // value. Sending it would abort saveAll before the terminal bridge SET, so
    // skip the MTU SET entirely when the target mode is bridge (MTU has no
    // meaning once the WAN port joins br-lan).
    if (edited.connectionType != UspWanConnectionType.bridge) {
      final mtuDiff = _diff(original.mtu, edited.mtu);
      if (mtuDiff != null) {
        _handleSetResult(await WanSettings.update(_usp, mtu: mtuDiff));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Bridge mode apply — terminal, fire-and-forget by design
  // ---------------------------------------------------------------------------

  /// Applies bridge mode via the WAN `AddressingType=""` SET.
  ///
  /// This SET is terminal-by-design (see [_bridgeSetTimeout]): the firmware
  /// applies bridge mode and drops the connection carrying the response, so a
  /// transport-level timeout/network error on THIS SET is the expected
  /// signature of success — the SET was received and applied on-device before
  /// the disconnect. Those two cases are swallowed.
  ///
  /// Any error the router actively returns BEFORE the disconnect — a fault code
  /// mapped to a validation / resource / partial / auth / unexpected
  /// [ServiceError] — means the SET was rejected. Those propagate so the user
  /// still sees the failure; a real config failure is never hidden.
  Future<void> _applyBridgeMode() async {
    try {
      _handleSetResult(
        await WanBridge.update(_usp, addressingType: '')
            .timeout(_bridgeSetTimeout),
      );
    } on TimeoutException {
      // No response within the budget: the firmware applied bridge mode and
      // dropped the connection, so the SET_RESP can never arrive. Expected
      // success. (Future.timeout keeps an error listener on the underlying
      // request, so its eventual late error is consumed, not left unhandled.)
      logger.i(
          '[USP][WAN]: bridge SET timed out after ${_bridgeSetTimeout.inSeconds}s '
          '— treating as success (firmware dropped the connection applying bridge mode)');
    } catch (e) {
      // Reached when the request fails BEFORE the timeout. A transport /
      // connectivity error is the same disconnect signature → success. But
      // anything the router actively rejected — a fault code mapped to
      // validation/resource/auth, or a partial/complete failure surfaced by
      // _handleSetResult (already a ServiceError) — propagates, so a genuine
      // config failure is never swallowed.
      if (e is ServiceError) rethrow;
      final mapped = mapUspErrorToServiceError(e);
      if (mapped is NetworkError || mapped is ConnectivityError) {
        logger.i('[USP][WAN]: bridge SET hit a transport error '
            '— treating as success (firmware dropped the connection applying bridge mode)');
        return;
      }
      throw mapped;
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
          pppoeServiceName:
              _diff(original.pppoeServiceName, edited.pppoeServiceName),
          connectionTrigger:
              _diff(original.connectionTrigger, edited.connectionTrigger),
          idleDisconnectTime:
              _diff(original.idleDisconnectTime, edited.idleDisconnectTime),
        )
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // PPP LowerLayers — sets the tunnel type reference
  // ---------------------------------------------------------------------------

  Future<void> _savePppLowerLayers(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath,
  ) async {
    final targetLowerLayers = edited.connectionType.pppLowerLayers;
    if (targetLowerLayers == null) return;

    final originalLowerLayers = original.connectionType.pppLowerLayers ?? '';
    if (originalLowerLayers == targetLowerLayers) return;

    logger.d('[USP][WAN]: Setting LowerLayers to $targetLowerLayers');
    _handleSetResult(await PppInterface.update(
      _usp,
      [
        PppInterfaceInstanceUpdate(
          instancePath: instancePath,
          lowerLayers: targetLowerLayers,
        )
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // Tunnel RemoteEndpoints — server address for PPTP/L2TP
  // ---------------------------------------------------------------------------

  Future<void> _saveTunnelRemoteEndpoints(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    final serverDiff = _diff(original.serverAddress, edited.serverAddress);
    if (serverDiff == null) return;

    switch (edited.connectionType) {
      case UspWanConnectionType.pptp:
        logger.d('[USP][WAN]: Setting GRE RemoteEndpoints to $serverDiff');
        _handleSetResult(
            await GreTunnel.update(_usp, remoteEndpoints: serverDiff));
      case UspWanConnectionType.l2tp:
        logger.d('[USP][WAN]: Setting L2TP RemoteEndpoints to $serverDiff');
        _handleSetResult(
            await L2tpTunnel.update(_usp, remoteEndpoints: serverDiff));
      default:
        break;
    }
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
      await WanOperations.renewDhcpLease(_usp);
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<void> renewDhcpv6Lease() async {
    try {
      await WanOperations.renewDhcpv6Lease(_usp);
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
}

/// Result of [UspInternetSettingsService.fetchSettings].
class InternetSettingsFetchResult {
  final UspInternetSettingsForm form;
  final InternetSettingsReadOnlyInfo readOnlyInfo;

  /// Existing instance paths tracked by state/notifier: [pppInstancePath] for
  /// the PPP instance lifecycle, [vlanInstancePath] as the SET target for VLAN
  /// enable/disable.
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
