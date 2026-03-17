import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/subscriptions.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/services/usp_device_service.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/sse_providers.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

/// USP Dashboard provider — AsyncNotifier for read + write operations.
///
/// NOT autoDispose — data persists across tab switches (Home/Menu/Support).
/// Pull-to-refresh and explicit invalidate still work for manual refresh.
final uspDashboardProvider =
    AsyncNotifierProvider<UspDashboardNotifier, UspDashboardState>(
  UspDashboardNotifier.new,
);

/// Tracks which card is currently being mutated (for loading overlay).
/// Values: null (idle), 'wifi', 'time', 'dhcp', 'portForwarding', 'portTriggering'
final uspMutationLoadingProvider = StateProvider<String?>((ref) => null);

/// Loading progress for the USP Dashboard initial fetch.
class UspLoadingProgress {
  final int completed;
  final int total;
  final String currentTask;

  const UspLoadingProgress({
    this.completed = 0,
    this.total = 17,
    this.currentTask = '',
  });

  double get fraction => total > 0 ? completed / total : 0;
}

final uspLoadingProgressProvider = StateProvider<UspLoadingProgress>(
  (ref) => const UspLoadingProgress(),
);

class UspDashboardNotifier extends AsyncNotifier<UspDashboardState> {
  /// Sequential lock — prevents parallel USP calls (WASM bug)
  bool _mutating = false;

  /// SSE invalidation debounce — batches rapid SSE events (500ms).
  Timer? _invalidationDebounce;
  final Set<InvalidationDomain> _pendingDomains = {};

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspDeviceService get _svc => ref.read(uspDeviceServiceProvider);

  @override
  Future<UspDashboardState> build() async {
    try {
      return await _buildImpl();
    } catch (e, st) {
      logger.e('[USP Dashboard] build() failed: $e\n$st');
      rethrow;
    }
  }

  Future<UspDashboardState> _buildImpl() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) {
      throw StateError('USP service not available');
    }
    // On page reload WASM state is lost — attempt session restore before giving up
    bool authWasRestored = false;
    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw StateError('USP not authenticated after restore attempt');
      }
      authWasRestored = true;
    }
    // SSE invalidation: listen for domain-specific change signals.
    // When SSE delivers a notification (e.g., device connected, WiFi changed),
    // we selectively re-fetch only the affected data instead of all 17 classes.
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain != null) {
        _pendingDomains.add(domain);
        _invalidationDebounce?.cancel();
        _invalidationDebounce = Timer(const Duration(milliseconds: 500), () {
          final domains = Set<InvalidationDomain>.from(_pendingDomains);
          _pendingDomains.clear();
          _handleInvalidation(domains);
        });
      }
    });
    ref.onDispose(() {
      _invalidationDebounce?.cancel();
    });

    // Yield so Riverpod finishes provider initialization before we modify
    // another provider (uspLoadingProgressProvider). Without this, Riverpod
    // throws "Providers are not allowed to modify other providers during
    // their initialization".
    await Future<void>.value();

    final progressNotifier = ref.read(uspLoadingProgressProvider.notifier);
    progressNotifier.state = const UspLoadingProgress();

    void tick(String task) {
      final prev = progressNotifier.state;
      progressNotifier.state = UspLoadingProgress(
        completed: prev.completed + 1,
        total: prev.total,
        currentTask: task,
      );
    }

    // Batched fetch — 3 requests per batch to stay within the browser's
    // HTTP/1.1 connection pool limit (6 per host). With SSE occupying 1
    // persistent connection, 3 concurrent fetches use 4 total — safe margin.
    // Each fetch reports progress on completion for the loading indicator.
    final totalSw = Stopwatch()..start();

    Future<T> timed<T>(String label, Future<T> Function() fn) async {
      final sw = Stopwatch()..start();
      final result = await fn().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
            '$label timed out', const Duration(seconds: 30)),
      );
      sw.stop();
      logger.d('[USP][Dashboard]$label — ${sw.elapsedMilliseconds}ms');
      tick(label);
      return result;
    }

    // Batch 1: Core system info
    final b1 = await Future.wait([
      timed('System Info', () => SystemInfo.fetch(usp)),
      timed('Devices', () => ConnectedDevices.fetch(usp)),
      timed('WAN Status', () => WanStatus.fetch(usp)),
    ]);
    final systemInfo = b1[0] as SystemInfo;
    final connectedDevices = b1[1] as ConnectedDevices;
    final wanStatus = b1[2] as WanStatus;
    logger.d('[USP][Dashboard]Batch 1 done — ${totalSw.elapsedMilliseconds}ms');

    // Batch 2: Network + WiFi radios
    final b2 = await Future.wait([
      timed('LAN Info', () => LanNetworkInfo.fetch(usp)),
      timed('WiFi Radios', () => WiFiRadios.fetch(usp)),
      timed('WiFi SSIDs', () => WiFiSsids.fetch(usp)),
    ]);
    final lanNetworkInfo = b2[0] as LanNetworkInfo;
    final wifiRadios = b2[1] as WiFiRadios;
    final wifiSsids = b2[2] as WiFiSsids;
    logger.d('[USP][Dashboard]Batch 2 done — ${totalSw.elapsedMilliseconds}ms');

    // Batch 3: WiFi clients + access points
    final b3 = await Future.wait([
      timed('Access Points', () => WiFiAccessPoints.fetch(usp)),
      timed('WiFi Clients', () => fetchWifiClients(usp)),
      timed('Ethernet Ports', () => EthernetInterfaces.fetch(usp)),
    ]);
    final wifiAccessPoints = b3[0] as WiFiAccessPoints;
    final wifiClientMap = b3[1] as Map<String, WifiClient>;
    final ethernetInterfaces = b3[2] as EthernetInterfaces;
    logger.d('[USP][Dashboard]Batch 3 done — ${totalSw.elapsedMilliseconds}ms');

    // Batch 4: DHCP + time
    final b4 = await Future.wait([
      timed('DHCP Clients', () => DhcpClients.fetch(usp)),
      timed('DHCP Reservations', () => DhcpReservations.fetch(usp)),
      timed('Time Settings', () => TimeSettings.fetch(usp)),
    ]);
    final dhcpClients = b4[0] as DhcpClients;
    final dhcpReservations = b4[1] as DhcpReservations;
    final timeSettings = b4[2] as TimeSettings;
    logger.d('[USP][Dashboard]Batch 4 done — ${totalSw.elapsedMilliseconds}ms');

    // Batch 5: Mesh + port rules
    final b5 = await Future.wait([
      timed('Mesh Nodes', () => fetchMeshNodes(usp)),
      timed('Port Forwarding', () => PortForwarding.fetch(usp)),
      timed('Port Triggering', () => PortTriggering.fetch(usp)),
    ]);
    final meshTopology = b5[0] as MeshTopologyInfo;
    final portForwarding = b5[1] as PortForwarding;
    final portTriggering = b5[2] as PortTriggering;
    logger.d('[USP][Dashboard]Batch 5 done — ${totalSw.elapsedMilliseconds}ms');

    // Batch 6: Firewall
    final b6 = await Future.wait([
      timed('Firewall Rules', () => FirewallChainRules.fetch(usp)),
      timed('DMZ', () => Dmz.fetch(usp)),
    ]);
    final firewallRules = b6[0] as FirewallChainRules;
    final dmzEntries = b6[1] as Dmz;
    totalSw.stop();
    logger.d(
        '[USP][Dashboard]Batch 6 done — total ${totalSw.elapsedMilliseconds}ms');
    logger.d('[USP][Dashboard]Dashboard fetch complete — '
        'devices: ${connectedDevices.items.length}, '
        'ethIfaces: ${ethernetInterfaces.items.length}, '
        'wifiClients: ${wifiClientMap.length}, '
        'meshNodes: ${meshTopology.nodes.length}');

    // Cross-reference AP → SSID → Radio to get band + SSID name per client
    final connectionDetailMap = buildConnectionDetailMap(
      wifiClientMap: wifiClientMap,
      accessPoints: wifiAccessPoints,
      ssids: wifiSsids,
      radios: wifiRadios,
    );
    // Fetch default gateway + IPv6 info + firmware images + bridge ports in parallel
    final extraResults = await Future.wait([
      _fetchDefaultGateway(usp),
      _fetchIpv6Info(usp),
      _fetchFirmwareImages(usp),
      _fetchBridgePortMap(usp),
    ]).timeout(const Duration(seconds: 30));
    final wanGateway = extraResults[0] as String;
    final ipv6Info = extraResults[1] as ({
      bool lanEnabled,
      List<String> lanAddresses,
      bool wanEnabled,
      List<String> wanAddresses
    });
    final firmwareImageData = extraResults[2] as ({
      FirmwareImages images,
      String activeRef,
      String bootRef
    });
    final bridgePortMap = extraResults[3] as Map<String, String>;

    // All dashboard HTTP requests are done. OBUSPA pipeline is now free.
    //
    // No purge needed: bridge subscription API is idempotent by subscription_id.
    // Re-registering the same codegen'd IDs overwrites existing entries without
    // creating orphans. This saves 1+N serialized UDS requests per page load.
    //
    // SSE subscription setup
    if (authWasRestored) {
      // F5 reload: bootstrap connected SSE but deferred core subs.
      // Also need to set core subs if bootstrap skipped them.
      final manager = ref.read(sseManagerProvider);
      if (manager != null) {
        manager.setCoreSubscriptions(coreSubscriptions);
        if (!manager.isConnected) {
          await manager.connect();
        }
        await manager.registerDeferredSubscriptions(force: true);
        logger.d('[USP][Dashboard]Post-reload SSE setup complete');
      }
    } else {
      // Normal: SSE already connected via bootstrap, register deferred subs.
      ref.read(sseManagerProvider)?.registerDeferredSubscriptions();
    }

    // Data → UI Model transformation (constitution Section 5.3)
    final svc = _svc;
    final gatewayName =
        systemInfo.modelName.isNotEmpty ? systemInfo.modelName : 'Router';

    final deviceModels = svc.buildDeviceUIModels(
      connectedDevices: connectedDevices,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
    );

    final firmwareImageModels = svc.buildFirmwareImageUIModels(
      data: firmwareImageData.images,
      activeRef: firmwareImageData.activeRef,
      bootRef: firmwareImageData.bootRef,
    );
    final systemInfoModel = svc.buildSystemInfoUIModel(
      systemInfo,
      firmwareImages: firmwareImageModels,
    );

    // Push a snapshot to the system monitor (avoids duplicate fetch)
    final memPct = systemInfo.totalMemory > 0
        ? ((systemInfo.totalMemory - systemInfo.freeMemory) /
                systemInfo.totalMemory *
                100)
            .round()
            .clamp(0, 100)
        : 0;
    ref.read(uspSystemMonitorProvider.notifier).pushSnapshot(
          SystemSnapshot(
            timestamp: DateTime.now(),
            cpuPercent: systemInfo.cpuUsage.clamp(0, 100),
            memoryPercent: memPct,
            totalMemoryKb: systemInfo.totalMemory,
            freeMemoryKb: systemInfo.freeMemory,
          ),
        );

    return UspDashboardState(
      systemInfo: systemInfo,
      connectedDevices: connectedDevices,
      wifiRadios: wifiRadios,
      wifiSsids: wifiSsids,
      wifiAccessPoints: wifiAccessPoints,
      timeSettings: timeSettings,
      dhcpClients: dhcpClients,
      dhcpReservations: dhcpReservations,
      portForwarding: portForwarding,
      portTriggering: portTriggering,
      firewallRules: firewallRules,
      dmzEntries: dmzEntries,
      isAuthenticated: usp.isAuthenticated,
      wifiClientMap: wifiClientMap,
      meshTopology: meshTopology,
      connectionDetailMap: connectionDetailMap,
      lanNetworkInfo: lanNetworkInfo,
      ethernetInterfaces: ethernetInterfaces,
      wanStatus: wanStatus,
      ethernetPortModels: svc.buildEthernetPortUIModels(
        ethernetInterfaces: ethernetInterfaces,
        deviceModels: deviceModels,
        bridgePortMap: bridgePortMap,
      ),
      lanInfoModel: svc.buildLanInfoUIModel(
        lanNetworkInfo,
        ipv6Enabled: ipv6Info.lanEnabled,
        ipv6Addresses: ipv6Info.lanAddresses,
      ),
      systemInfoModel: systemInfoModel,
      deviceModels: deviceModels,
      wifiRadioModels: svc.buildWifiRadioUIModels(
        radios: wifiRadios,
        ssids: wifiSsids,
        accessPoints: wifiAccessPoints,
      ),
      timeSettingsModel: svc.buildTimeSettingsUIModel(timeSettings),
      dhcpClientModels: svc.buildDhcpClientUIModels(
        clients: dhcpClients,
        connectedDevices: connectedDevices,
      ),
      dhcpReservationModels: svc.buildDhcpReservationUIModels(dhcpReservations),
      portForwardingRuleModels:
          svc.buildPortForwardingRuleUIModels(portForwarding),
      portTriggeringRuleModels:
          svc.buildPortTriggeringRuleUIModels(portTriggering),
      wanStatusModel: svc.buildWanStatusUIModel(
        wanStatus: wanStatus,
        gateway: wanGateway,
        ipv6Enabled: ipv6Info.wanEnabled,
        ipv6Addresses: ipv6Info.wanAddresses,
      ),
      nodeModels: svc.buildNodeUIModels(
        meshTopology: meshTopology,
        deviceModels: deviceModels,
        systemInfo: systemInfoModel,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WAN default gateway extraction
  // ---------------------------------------------------------------------------

  /// Fetches the default gateway IP from the IPv4 routing table.
  ///
  /// Looks for the entry with DestIPAddress=0.0.0.0 whose Interface points to
  /// the WAN (Device.IP.Interface.2). Returns empty string on failure.
  Future<String> _fetchDefaultGateway(UspService usp) async {
    try {
      // Use wildcard search paths — instance IDs may not be contiguous
      final resp = await usp.get([
        'Device.Routing.Router.1.IPv4Forwarding.*.DestIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.GatewayIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.Interface',
      ]).timeout(const Duration(seconds: 10));

      // Extract instance IDs from response keys
      const basePath = 'Device.Routing.Router.1.IPv4Forwarding.';
      final ids = <String>{};
      for (final key in resp.keys) {
        if (key.startsWith(basePath)) {
          final rest = key.substring(basePath.length);
          final dot = rest.indexOf('.');
          if (dot > 0) ids.add(rest.substring(0, dot));
        }
      }

      // Find default route (DestIPAddress=0.0.0.0) pointing to WAN interface
      for (final id in ids) {
        final prefix = '$basePath$id.';
        final dest = resp['${prefix}DestIPAddress']?.toString() ?? '';
        final gw = resp['${prefix}GatewayIPAddress']?.toString() ?? '';
        final iface = resp['${prefix}Interface']?.toString() ?? '';
        if (dest == '0.0.0.0' && iface.contains('Interface.2')) {
          return gw;
        }
      }
      return '';
    } catch (e) {
      logger.w('[USP][Dashboard]Failed to fetch default gateway: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // IPv6 status fetch (F-008)
  // ---------------------------------------------------------------------------

  /// Fetches IPv6 enable flags and addresses for LAN (Interface.1) and
  /// WAN (Interface.2). Returns a record with both sides.
  /// Fails silently if the router doesn't support IPv6 queries.
  Future<
      ({
        bool lanEnabled,
        List<String> lanAddresses,
        bool wanEnabled,
        List<String> wanAddresses
      })> _fetchIpv6Info(UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.IP.Interface.1.IPv6Enable',
        'Device.IP.Interface.2.IPv6Enable',
        'Device.IP.Interface.1.IPv6Address.',
        'Device.IP.Interface.2.IPv6Address.',
      ]).timeout(const Duration(seconds: 10));

      final lanEnabled = resp['Device.IP.Interface.1.IPv6Enable'] == true;
      final wanEnabled = resp['Device.IP.Interface.2.IPv6Enable'] == true;

      final lanInstances =
          resp.getInstances('Device.IP.Interface.1.IPv6Address.');
      final wanInstances =
          resp.getInstances('Device.IP.Interface.2.IPv6Address.');

      final lanAddresses = lanInstances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();
      final wanAddresses = wanInstances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();

      logger.d('[USP][Dashboard]IPv6 LAN: enabled=$lanEnabled, '
          'addresses=${lanAddresses.length}');
      logger.d('[USP][Dashboard]IPv6 WAN: enabled=$wanEnabled, '
          'addresses=${wanAddresses.length}');

      return (
        lanEnabled: lanEnabled,
        lanAddresses: lanAddresses,
        wanEnabled: wanEnabled,
        wanAddresses: wanAddresses,
      );
    } catch (e) {
      logger.w(
          '[USP][Dashboard]IPv6 fetch failed (router may not support IPv6): $e');
      return (
        lanEnabled: false,
        lanAddresses: <String>[],
        wanEnabled: false,
        wanAddresses: <String>[],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Firmware Images fetch (F-013)
  // ---------------------------------------------------------------------------

  /// Fetches firmware image partitions and the active/boot reference paths.
  /// Returns empty data on failure (graceful fallback for unsupported routers).
  Future<({FirmwareImages images, String activeRef, String bootRef})>
      _fetchFirmwareImages(UspService usp) async {
    try {
      final results = await Future.wait([
        FirmwareImages.fetch(usp),
        usp.get([
          'Device.DeviceInfo.ActiveFirmwareImage',
          'Device.DeviceInfo.BootFirmwareImage',
        ]),
      ]).timeout(const Duration(seconds: 10));
      final images = results[0] as FirmwareImages;
      final refs = results[1] as Map<String, dynamic>;
      final activeRef =
          refs['Device.DeviceInfo.ActiveFirmwareImage']?.toString() ?? '';
      final bootRef =
          refs['Device.DeviceInfo.BootFirmwareImage']?.toString() ?? '';
      logger.d('[USP][Dashboard]Firmware images: ${images.items.length}, '
          'active=$activeRef, boot=$bootRef');
      return (images: images, activeRef: activeRef, bootRef: bootRef);
    } catch (e) {
      logger.w('[USP][Dashboard]Firmware images fetch failed: $e');
      return (
        images: FirmwareImages(items: const []),
        activeRef: '',
        bootRef: '',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bridge port → Ethernet interface mapping
  // ---------------------------------------------------------------------------

  /// Fetches `Device.Bridging.Bridge.*.Port.*.LowerLayers` and builds a map
  /// from bridge port path → ethernet interface path.
  ///
  /// Example: `Device.Bridging.Bridge.1.Port.2.` → `Device.Ethernet.Interface.3.`
  /// This lets us correlate a device's Layer1Interface (bridge port) with
  /// the physical Ethernet port it's connected to.
  Future<Map<String, String>> _fetchBridgePortMap(UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.Bridging.Bridge.*.Port.*.LowerLayers',
      ]).timeout(const Duration(seconds: 10));
      final map = <String, String>{};
      for (final entry in resp.entries) {
        if (!entry.key.endsWith('.LowerLayers')) continue;
        final lowerLayers = entry.value?.toString() ?? '';
        if (lowerLayers.isEmpty) continue;
        // Extract bridge port path: remove trailing "LowerLayers"
        final bridgePortPath = entry.key.substring(
          0,
          entry.key.length - 'LowerLayers'.length,
        );
        // LowerLayers may be comma-separated; take first entry that points
        // to an Ethernet interface.
        for (final layer in lowerLayers.split(',')) {
          final trimmed = layer.trim();
          if (trimmed.startsWith('Device.Ethernet.Interface.')) {
            final normalized = trimmed.endsWith('.') ? trimmed : '$trimmed.';
            map[bridgePortPath] = normalized;
            break;
          }
        }
      }
      return map;
    } catch (e) {
      logger.w('[USP][Dashboard]Bridge port map fetch failed: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // SSE Invalidation — selective re-fetch by domain
  // ---------------------------------------------------------------------------

  /// Handles batched SSE invalidation signals by selectively re-fetching
  /// only the affected data domains. Avoids the full 17-class rebuild.
  Future<void> _handleInvalidation(Set<InvalidationDomain> domains) async {
    final s = state.valueOrNull;
    if (s == null || _mutating) return;

    logger.d('[USP][Dashboard]SSE invalidation: $domains');

    try {
      for (final domain in domains) {
        switch (domain) {
          case InvalidationDomain.connectedDevices:
            final devices = await ConnectedDevices.fetch(_usp);
            final wifiClientMap = await fetchWifiClients(_usp);
            final cur = state.requireValue;
            final connectionDetailMap = buildConnectionDetailMap(
              wifiClientMap: wifiClientMap,
              accessPoints: cur.wifiAccessPoints,
              ssids: cur.wifiSsids,
              radios: cur.wifiRadios,
            );
            final deviceModels = _svc.buildDeviceUIModels(
              connectedDevices: devices,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connectionDetailMap,
              meshTopology: cur.meshTopology,
              gatewayName: cur.systemInfo.modelName.isNotEmpty
                  ? cur.systemInfo.modelName
                  : 'Router',
            );
            state = AsyncData(cur.copyWith(
              connectedDevices: devices,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connectionDetailMap,
              deviceModels: deviceModels,
            ));
            break;

          case InvalidationDomain.wifiSsids:
            final ssids = await WiFiSsids.fetch(_usp);
            final cur = state.requireValue;
            state = AsyncData(cur.copyWith(
              wifiSsids: ssids,
              wifiRadioModels: _svc.buildWifiRadioUIModels(
                radios: cur.wifiRadios,
                ssids: ssids,
                accessPoints: cur.wifiAccessPoints,
              ),
            ));
            break;

          case InvalidationDomain.wifiRadios:
            final radios = await WiFiRadios.fetch(_usp);
            final cur = state.requireValue;
            state = AsyncData(cur.copyWith(
              wifiRadios: radios,
              wifiRadioModels: _svc.buildWifiRadioUIModels(
                radios: radios,
                ssids: cur.wifiSsids,
                accessPoints: cur.wifiAccessPoints,
              ),
            ));
            break;

          case InvalidationDomain.wifiAccessPoints:
            final aps = await WiFiAccessPoints.fetch(_usp);
            final cur = state.requireValue;
            state = AsyncData(cur.copyWith(
              wifiAccessPoints: aps,
              wifiRadioModels: _svc.buildWifiRadioUIModels(
                radios: cur.wifiRadios,
                ssids: cur.wifiSsids,
                accessPoints: aps,
              ),
            ));
            break;

          case InvalidationDomain.portForwarding:
            final pf = await PortForwarding.fetch(_usp);
            state = AsyncData(state.requireValue.copyWith(
              portForwarding: pf,
              portForwardingRuleModels:
                  _svc.buildPortForwardingRuleUIModels(pf),
            ));
            break;

          case InvalidationDomain.firewallRules:
            final rules = await FirewallChainRules.fetch(_usp);
            state = AsyncData(state.requireValue.copyWith(
              firewallRules: rules,
            ));
            break;

          case InvalidationDomain.dhcpReservations:
            final reservations = await DhcpReservations.fetch(_usp);
            state = AsyncData(state.requireValue.copyWith(
              dhcpReservations: reservations,
              dhcpReservationModels:
                  _svc.buildDhcpReservationUIModels(reservations),
            ));
            break;

          case InvalidationDomain.dmz:
            final dmzEntries = await Dmz.fetch(_usp);
            state = AsyncData(state.requireValue.copyWith(
              dmzEntries: dmzEntries,
            ));
            break;

          case InvalidationDomain.staticRouting:
            // Static routing is a standalone page, not part of dashboard state.
            // Its notifier handles its own invalidation.
            break;

          case InvalidationDomain.dhcpClients:
            // DHCP lease creation often accompanies device connect —
            // trigger same re-fetch as connectedDevices.
            final devices = await ConnectedDevices.fetch(_usp);
            final wifiClientMap = await fetchWifiClients(_usp);
            final curDhcp = state.requireValue;
            final connDetailMap = buildConnectionDetailMap(
              wifiClientMap: wifiClientMap,
              accessPoints: curDhcp.wifiAccessPoints,
              ssids: curDhcp.wifiSsids,
              radios: curDhcp.wifiRadios,
            );
            final devModels = _svc.buildDeviceUIModels(
              connectedDevices: devices,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connDetailMap,
              meshTopology: curDhcp.meshTopology,
              gatewayName: curDhcp.systemInfo.modelName.isNotEmpty
                  ? curDhcp.systemInfo.modelName
                  : 'Router',
            );
            state = AsyncData(curDhcp.copyWith(
              connectedDevices: devices,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connDetailMap,
              deviceModels: devModels,
            ));
            break;

          case InvalidationDomain.wifiClients:
            // WiFi client association change — re-fetch WiFi enricher data.
            final wifiMap = await fetchWifiClients(_usp);
            final curWifi = state.requireValue;
            final connDetail = buildConnectionDetailMap(
              wifiClientMap: wifiMap,
              accessPoints: curWifi.wifiAccessPoints,
              ssids: curWifi.wifiSsids,
              radios: curWifi.wifiRadios,
            );
            final models = _svc.buildDeviceUIModels(
              connectedDevices: curWifi.connectedDevices,
              wifiClientMap: wifiMap,
              connectionDetailMap: connDetail,
              meshTopology: curWifi.meshTopology,
              gatewayName: curWifi.systemInfo.modelName.isNotEmpty
                  ? curWifi.systemInfo.modelName
                  : 'Router',
            );
            state = AsyncData(curWifi.copyWith(
              wifiClientMap: wifiMap,
              connectionDetailMap: connDetail,
              deviceModels: models,
            ));
            break;
        }
      }
    } catch (e) {
      logger.w('[USP][Dashboard]SSE-triggered re-fetch failed: $e');
      // Non-fatal: data remains stale until next manual refresh
    }
  }

  // ---------------------------------------------------------------------------
  // Sequential lock guard
  // ---------------------------------------------------------------------------

  Future<T> _withLock<T>(Future<T> Function() action) async {
    if (_mutating) throw StateError('Another mutation is in progress');
    _mutating = true;
    try {
      return await action();
    } finally {
      _mutating = false;
    }
  }

  // ---------------------------------------------------------------------------
  // WAN DHCP Lease Renewal (F-002)
  // ---------------------------------------------------------------------------

  Future<void> renewWanLease() async {
    await _withLock(() async {
      // DHCP Renew is fire-and-forget — firmware does NOT send
      // OperationComplete for this operation (unlike Ping/Traceroute).
      await WanOperations.renewDhcpLease(_usp);
      await Future.delayed(const Duration(seconds: 2));
      final wan = await WanStatus.fetch(_usp);
      final s = state.requireValue;
      state = AsyncData(s.copyWith(
        wanStatus: wan,
        wanStatusModel: _svc.buildWanStatusUIModel(
          wanStatus: wan,
          gateway: s.wanStatusModel.gateway,
        ),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // WiFi Radio mutations (2B-2)
  // ---------------------------------------------------------------------------

  Future<void> toggleWifiRadio(String instancePath, bool enable) async {
    await _withLock(() async {
      await WiFiRadios.update(
          _usp, WiFiRadioUpdate(instancePath: instancePath, enable: enable));
      final radios = await WiFiRadios.fetch(_usp);
      final s = state.requireValue;
      state = AsyncData(s.copyWith(
        wifiRadios: radios,
        wifiRadioModels: _svc.buildWifiRadioUIModels(
          radios: radios,
          ssids: s.wifiSsids,
          accessPoints: s.wifiAccessPoints,
        ),
      ));
    });
  }

  Future<void> updateWifiRadioChannel(
      String instancePath, int channel, bool autoChannel) async {
    await _withLock(() async {
      await WiFiRadios.update(
        _usp,
        WiFiRadioUpdate(
          instancePath: instancePath,
          channel: channel,
          autoChannelEnable: autoChannel,
        ),
      );
      final radios = await WiFiRadios.fetch(_usp);
      final s = state.requireValue;
      state = AsyncData(s.copyWith(
        wifiRadios: radios,
        wifiRadioModels: _svc.buildWifiRadioUIModels(
          radios: radios,
          ssids: s.wifiSsids,
          accessPoints: s.wifiAccessPoints,
        ),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // Time Settings mutations (2B-5)
  // ---------------------------------------------------------------------------

  Future<void> updateTimeSettings(
      {bool? enable, String? ntpServer1, String? ntpServer2}) async {
    await _withLock(() async {
      final params = <String, dynamic>{};
      if (enable != null) params['Device.Time.Enable'] = enable;
      if (ntpServer1 != null) params['Device.Time.NTPServer1'] = ntpServer1;
      if (ntpServer2 != null) params['Device.Time.NTPServer2'] = ntpServer2;
      if (params.isNotEmpty) await _usp.set(params);
      final ts = await TimeSettings.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        timeSettings: ts,
        timeSettingsModel: _svc.buildTimeSettingsUIModel(ts),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // DHCP Reservation mutations (2B-3)
  // ---------------------------------------------------------------------------

  Future<void> toggleDhcpReservation(String instancePath, bool enable) async {
    await _withLock(() async {
      await DhcpReservations.update(
        _usp,
        DhcpReservationUpdate(instancePath: instancePath, enable: enable),
      );
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        dhcpReservations: reservations,
        dhcpReservationModels: _svc.buildDhcpReservationUIModels(reservations),
      ));
    });
  }

  Future<void> addDhcpReservation(
      {required String mac, required String ip, bool enable = true}) async {
    await _withLock(() async {
      await DhcpReservations.add(_usp, enable: enable, chaddr: mac, yiaddr: ip);
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        dhcpReservations: reservations,
        dhcpReservationModels: _svc.buildDhcpReservationUIModels(reservations),
      ));
    });
  }

  Future<void> updateDhcpReservation({
    required String instancePath,
    String? mac,
    String? ip,
    bool? enable,
  }) async {
    await _withLock(() async {
      await DhcpReservations.update(
        _usp,
        DhcpReservationUpdate(
          instancePath: instancePath,
          enable: enable,
          chaddr: mac,
          yiaddr: ip,
        ),
      );
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        dhcpReservations: reservations,
        dhcpReservationModels: _svc.buildDhcpReservationUIModels(reservations),
      ));
    });
  }

  Future<void> deleteDhcpReservation(String instancePath) async {
    await _withLock(() async {
      await DhcpReservations.delete(_usp, instancePath);
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        dhcpReservations: reservations,
        dhcpReservationModels: _svc.buildDhcpReservationUIModels(reservations),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // Port Forwarding mutations (2B-4)
  // ---------------------------------------------------------------------------

  Future<void> togglePortForwardingRule(
      String instancePath, bool enabled) async {
    await _withLock(() async {
      await PortForwarding.update(
        _usp,
        PortForwardingRuleUpdate(instancePath: instancePath, enabled: enabled),
      );
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        portForwarding: pf,
        portForwardingRuleModels: _svc.buildPortForwardingRuleUIModels(pf),
      ));
    });
  }

  Future<void> addPortForwardingRule({
    required int externalPort,
    required int internalPort,
    required String internalClient,
    required String protocol,
    String description = '',
    bool enabled = true,
    int externalPortEndRange = 0,
  }) async {
    await _withLock(() async {
      await PortForwarding.add(
        _usp,
        enabled: enabled,
        externalPort: externalPort,
        externalPortEndRange: externalPortEndRange,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        description: description,
      );
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        portForwarding: pf,
        portForwardingRuleModels: _svc.buildPortForwardingRuleUIModels(pf),
      ));
    });
  }

  Future<void> updatePortForwardingRule({
    required String instancePath,
    bool? enabled,
    int? externalPort,
    int? externalPortEndRange,
    int? internalPort,
    String? internalClient,
    String? protocol,
    String? description,
  }) async {
    await _withLock(() async {
      await PortForwarding.update(
        _usp,
        PortForwardingRuleUpdate(
          instancePath: instancePath,
          enabled: enabled,
          externalPort: externalPort,
          externalPortEndRange: externalPortEndRange,
          internalPort: internalPort,
          internalClient: internalClient,
          protocol: protocol,
          description: description,
        ),
      );
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        portForwarding: pf,
        portForwardingRuleModels: _svc.buildPortForwardingRuleUIModels(pf),
      ));
    });
  }

  Future<void> deletePortForwardingRule(String instancePath) async {
    await _withLock(() async {
      await PortForwarding.delete(_usp, instancePath);
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        portForwarding: pf,
        portForwardingRuleModels: _svc.buildPortForwardingRuleUIModels(pf),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // Port Triggering mutations
  // ---------------------------------------------------------------------------

  Future<void> _refreshPortTriggering() async {
    final pt = await PortTriggering.fetch(_usp);
    state = AsyncData(state.requireValue.copyWith(
      portTriggering: pt,
      portTriggeringRuleModels: _svc.buildPortTriggeringRuleUIModels(pt),
    ));
  }

  Future<void> togglePortTriggerRule(String instancePath, bool enabled) async {
    await _withLock(() async {
      await PortTriggering.update(
        _usp,
        PortTriggerUpdate(instancePath: instancePath, enabled: enabled),
      );
      await _refreshPortTriggering();
    });
  }

  Future<void> addPortTriggerRule({
    required int triggerPort,
    required String triggerProtocol,
    int triggerPortEndRange = 0,
    String description = '',
    bool enabled = true,
    int? forwardPort,
    int? forwardPortEndRange,
    String? forwardProtocol,
  }) async {
    await _withLock(() async {
      final parentPath = await PortTriggering.add(
        _usp,
        enabled: enabled,
        triggerPort: triggerPort,
        triggerPortEndRange: triggerPortEndRange,
        triggerProtocol: triggerProtocol,
        description: description,
      );
      // Auto-create a forward rule if provided
      if (forwardPort != null) {
        await PortTriggering.addPortTriggerForwardRule(
          _usp,
          parentPath,
          forwardPort: forwardPort,
          forwardPortEndRange: forwardPortEndRange,
          forwardProtocol: forwardProtocol,
        );
      }
      await _refreshPortTriggering();
    });
  }

  Future<void> updatePortTriggerRule({
    required String instancePath,
    bool? enabled,
    int? triggerPort,
    int? triggerPortEndRange,
    String? triggerProtocol,
    String? description,
  }) async {
    await _withLock(() async {
      await PortTriggering.update(
        _usp,
        PortTriggerUpdate(
          instancePath: instancePath,
          enabled: enabled,
          triggerPort: triggerPort,
          triggerPortEndRange: triggerPortEndRange,
          triggerProtocol: triggerProtocol,
          description: description,
        ),
      );
      await _refreshPortTriggering();
    });
  }

  Future<void> deletePortTriggerRule(String instancePath) async {
    await _withLock(() async {
      await PortTriggering.delete(_usp, instancePath);
      await _refreshPortTriggering();
    });
  }

  Future<void> addPortTriggerForwardRule({
    required String parentInstancePath,
    required int forwardPort,
    int forwardPortEndRange = 0,
    String forwardProtocol = 'TCP',
  }) async {
    await _withLock(() async {
      await PortTriggering.addPortTriggerForwardRule(
        _usp,
        parentInstancePath,
        forwardPort: forwardPort,
        forwardPortEndRange: forwardPortEndRange,
        forwardProtocol: forwardProtocol,
      );
      await _refreshPortTriggering();
    });
  }

  Future<void> deletePortTriggerForwardRule(String instancePath) async {
    await _withLock(() async {
      await PortTriggering.deletePortTriggerForwardRule(_usp, instancePath);
      await _refreshPortTriggering();
    });
  }
}
