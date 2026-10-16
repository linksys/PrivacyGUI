import 'dart:async';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dhcpv6clients.g.dart';
import 'package:privacy_gui/generated/gre_tunnels.g.dart';
import 'package:privacy_gui/generated/ipv6rd_settings.g.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/l2tp_tunnels.g.dart';
import 'package:privacy_gui/generated/ppp_interface.g.dart';
import 'package:privacy_gui/generated/vlan_termination.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
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

  /// How long entering bridge waits after its SET before [saveAll] returns.
  final Duration _bridgeSettleDelay;

  UspInternetSettingsService(
    this._usp, {
    Duration bridgeSettleDelay = defaultBridgeSettleDelay,
  }) : _bridgeSettleDelay = bridgeSettleDelay;

  /// Timeout for the terminal bridge-mode SETs (both directions).
  ///
  /// Crossing the bridge boundary is terminal-by-design. The firmware's set
  /// handler for `Device.IP.Interface.{wan}.Enable` moves the WAN device in or
  /// out of `br-lan`, commits, and then runs `/usr/sbin/bridge-mode-apply.sh
  /// enter|exit`, which stops or restarts firewall and dnsmasq, bounces the
  /// physical switch ports, deauths the wireless clients and restarts lighttpd.
  /// Any one of those tears down the very connection carrying this request's
  /// response. Verified on-device: obuspa applies the SET and returns a
  /// SET_RESP over its local UDS (rc=0), but the app never receives the HTTP
  /// response because the transport is already gone. 4s leaves headroom over
  /// the observed ~2s disconnect without making the user wait the full 15s
  /// throttler timeout on a SET that has already succeeded. See
  /// [_enterBridgeMode] and [_exitBridgeMode].
  static const _bridgeSetTimeout = Duration(seconds: 4);

  /// Default for [_bridgeSettleDelay].
  ///
  /// The router is reachable again at `<hostName>.local` only T+20–25s after
  /// entering bridge, T being the SET returning (#762 comment 5987286082), so
  /// the caller's next step — redirecting there — waits for it here.
  static const defaultBridgeSettleDelay = Duration(seconds: 20);

  /// The WAN tunnel and 6rd rows.
  ///
  /// GRE, L2TPv2 and IPv6rd are tables, so the generated models return every
  /// row. The firmware drives the WAN through row 1 of each — the PPP
  /// `LowerLayers` values in [UspWanConnectionType.pppLowerLayers] name
  /// `Tunnel.1`, and linksys/PrivacyGUI#762 (comment 5987286082) keeps
  /// instance `.1` for both tunnels. Which 6rd row is the WAN one is still
  /// unconfirmed upstream (usp_framework#73), so it stays on row 1 as before.
  static const _greTunnelPath = 'Device.GRE.Tunnel.1.';
  static const _l2tpTunnelPath = 'Device.L2TPv2.Tunnel.1.';
  static const _ipv6rdPath = 'Device.IPv6rd.InterfaceSetting.1.';

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch WAN, IPv6, PPP, and VLAN settings in parallel, then the tunnel that
  /// the resolved connection type actually uses.
  ///
  /// Tables are read as lists, so a row the current WAN state does not have is
  /// an empty list rather than a failed fetch: bridge mode drops the WAN
  /// `IPv4Address` row (#1597).
  Future<InternetSettingsFetchResult> fetchSettings() async {
    try {
      // Phase 1 — always needed, fetched in parallel.
      final results = await Future.wait([
        WanSettings.fetch(_usp),
        Ipv6Settings.fetch(_usp),
        PppInterface.fetch(_usp),
        VlanTermination.fetch(_usp),
        _fetchHostName(),
        Dhcpv6Clients.fetch(_usp),
        Ipv6rdSettings.fetch(_usp),
      ]);
      final wan = results[0] as WanSettings;
      final ipv6 = results[1] as Ipv6Settings;
      final ppp = results[2] as PppInterface;
      final vlan = results[3] as VlanTermination;
      final hostName = results[4] as String;
      final dhcpv6 = results[5] as Dhcpv6Clients;
      final ipv6rd = results[6] as Ipv6rdSettings;

      final pppInstance = ppp.items.isNotEmpty ? ppp.items.first : null;
      final vlanInstance = vlan.items.isNotEmpty ? vlan.items.first : null;
      final ipv4 = wan.ipv4Addresses.firstOrNull;
      final addressingType = ipv4?.addressingType ?? '';

      // Phase 2 — tunnel is connection-type-specific. Only fetch the tunnel
      // the current connection type actually uses.
      final connectionType = UspWanConnectionType.fromRawFields(
        addressingType: addressingType,
        interfaceEnabled: wan.enable,
        lowerLayers: pppInstance?.lowerLayers ?? '',
      );
      GreTunnel? gre;
      L2tpTunnel? l2tp;
      switch (connectionType) {
        case UspWanConnectionType.pptp:
          gre = _rowAt((await GreTunnels.fetch(_usp)).items, _greTunnelPath,
              (r) => r.instancePath);
        case UspWanConnectionType.l2tp:
          l2tp = _rowAt((await L2tpTunnels.fetch(_usp)).items, _l2tpTunnelPath,
              (r) => r.instancePath);
        default:
          break;
      }

      return InternetSettingsFetchResult(
        form: _buildForm(
          wan: wan,
          ipv4: ipv4,
          ipv6: ipv6,
          dhcpv6: _wanDhcpv6Client(dhcpv6, wan.instancePath),
          ipv6rd: _rowAt(ipv6rd.items, _ipv6rdPath, (r) => r.instancePath),
          ppp: pppInstance,
          vlan: vlanInstance,
          gre: gre,
          l2tp: l2tp,
          connectionType: connectionType,
        ),
        readOnlyInfo: _buildReadOnlyInfo(pppInstance, hostName),
        pppInstancePath: pppInstance?.instancePath,
        vlanInstancePath: vlanInstance?.instancePath,
        // Absent key means firmware predating feed_bbf#128 — the UI hides the
        // Auto MTU toggle rather than offering a mode it cannot write.
        mtuModeSupported: wan.mtuMode != null,
        debugAddressingType: addressingType,
        debugInterfaceEnabled: wan.enable,
        debugMtu: wan.mtu,
        debugIpv6Enabled: ipv6.ipv6Enabled,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The row of [rows] at [path], or null when the table has no such row.
  static T? _rowAt<T>(List<T> rows, String path, String Function(T) pathOf) {
    for (final row in rows) {
      if (pathOf(row) == path) return row;
    }
    return null;
  }

  /// The DHCPv6 client bound to the WAN interface.
  ///
  /// `Device.DHCPv6.Client.{i}.Interface` names the IP.Interface the client
  /// runs on, with or without the trailing dot.
  static Dhcpv6Client? _wanDhcpv6Client(Dhcpv6Clients clients, String wanPath) {
    final wan = wanPath.endsWith('.')
        ? wanPath.substring(0, wanPath.length - 1)
        : wanPath;
    for (final client in clients.items) {
      final iface = client.interface_.endsWith('.')
          ? client.interface_.substring(0, client.interface_.length - 1)
          : client.interface_;
      if (iface == wan) return client;
    }
    return null;
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

  /// [ipv4], [dhcpv6], [ipv6rd], [gre] and [l2tp] are rows of tables that may
  /// be empty: no WAN `IPv4Address` row in bridge mode, no DHCPv6 client bound
  /// to the WAN, no tunnel row. An absent row reads as that row's defaults.
  UspInternetSettingsForm _buildForm({
    required WanSettings wan,
    required WanSettingsIpv4Address? ipv4,
    required Ipv6Settings ipv6,
    required Dhcpv6Client? dhcpv6,
    required Ipv6rdSetting? ipv6rd,
    required PppInterfaceInstance? ppp,
    required VlanTerminationInstance? vlan,
    required GreTunnel? gre,
    required L2tpTunnel? l2tp,
    required UspWanConnectionType connectionType,
  }) {
    // Split comma-separated DNS into 3 fields
    final dnsParts = (ipv4?.dnsServers ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Server address from the tunnel fetchSettings' phase 2 loaded for this
    // connection type. A PPTP/L2TP WAN whose Tunnel.1 row is absent reads as
    // an empty server address, which fails form validation and prompts the
    // user to re-enter it.
    final serverAddress = switch (connectionType) {
      UspWanConnectionType.pptp => gre?.remoteEndpoints ?? '',
      UspWanConnectionType.l2tp => l2tp?.remoteEndpoints ?? '',
      _ => '',
    };

    return UspInternetSettingsForm(
      connectionType: connectionType,
      staticIpAddress: ipv4?.ipAddress ?? '',
      subnetMask: ipv4?.subnetMask ?? '',
      defaultGateway: ipv4?.defaultGateway ?? '',
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
      // Firmware without the vendor extension returns null → Manual, which is
      // what the app assumed before X_LINKSYS_MTUMode existed.
      mtuAuto: wan.mtuMode == 'Auto',
      wanMacAddress: '',
      ipv6Enabled: ipv6.ipv6Enabled,
      dhcpv6Enabled: dhcpv6?.enable ?? false,
      ipv6rdEnabled: ipv6rd?.enabled ?? false,
      ipv6rdPrefix: ipv6rd?.prefix ?? '',
      ipv6rdIpv4MaskLength: ipv6rd?.ipv4MaskLength ?? 0,
      ipv6rdBorderRelay: ipv6rd?.borderRelay ?? '',
    );
  }

  InternetSettingsReadOnlyInfo _buildReadOnlyInfo(
    PppInterfaceInstance? ppp,
    String hostName,
  ) {
    return InternetSettingsReadOnlyInfo(
      pppConnectionStatus: ppp?.connectionStatus ?? '',
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
  /// 2. Save the WAN IPv4 row (mode switch or field edit) — must precede
  ///    tunnel writes so the firmware syncs `proto` and the GRE/L2TPv2 tunnel
  ///    instance becomes valid (per Architecture issue #119)
  /// 3. Save PPP LowerLayers + credentials (one batch on a mode switch)
  /// 4. Set tunnel RemoteEndpoints (server address)
  /// 5. Save PPP instance fields (connection mode)
  /// 6. Save VLAN instance fields (if instance exists)
  /// 7. Save IPv6 fields
  /// 8. Cross the bridge boundary last (drops the connection; see
  ///    [_enterBridgeMode] / [_exitBridgeMode]) so every other SET lands on a
  ///    live connection
  ///
  /// Leaving bridge writes no target-mode parameter at all. The WAN
  /// `IPv4Address` row does not exist while bridged, so a target AddressingType
  /// SET faults 9005, and it reappears only after `Enable=true` has run
  /// `bridge-mode-apply.sh exit` (#762 comment 5987286082): the target mode is
  /// set once the user has reconnected.
  Future<void> saveAll(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited, {
    String? pppInstancePath,
    String? vlanInstancePath,
  }) async {
    if (edited.connectionType == UspWanConnectionType.ipoe) {
      throw const InvalidInputError(
          detail: 'IPoE requires the Auto-IPoE workflow');
    }
    try {
      final typeChanged = original.connectionType != edited.connectionType;
      final enteringBridge =
          typeChanged && edited.connectionType == UspWanConnectionType.bridge;
      final leavingBridge =
          typeChanged && original.connectionType == UspWanConnectionType.bridge;

      if (!leavingBridge) {
        // Step 1: PPP lifecycle
        final pppPath = await _handlePppLifecycle(
          edited,
          currentInstancePath: pppInstancePath,
        );

        // Step 2: WAN mode switch or field edit (per-mode dispatch). Setting
        // AddressingType=IPCP first lets the firmware sync proto=pptp/l2tp so
        // the tunnel instance becomes valid before its RemoteEndpoints is
        // written.
        await _saveWanSettings(original, edited);

        // Step 3: PPP LowerLayers + credentials
        if (pppPath != null && edited.connectionType.isPppBased) {
          await _savePppLink(original, edited, pppPath);
        }

        // Step 4: Set tunnel RemoteEndpoints (server address)
        await _saveTunnelRemoteEndpoints(original, edited);

        // Step 5: PPP instance fields
        if (pppPath != null && edited.connectionType.isPppBased) {
          await _savePppSettings(original, edited, pppPath);
        }
      }

      // Step 6: VLAN settings (always use SET on existing instance)
      if (vlanInstancePath != null) {
        await _saveVlanSettings(original, edited, vlanInstancePath);
      }

      // Step 7: IPv6 fields
      await _saveIpv6Settings(original, edited);

      // Step 8: terminal bridge-boundary SET — last, once every other SET has
      // landed. The two are mutually exclusive: one tests the edited type, the
      // other the original.
      if (enteringBridge) {
        await _enterBridgeMode();
      } else if (leavingBridge) {
        await _exitBridgeMode();
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

  /// Saves the WAN IPv4 row and MTU for the target mode.
  ///
  /// The bridge boundary is deliberately not crossed here: both directions are
  /// a single terminal SET that [saveAll] sends last, once the FW-spec
  /// VLAN/IPv6 SETs have landed on a still-live connection.
  Future<void> _saveWanSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
  ) async {
    final typeChanged = original.connectionType != edited.connectionType;

    if (typeChanged) {
      switch (edited.connectionType) {
        case UspWanConnectionType.ipoe:
          throw const InvalidInputError();
        case UspWanConnectionType.dhcp:
          await _updateWanIpv4((path) => WanSettingsIpv4AddressUpdate(
              instancePath: path, addressingType: 'DHCP'));

        case UspWanConnectionType.staticIp:
          final dns = _mergeDns(
              edited.dnsServer1, edited.dnsServer2, edited.dnsServer3);
          await _updateWanIpv4((path) => WanSettingsIpv4AddressUpdate(
                instancePath: path,
                addressingType: 'Static',
                ipAddress: edited.staticIpAddress,
                subnetMask: edited.subnetMask,
                defaultGateway: edited.defaultGateway,
                dnsServers: dns,
              ));

        case UspWanConnectionType.pppoe:
        case UspWanConnectionType.pptp:
        case UspWanConnectionType.l2tp:
          // AddressingType alone; LowerLayers and the credentials follow as one
          // PPP batch in _savePppLink (#762 comment 5987286082, SET 1 / SET 2).
          await _updateWanIpv4((path) => WanSettingsIpv4AddressUpdate(
              instancePath: path, addressingType: 'IPCP'));

        case UspWanConnectionType.bridge:
          // Nothing to write for the target mode: entering bridge is the single
          // Enable=false SET that saveAll sends last (Step 8).
          break;
      }
    } else {
      switch (edited.connectionType) {
        case UspWanConnectionType.ipoe:
          throw const InvalidInputError();
        case UspWanConnectionType.staticIp:
          final originalDns = _mergeDns(
              original.dnsServer1, original.dnsServer2, original.dnsServer3);
          final editedDns = _mergeDns(
              edited.dnsServer1, edited.dnsServer2, edited.dnsServer3);
          final ipAddress =
              _diff(original.staticIpAddress, edited.staticIpAddress);
          final subnetMask = _diff(original.subnetMask, edited.subnetMask);
          final defaultGateway =
              _diff(original.defaultGateway, edited.defaultGateway);
          final dnsServers = _diff(originalDns, editedDns);
          if (ipAddress != null ||
              subnetMask != null ||
              defaultGateway != null ||
              dnsServers != null) {
            await _updateWanIpv4((path) => WanSettingsIpv4AddressUpdate(
                  instancePath: path,
                  ipAddress: ipAddress,
                  subnetMask: subnetMask,
                  defaultGateway: defaultGateway,
                  dnsServers: dnsServers,
                ));
          }

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
    // Bridge is the exception: MTU has no meaning once the WAN port joins
    // br-lan, and the bridge SET is terminal (the transport drops mid-request),
    // so neither MaxMTUSize nor X_LINKSYS_MTUMode is sent for that target.
    if (edited.connectionType != UspWanConnectionType.bridge) {
      int? mtuArg;
      String? mtuModeArg;
      if (edited.mtuAuto) {
        // Only X_LINKSYS_MTUMode='Auto' clears the UCI mtu option. MaxMTUSize is
        // never sent in auto mode: 0 is outside the TR-181 range 64..65535 and
        // the firmware rejects it with fault 9007 (Architecture#122).
        if (!original.mtuAuto) mtuModeArg = 'Auto';
      } else {
        // Manual: writing MaxMTUSize is what puts UCI back into Manual, so
        // SET X_LINKSYS_MTUMode='Manual' is a firmware no-op and is never sent.
        // Force the write when leaving auto even if the number is unchanged —
        // _diff alone returns null there and the device would stay in Auto.
        mtuArg =
            original.mtuAuto ? edited.mtu : _diff(original.mtu, edited.mtu);
      }
      if (mtuArg != null || mtuModeArg != null) {
        _handleSetResult(
            await WanSettings.update(_usp, mtu: mtuArg, mtuMode: mtuModeArg));
      }
    }
  }

  /// Writes the WAN `IPv4Address` row through its own instance path, with
  /// AddressingType ahead of the address fields (one ordered SET).
  ///
  /// The row is created by the firmware and never added, so it is read here
  /// rather than assumed. A WAN with no row (bridge mode, #1597) has nothing to
  /// write, which is reported as such instead of faulting 9005 on a fixed
  /// `IPv4Address.1` path.
  Future<void> _updateWanIpv4(
    WanSettingsIpv4AddressUpdate Function(String instancePath) build,
  ) async {
    final row = (await WanSettings.fetch(_usp)).ipv4Addresses.firstOrNull;
    if (row == null) {
      throw const ResourceNotFoundError(
          detail: 'WAN IPv4Address row is absent; nothing to write');
    }
    _handleSetResult(await WanSettings.updateOrderedIpv4Addresses(
        _usp, [build(row.instancePath)]));
  }

  // ---------------------------------------------------------------------------
  // Bridge mode boundary — terminal, fire-and-forget by design
  // ---------------------------------------------------------------------------

  /// Enters bridge mode: `Device.IP.Interface.{wan}.Enable = false`.
  ///
  /// That one parameter is what actually bridges the WAN. Its firmware set
  /// handler adds the WAN device to `br-lan`'s `ports`, commits network+dhcp and
  /// runs `bridge-mode-apply.sh enter`. Writing `AddressingType=""` — what this
  /// used to send — does none of that: on this firmware that set handler only
  /// writes a uci option and never invokes the script, so the router was left
  /// with a dead WAN rather than a bridge.
  ///
  /// Then waits [_bridgeSettleDelay] for the router to come up at
  /// `<hostName>.local`. A rejected SET throws before the wait.
  Future<void> _enterBridgeMode() async {
    await _setBridgeBoundary(enable: false);
    await Future<void>.delayed(_bridgeSettleDelay);
  }

  /// Leaves bridge mode: `Device.IP.Interface.{wan}.Enable = true`.
  ///
  /// Sent alone: `bridge-mode-apply.sh exit` ends with `ifup wan`, and only
  /// then does the WAN `IPv4Address` row exist again to take a target mode.
  Future<void> _exitBridgeMode() => _setBridgeBoundary(enable: true);

  /// Sends the terminal bridge-boundary SET, treating the disconnect it causes
  /// as success.
  ///
  /// This SET is terminal-by-design (see [_bridgeSetTimeout]): the firmware
  /// applies the change and drops the connection carrying the response, so a
  /// transport-level timeout/network error on THIS SET is the expected
  /// signature of success — the SET was received and applied on-device before
  /// the disconnect. Those two cases are swallowed.
  ///
  /// Any error the router actively returns BEFORE the disconnect — a fault code
  /// mapped to a validation / resource / partial / auth / unexpected
  /// [ServiceError] — means the SET was rejected. Those propagate so the user
  /// still sees the failure; a real config failure is never hidden.
  Future<void> _setBridgeBoundary({required bool enable}) async {
    // enable=false enters bridge, enable=true leaves it.
    final direction = enable ? 'exit' : 'enter';
    try {
      _handleSetResult(
        await WanSettings.update(_usp, enable: enable)
            .timeout(_bridgeSetTimeout),
      );
    } on TimeoutException {
      // No response within the budget: the firmware applied the change and
      // dropped the connection, so the SET_RESP can never arrive. Expected
      // success. (Future.timeout keeps an error listener on the underlying
      // request, so its eventual late error is consumed, not left unhandled.)
      logger.i(
          '[USP][WAN]: bridge $direction SET timed out after ${_bridgeSetTimeout.inSeconds}s '
          '— treating as success (firmware dropped the connection applying it)');
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
        logger.i('[USP][WAN]: bridge $direction SET hit a transport error '
            '— treating as success (firmware dropped the connection applying it)');
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
    String instancePath,
  ) async {
    _handleSetResult(await PppInterface.update(
      _usp,
      [
        PppInterfaceInstanceUpdate(
          instancePath: instancePath,
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
  // PPP link — LowerLayers (tunnel type) and credentials
  // ---------------------------------------------------------------------------

  /// Writes `LowerLayers` and the credentials as one PPP batch.
  ///
  /// On a switch into or between PPP modes all three are sent, so the firmware
  /// gets the whole link in the SET that follows `AddressingType=IPCP` (#762
  /// comment 5987286082, SET 2). Otherwise only changed credentials are sent.
  Future<void> _savePppLink(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath,
  ) async {
    final typeChanged = original.connectionType != edited.connectionType;
    final lowerLayers =
        typeChanged ? edited.connectionType.pppLowerLayers : null;
    if (lowerLayers != null) {
      logger.d('[USP][WAN]: Setting LowerLayers to "$lowerLayers"');
    }
    _handleSetResult(await PppInterface.update(
      _usp,
      [
        PppInterfaceInstanceUpdate(
          instancePath: instancePath,
          lowerLayers: lowerLayers,
          username: typeChanged
              ? edited.pppUsername
              : _diff(original.pppUsername, edited.pppUsername),
          password: typeChanged
              ? edited.pppPassword
              : _diff(original.pppPassword, edited.pppPassword),
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
        _handleSetResult(await GreTunnels.update(_usp, [
          GreTunnelUpdate(
              instancePath: _greTunnelPath, remoteEndpoints: serverDiff),
        ]));
      case UspWanConnectionType.l2tp:
        logger.d('[USP][WAN]: Setting L2TP RemoteEndpoints to $serverDiff');
        _handleSetResult(await L2tpTunnels.update(_usp, [
          L2tpTunnelUpdate(
              instancePath: _l2tpTunnelPath, remoteEndpoints: serverDiff),
        ]));
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
    final ipv6Enabled = _diff(original.ipv6Enabled, edited.ipv6Enabled);
    final dhcpv6Enabled = _diff(original.dhcpv6Enabled, edited.dhcpv6Enabled);
    final ipv6rd = Ipv6rdSettingUpdate(
      instancePath: _ipv6rdPath,
      enabled: _diff(original.ipv6rdEnabled, edited.ipv6rdEnabled),
      prefix: _diff(original.ipv6rdPrefix, edited.ipv6rdPrefix),
      ipv4MaskLength:
          _diff(original.ipv6rdIpv4MaskLength, edited.ipv6rdIpv4MaskLength),
      borderRelay: _diff(original.ipv6rdBorderRelay, edited.ipv6rdBorderRelay),
    );
    if (ipv6Enabled == null &&
        dhcpv6Enabled == null &&
        Ipv6rdSettings.updateParams([ipv6rd]).isEmpty) {
      return;
    }

    // The WAN interface path both IPv6Enable and the DHCPv6 client match on.
    final wanPath = (await Ipv6Settings.fetch(_usp)).instancePath;
    Dhcpv6Client? client;
    if (dhcpv6Enabled != null) {
      client = _wanDhcpv6Client(await Dhcpv6Clients.fetch(_usp), wanPath);
    }

    // IPv6 settings span three USP services (IP.Interface, DHCPv6.Client,
    // IPv6rd.InterfaceSetting). They go out as one SET built from each
    // model's write builder; the OBUSPA broker rejects an atomic SET
    // (allow_partial=false) that touches more than one service with 7005
    // "Allow partial=false not supported across more than one USP Service",
    // so it allows partial application. _handleSetResult still surfaces any
    // per-parameter failure as a UspPartialFailureError.
    final params = {
      ...Ipv6Settings.updateParams(wanPath, ipv6Enabled: ipv6Enabled),
      if (client != null)
        ...Dhcpv6Clients.updateParams([
          Dhcpv6ClientUpdate(
              instancePath: client.instancePath, enable: dhcpv6Enabled),
        ]),
      ...Ipv6rdSettings.updateParams([ipv6rd]),
    };
    if (params.isEmpty) return;
    _handleSetResult(await _usp.set(params, allowPartial: true));
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

  /// Whether the device exposes `X_LINKSYS_MTUMode`. False on firmware
  /// predating feed_bbf#128, where MTU is manual-only.
  final bool mtuModeSupported;

  /// Debug fields for logging — not exposed to UI.
  final String debugAddressingType;
  final bool debugInterfaceEnabled;
  final int debugMtu;
  final bool debugIpv6Enabled;

  const InternetSettingsFetchResult({
    required this.form,
    required this.readOnlyInfo,
    this.pppInstancePath,
    this.vlanInstancePath,
    this.mtuModeSupported = false,
    this.debugAddressingType = '',
    this.debugInterfaceEnabled = true,
    this.debugMtu = 0,
    this.debugIpv6Enabled = false,
  });
}
