import 'dart:async';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/generated/dhcpv4clients.g.dart';
import 'package:privacy_gui/generated/dhcpv6clients.g.dart';
import 'package:privacy_gui/generated/gre_tunnels.g.dart';
import 'package:privacy_gui/generated/ipv6rd_settings.g.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/l2tp_tunnels.g.dart';
import 'package:privacy_gui/generated/ppp_interface.g.dart';
import 'package:privacy_gui/generated/vlan_termination.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
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

  /// 1.0's KeepAlive: missed echo replies before the link is dropped.
  static const _keepAliveEchoRetry = 5;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch WAN, IPv6, PPP, and VLAN settings in parallel, then the tunnel that
  /// the resolved connection type actually uses.
  ///
  /// Tables are read as lists, so a row the current WAN state does not have is
  /// an empty list rather than a failed fetch (#1597): no tunnel row on a
  /// non-PPTP/L2TP WAN, and on FW 2.0.2 no WAN `IPv4Address` row in bridge mode.
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

      final pppInstance = _wanPppRow(ppp.items, wan.lowerLayers);
      // No leaf ties the WAN to its VLAN row yet (no VLAN row on
      // 2.0.3.26102008 to read the chain from), so the only row, never a guess.
      final vlanInstance = vlan.items.length == 1 ? vlan.items.single : null;
      final ipv4 = wan.ipv4Addresses.firstOrNull;
      final addressingType = ipv4?.addressingType ?? '';

      // Phase 2 — tunnel is connection-type-specific. Only fetch the tunnel
      // the current connection type actually uses.
      final connectionType = UspWanConnectionType.fromRawFields(
        addressingType: addressingType,
        interfaceEnabled: wan.enable,
        lowerLayers: pppInstance?.lowerLayers ?? '',
      );
      final tunnel = await _fetchTunnel(connectionType);

      return InternetSettingsFetchResult(
        form: _buildForm(
          wan: wan,
          ipv4: ipv4,
          ipv6: ipv6,
          dhcpv6: _wanDhcpv6Client(dhcpv6, wan.instancePath),
          ipv6rd: _wanIpv6rdRow(ipv6rd),
          ppp: pppInstance,
          vlan: vlanInstance,
          tunnel: tunnel.row,
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

  /// The 6rd row the WAN uses: the first the table lists, or null when it
  /// lists none.
  ///
  /// No leaf names the WAN's row: with 6rd on, `TunneledInterface` stays empty
  /// on every row (bench 2.0.3.26102008), so the first row is taken, which is
  /// the row the firmware maps to its `wan6rd` section there.
  static Ipv6rdSetting? _wanIpv6rdRow(Ipv6rdSettings table) =>
      table.items.firstOrNull;

  /// The PPP row the WAN runs on.
  ///
  /// On PPPoE, PPTP and L2TP the WAN's `LowerLayers` names it (TR-181 stacks
  /// `IP.Interface` on `PPP.Interface`; bench 2.0.3.26102008:
  /// `Device.PPP.Interface.1`). On DHCP and Static it names the Ethernet link
  /// and no PPP row, so the only row is the one a switch to PPP writes. Null
  /// when the table is empty, or has several rows the WAN names none of.
  static PppInterfaceInstance? _wanPppRow(
      List<PppInterfaceInstance> rows, String wanLowerLayers) {
    final named = ensureTrailingDot(wanLowerLayers);
    for (final row in rows) {
      if (row.instancePath == named) return row;
    }
    return rows.length == 1 ? rows.single : null;
  }

  /// The rows of the tunnel table [type] runs over: `GRE.Tunnel` for PPTP,
  /// `L2TPv2.Tunnel` for L2TP, nothing for any other type.
  ///
  /// The firmware creates one row of each (linksys/PrivacyGUI#762 comment
  /// 5987286082, bench 2026-10-27), and no leaf names the WAN's, so the WAN's
  /// tunnel is the only row: [_TunnelTable.row] is null when the table has none
  /// or several.
  Future<_TunnelTable> _fetchTunnel(UspWanConnectionType type) async =>
      switch (type) {
        UspWanConnectionType.pptp => _TunnelTable(type, [
            for (final r in (await GreTunnels.fetch(_usp)).items)
              _TunnelRow.gre(r),
          ]),
        UspWanConnectionType.l2tp => _TunnelTable(type, [
            for (final r in (await L2tpTunnels.fetch(_usp)).items)
              _TunnelRow.l2tp(r),
          ]),
        _ => _TunnelTable(type, const []),
      };

  /// The DHCPv6 client bound to the WAN interface.
  static Dhcpv6Client? _wanDhcpv6Client(
          Dhcpv6Clients clients, String wanPath) =>
      _wanDhcpClientOf(clients.items, wanPath, (c) => c.interface_);

  /// The row of [clients] whose `Interface` is [wanPath], or null when none is.
  ///
  /// `Device.DHCPv{4,6}.Client.{i}.Interface` names the IP.Interface the client
  /// runs on, with or without the trailing dot.
  static T? _wanDhcpClientOf<T>(
    Iterable<T> clients,
    String wanPath,
    String Function(T client) interfaceOf,
  ) {
    final wan = ensureTrailingDot(wanPath);
    for (final client in clients) {
      if (ensureTrailingDot(interfaceOf(client)) == wan) return client;
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

  /// [ipv4], [dhcpv6], [ipv6rd] and [tunnel] are rows of tables that may be
  /// empty: no WAN `IPv4Address` row (bridge mode on FW 2.0.2), no DHCPv6
  /// client bound to the WAN, no tunnel row. An absent row reads as that row's
  /// defaults.
  UspInternetSettingsForm _buildForm({
    required WanSettings wan,
    required WanSettingsIpv4Address? ipv4,
    required Ipv6Settings ipv6,
    required Dhcpv6Client? dhcpv6,
    required Ipv6rdSetting? ipv6rd,
    required PppInterfaceInstance? ppp,
    required VlanTerminationInstance? vlan,
    required _TunnelRow? tunnel,
    required UspWanConnectionType connectionType,
  }) {
    // Split comma-separated DNS into 3 fields
    final dnsParts = _splitDns(ipv4?.dnsServers ?? '');

    // Server address from the tunnel fetchSettings' phase 2 loaded for this
    // connection type. A PPTP/L2TP WAN with no single tunnel row reads as an
    // empty server address, which fails form validation and prompts the user
    // to re-enter it. The underlay is read on PPTP only, the one type the page
    // offers it on.
    final underlay = connectionType == UspWanConnectionType.pptp &&
            tunnel?.underlayAddressingType == 'Static'
        ? tunnel
        : null;
    final underlayDns = _splitDns(underlay?.underlayDnsServers ?? '');

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
      // TR-181 holds seconds; the form holds minutes, as 1.0. Rounded up, so
      // an On Demand WAN under a minute never reads as 0.
      idleDisconnectTime: ((ppp?.idleDisconnectTime ?? 0) + 59) ~/ 60,
      lcpEchoInterval: _keepAliveInterval(ppp),
      serverAddress: tunnel?.remoteEndpoints ?? '',
      underlayStatic: underlay != null,
      underlayIpAddress: underlay?.underlayIpAddress ?? '',
      underlaySubnetMask: underlay?.underlaySubnetMask ?? '',
      underlayGateway: underlay?.underlayDefaultGateway ?? '',
      underlayDns1: underlayDns.elementAtOrNull(0) ?? '',
      underlayDns2: underlayDns.elementAtOrNull(1) ?? '',
      underlayDns3: underlayDns.elementAtOrNull(2) ?? '',
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

  /// The Keep Alive interval (`LCPEcho`) to show: a value outside 20–180 s
  /// reads as 30, 1.0's default (FWDEV#212).
  static int _keepAliveInterval(PppInterfaceInstance? ppp) {
    final value = ppp?.lcpEcho ?? 0;
    return value >= kPppKeepAliveSecondsMin && value <= kPppKeepAliveSecondsMax
        ? value
        : kPppKeepAliveDefaultSeconds;
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
  /// 4. Set tunnel RemoteEndpoints (server address) and the PPTP static
  ///    underlay, on the only tunnel row, read before step 1
  /// 5. Save PPP instance fields (connection mode)
  /// 6. Save VLAN instance fields (if instance exists)
  /// 7. Save IPv6 fields
  /// 8. Cross the bridge boundary last (drops the connection; see
  ///    [_enterBridgeMode] / [_exitBridgeMode]) so every other SET lands on a
  ///    live connection
  ///
  /// Leaving bridge writes the target mode like any other switch, before the
  /// `Enable=true` that leaves. The WAN `IPv4Address` row stays while bridged
  /// (FW 2.0.3), and `bridge-mode-apply.sh exit` never touches `network.wan`,
  /// so the WAN comes back in whatever mode it holds when Enable flips; sent
  /// alone, it came back in the mode it had before entering bridge.
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

      // Step 0: read the tunnel row a PPTP / L2TP save writes, so a WAN with
      // no single row, or a static underlay the firmware cannot take, is
      // refused before anything is sent.
      final tunnel = await _tunnelToWrite(edited);

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
        await _savePppLink(original, edited, pppPath, tunnel: tunnel);
      }

      // Step 4: tunnel RemoteEndpoints (server address) and static underlay
      if (tunnel != null) await _saveTunnel(original, edited, tunnel);

      // Step 5: PPP instance fields
      if (pppPath != null && edited.connectionType.isPppBased) {
        await _savePppSettings(original, edited, pppPath);
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
    } on UspCompleteFailureError catch (e) {
      throw _refusalOf(e.failures) ?? e;
    } on UspPartialFailureError catch (e) {
      throw _refusalOf(e.failures) ?? e;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// A save refused before anything is sent, because a table the router lists
  /// has no row to write to — or several, where no leaf names the WAN's.
  ///
  /// Logged here, since a [ServiceError] prints only its type: a field log
  /// would otherwise read "Resource not found" for every one of them.
  static ResourceNotFoundError _refuse(String why) {
    logger.w('[USP][WAN]: $why — nothing sent');
    return ResourceNotFoundError(detail: why);
  }

  /// A refusal that carries one of netmngr's WAN messages, as an
  /// [InvalidInputError] whose `field` is that message, so the page can say
  /// which check the firmware applied. Null for any other failure.
  static InvalidInputError? _refusalOf(List<UspErrorDetail> failures) {
    final refusal = refusalNameIn(failures, WanRefusalNames.all);
    if (refusal == null) return null;
    return InvalidInputError(
      field: refusal.name,
      code: refusal.detail.errorCode,
      detail: refusal.detail.errorMessage,
    );
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
  /// rather than assumed. A WAN with no row (bridge mode on FW 2.0.2, #1597) has
  /// nothing to write, which is reported as such instead of faulting 9005 on a
  /// fixed `IPv4Address.1` path.
  Future<void> _updateWanIpv4(
    WanSettingsIpv4AddressUpdate Function(String instancePath) build,
  ) async {
    final wan = await WanSettings.fetch(_usp);
    final row = wan.ipv4Addresses.firstOrNull;
    if (row == null) {
      throw _refuse('${wan.instancePath}IPv4Address has no row');
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
  Future<void> _enterBridgeMode() => _setBridgeBoundary(enable: false);

  /// Leaves bridge mode: `Device.IP.Interface.{wan}.Enable = true`.
  ///
  /// Sent after the target mode's own SETs: `bridge-mode-apply.sh exit` ends
  /// with `ifup wan`, which brings the WAN up in the mode `network.wan` holds.
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

  /// Writes the connection mode: the trigger, and the idle time (On Demand) or
  /// the Keep Alive interval (Keep Alive).
  ///
  /// The idle time is held in minutes and sent in seconds. It is never sent
  /// with Keep Alive: the firmware derives `ConnectionTrigger` from it, so a
  /// later `IdleDisconnectTime` in the same save turns On Demand back on
  /// (linksys/feed_usp#55 netmngr 050).
  ///
  /// Every Keep Alive save sends 1.0's KeepAlive as one Set: `LCPEcho` the
  /// interval, `LCPEchoRetry` 5, `LCPEchoAdaptive` false (linksys/feed_usp#68;
  /// "sent on every KeepAlive save", FWDEV#212). A router holding an
  /// out-of-range `LCPEcho` reads as 30, and only this write makes it so.
  /// Writing `LCPEcho` no longer turns adaptive echo off by itself.
  Future<void> _savePppSettings(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath,
  ) async {
    final onDemand = edited.connectionTrigger == 'OnDemand';
    final idleMinutes = onDemand
        ? _diff(original.idleDisconnectTime, edited.idleDisconnectTime) ??
            (original.connectionTrigger != edited.connectionTrigger
                ? edited.idleDisconnectTime
                : null)
        : null;
    final update = PppInterfaceInstanceUpdate(
      instancePath: instancePath,
      pppoeServiceName:
          _diff(original.pppoeServiceName, edited.pppoeServiceName),
      connectionTrigger:
          _diff(original.connectionTrigger, edited.connectionTrigger),
      idleDisconnectTime: idleMinutes == null ? null : idleMinutes * 60,
    );
    _handleSetResult(await PppInterface.update(
      _usp,
      [
        !onDemand
            ? PppInterfaceInstanceUpdate(
                instancePath: instancePath,
                pppoeServiceName: update.pppoeServiceName,
                connectionTrigger: update.connectionTrigger,
                lcpEcho: edited.lcpEchoInterval,
                lcpEchoRetry: _keepAliveEchoRetry,
                lcpEchoAdaptive: false,
              )
            : update,
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
  ///
  /// `LowerLayers` is empty for PPPoE, which is what selects plain PPPoE on
  /// this firmware (#762 comment 5987286082), and [tunnel]'s interface, without
  /// the trailing dot, for PPTP / L2TP.
  Future<void> _savePppLink(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    String instancePath, {
    required _TunnelRow? tunnel,
  }) async {
    final typeChanged = original.connectionType != edited.connectionType;
    final lowerLayers = !typeChanged
        ? null
        : edited.connectionType.isTunnel
            ? withoutTrailingDot(tunnel!.interfacePath!)
            : '';
    if (lowerLayers != null) {
      logger.d('[USP][WAN]: Setting LowerLayers to "$lowerLayers"');
    }
    final update = PppInterfaceInstanceUpdate(
      instancePath: instancePath,
      lowerLayers: lowerLayers,
      username: typeChanged
          ? edited.pppUsername
          : _diff(original.pppUsername, edited.pppUsername),
      password: typeChanged
          ? edited.pppPassword
          : _diff(original.pppPassword, edited.pppPassword),
    );
    _handleSetResult(await PppInterface.update(_usp, [update]));
  }

  // ---------------------------------------------------------------------------
  // Tunnel row — server address and static underlay for PPTP/L2TP
  // ---------------------------------------------------------------------------

  /// The tunnel row [edited] writes, read before anything is sent.
  ///
  /// Null when [edited] is not PPTP / L2TP. Throws [ResourceNotFoundError] when
  /// the table has no row or several (no leaf names the WAN's), or when the
  /// row has no interface for PPP to run on.
  Future<_TunnelRow?> _tunnelToWrite(UspInternetSettingsForm edited) async {
    final read = await _fetchTunnel(edited.connectionType);
    if (!read.type.isTunnel) return null;
    final row = read.row;
    if (row == null) {
      throw _refuse('${read.type.name} needs exactly one ${read.table} row, '
          'found ${read.rows.length}');
    }
    if (row.interfacePath == null) {
      throw _refuse('${row.instancePath}Interface has no row');
    }
    return row;
  }

  /// Writes the server address and the underlay on [row] with `updateOrdered`.
  ///
  /// Each value is compared with what [row] holds, not with [original]: on a
  /// type switch the original form describes the other tunnel. The underlay
  /// type goes in the first group, with the server, so the firmware checks the
  /// fields that follow against it (linksys/feed_usp#55 netmngr 039); a switch
  /// to Static sends every field, otherwise only the fields edited.
  ///
  /// The groups are sent in order and partially: the generated `updateOrdered`
  /// passes `allowPartial: true`. So a refused IP or mask leaves the server and
  /// the type written. The page checks every field the firmware refuses before
  /// it saves, which is what keeps that from happening.
  ///
  /// The page offers the underlay on PPTP only, as 1.0. The firmware keeps the
  /// GRE and L2TPv2 underlay in the same WAN section, so an L2TP save sets the
  /// row back to DHCP rather than leave a PPTP static underlay under it.
  Future<void> _saveTunnel(
    UspInternetSettingsForm original,
    UspInternetSettingsForm edited,
    _TunnelRow row,
  ) async {
    final wantStatic = edited.connectionType == UspWanConnectionType.pptp &&
        edited.underlayStatic;
    final underlayType =
        _diff(row.underlayAddressingType, wantStatic ? 'Static' : 'DHCP');
    final toStatic = wantStatic && underlayType != null;
    String? field(String originalValue, String editedValue) => !wantStatic
        ? null
        : toStatic
            ? editedValue
            : _diff(originalValue, editedValue);
    final update = (
      remoteEndpoints: _diff(row.remoteEndpoints, edited.serverAddress),
      underlayAddressingType: underlayType,
      underlayIpAddress:
          field(original.underlayIpAddress, edited.underlayIpAddress),
      underlaySubnetMask:
          field(original.underlaySubnetMask, edited.underlaySubnetMask),
      underlayDefaultGateway:
          field(original.underlayGateway, edited.underlayGateway),
      underlayDnsServers: field(
          _mergeDns(original.underlayDns1, original.underlayDns2,
              original.underlayDns3),
          _mergeDns(
              edited.underlayDns1, edited.underlayDns2, edited.underlayDns3)),
    );
    // Nothing to write is not sent: updateOrdered() with no groups returns a
    // result the parser cannot read (an untyped `data` map).
    final Future<Map<String, dynamic>> Function()? send;
    switch (row.type) {
      case UspWanConnectionType.pptp:
        final gre = GreTunnelUpdate(
          instancePath: row.instancePath,
          remoteEndpoints: update.remoteEndpoints,
          underlayAddressingType: update.underlayAddressingType,
          underlayIpAddress: update.underlayIpAddress,
          underlaySubnetMask: update.underlaySubnetMask,
          underlayDefaultGateway: update.underlayDefaultGateway,
          underlayDnsServers: update.underlayDnsServers,
        );
        send = GreTunnels.updateOrderedGroups([gre]).isEmpty
            ? null
            : () => GreTunnels.updateOrdered(_usp, [gre]);
      case UspWanConnectionType.l2tp:
        final l2tp = L2tpTunnelUpdate(
          instancePath: row.instancePath,
          remoteEndpoints: update.remoteEndpoints,
          underlayAddressingType: update.underlayAddressingType,
        );
        send = L2tpTunnels.updateOrderedGroups([l2tp]).isEmpty
            ? null
            : () => L2tpTunnels.updateOrdered(_usp, [l2tp]);
      default:
        throw StateError('${row.type.name} has no tunnel row');
    }
    if (send == null) return;
    logger.d('[USP][WAN]: Writing tunnel ${row.instancePath}: $update');
    _handleSetResult(await send());
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
    final ipv6rdEnabled = _diff(original.ipv6rdEnabled, edited.ipv6rdEnabled);
    final ipv6rdPrefix = _diff(original.ipv6rdPrefix, edited.ipv6rdPrefix);
    final ipv6rdMaskLength =
        _diff(original.ipv6rdIpv4MaskLength, edited.ipv6rdIpv4MaskLength);
    final ipv6rdBorderRelay =
        _diff(original.ipv6rdBorderRelay, edited.ipv6rdBorderRelay);
    final ipv6rdChanged = ipv6rdEnabled != null ||
        ipv6rdPrefix != null ||
        ipv6rdMaskLength != null ||
        ipv6rdBorderRelay != null;
    if (ipv6Enabled == null && dhcpv6Enabled == null && !ipv6rdChanged) {
      return;
    }

    // The WAN interface path both IPv6Enable and the DHCPv6 client match on.
    final wanPath = (await Ipv6Settings.fetch(_usp)).instancePath;
    Dhcpv6Client? client;
    if (dhcpv6Enabled != null) {
      client = _wanDhcpv6Client(await Dhcpv6Clients.fetch(_usp), wanPath);
      // Refused before anything is sent, so a DHCPv6 change with no client
      // to write it to is never reported as saved.
      if (client == null) {
        throw const ResourceNotFoundError(
            detail: 'No DHCPv6 client is bound to the WAN interface');
      }
    }
    // The same for a 6rd change with no 6rd row to write it to.
    Ipv6rdSettingUpdate? ipv6rd;
    if (ipv6rdChanged) {
      final row = _wanIpv6rdRow(await Ipv6rdSettings.fetch(_usp));
      if (row == null) {
        throw _refuse('Device.IPv6rd.InterfaceSetting has no row');
      }
      ipv6rd = Ipv6rdSettingUpdate(
        instancePath: row.instancePath,
        enabled: ipv6rdEnabled,
        prefix: ipv6rdPrefix,
        ipv4MaskLength: ipv6rdMaskLength,
        borderRelay: ipv6rdBorderRelay,
      );
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
      if (ipv6rd != null) ...Ipv6rdSettings.updateParams([ipv6rd]),
    };
    if (params.isEmpty) return;
    _handleSetResult(await _usp.set(params, allowPartial: true));
  }

  // ---------------------------------------------------------------------------
  // DHCP Renewal
  // ---------------------------------------------------------------------------

  /// Renews the DHCPv4 lease of the client bound to the WAN interface.
  ///
  /// Throws [ResourceNotFoundError] when no client is bound to the WAN, so a
  /// renew never lands on a guessed `Client.1`.
  Future<void> renewDhcpLease() async {
    try {
      final results = await Future.wait([
        WanStatus.fetch(_usp),
        Dhcpv4Clients.fetch(_usp),
      ]);
      final client = _wanDhcpClientOf((results[1] as Dhcpv4Clients).items,
          (results[0] as WanStatus).instancePath, (c) => c.interface_);
      await WanOperations.renewDhcpLease(
          _usp, _clientInstance(client?.instancePath, 'DHCPv4'));
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Renews the DHCPv6 lease of the client bound to the WAN interface.
  /// Throws like [renewDhcpLease].
  Future<void> renewDhcpv6Lease() async {
    try {
      final results = await Future.wait([
        WanStatus.fetch(_usp),
        Dhcpv6Clients.fetch(_usp),
      ]);
      final client = _wanDhcpv6Client(
          results[1] as Dhcpv6Clients, (results[0] as WanStatus).instancePath);
      await WanOperations.renewDhcpv6Lease(
          _usp, _clientInstance(client?.instancePath, 'DHCPv6'));
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The instance number in a DHCP client's [instancePath].
  static int _clientInstance(String? instancePath, String protocol) {
    final match = instancePath == null
        ? null
        : RegExp(r'\.(\d+)\.$').firstMatch(instancePath);
    if (match == null) {
      throw ResourceNotFoundError(
          detail: 'No $protocol client is bound to the WAN interface');
    }
    return int.parse(match.group(1)!);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Split a comma-separated DNS list into its non-empty entries.
  static List<String> _splitDns(String dns) =>
      dns.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

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

/// A PPTP (`Device.GRE.Tunnel.{i}`) or L2TP (`Device.L2TPv2.Tunnel.{i}`) row.
/// The two generated rows carry the same leaves; [type] says which it is.
class _TunnelRow {
  final UspWanConnectionType type;
  final String instancePath;
  final String remoteEndpoints;
  final String? underlayAddressingType;
  final String? underlayIpAddress;
  final String? underlaySubnetMask;
  final String? underlayDefaultGateway;
  final String? underlayDnsServers;

  /// The tunnel's interface row, the layer PPP runs on; null when it has none.
  final String? interfacePath;

  _TunnelRow.gre(GreTunnel r)
      : type = UspWanConnectionType.pptp,
        instancePath = r.instancePath,
        interfacePath = r.tunnelInterface?.instancePath,
        remoteEndpoints = r.remoteEndpoints,
        underlayAddressingType = r.underlayAddressingType,
        underlayIpAddress = r.underlayIpAddress,
        underlaySubnetMask = r.underlaySubnetMask,
        underlayDefaultGateway = r.underlayDefaultGateway,
        underlayDnsServers = r.underlayDnsServers;

  _TunnelRow.l2tp(L2tpTunnel r)
      : type = UspWanConnectionType.l2tp,
        instancePath = r.instancePath,
        interfacePath = r.tunnelInterface?.instancePath,
        remoteEndpoints = r.remoteEndpoints,
        underlayAddressingType = r.underlayAddressingType,
        underlayIpAddress = r.underlayIpAddress,
        underlaySubnetMask = r.underlaySubnetMask,
        underlayDefaultGateway = r.underlayDefaultGateway,
        underlayDnsServers = r.underlayDnsServers;
}

/// The tunnel table a connection type runs over, read as every row.
class _TunnelTable {
  final UspWanConnectionType type;
  final List<_TunnelRow> rows;

  const _TunnelTable(this.type, this.rows);

  /// The WAN's tunnel: the only row, or null when there is none or several.
  _TunnelRow? get row => rows.length == 1 ? rows.single : null;

  /// The TR-181 table [type] runs over.
  String get table => switch (type) {
        UspWanConnectionType.pptp => 'Device.GRE.Tunnel',
        UspWanConnectionType.l2tp => 'Device.L2TPv2.Tunnel',
        _ => 'no tunnel',
      };
}
