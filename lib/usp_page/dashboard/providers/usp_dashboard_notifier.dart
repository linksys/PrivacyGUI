import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/services/usp_device_service.dart';
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
    this.total = 14,
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

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspDeviceService get _svc => ref.read(uspDeviceServiceProvider);

  @override
  Future<UspDashboardState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) {
      throw StateError('USP service not available');
    }
    // On page reload WASM state is lost — attempt session restore before giving up
    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw StateError('USP not authenticated after restore attempt');
      }
    }
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

    // Parallel fetch — WASM client v0.6.1+ supports concurrent HTTP requests.
    // Each fetch reports progress on completion for the loading indicator.
    final results = await Future.wait([
      SystemInfo.fetch(usp).then((v) {
        tick('System Info');
        return v;
      }),
      ConnectedDevices.fetch(usp).then((v) {
        tick('Devices');
        return v;
      }),
      WiFiRadios.fetch(usp).then((v) {
        tick('WiFi Radios');
        return v;
      }),
      WiFiSsids.fetch(usp).then((v) {
        tick('WiFi SSIDs');
        return v;
      }),
      WiFiAccessPoints.fetch(usp).then((v) {
        tick('Access Points');
        return v;
      }),
      TimeSettings.fetch(usp).then((v) {
        tick('Time Settings');
        return v;
      }),
      DhcpClients.fetch(usp).then((v) {
        tick('DHCP Clients');
        return v;
      }),
      DhcpReservations.fetch(usp).then((v) {
        tick('DHCP Reservations');
        return v;
      }),
      PortForwarding.fetch(usp).then((v) {
        tick('Port Forwarding');
        return v;
      }),
      PortTriggering.fetch(usp).then((v) {
        tick('Port Triggering');
        return v;
      }),
      fetchWifiClients(usp).then((v) {
        tick('WiFi Clients');
        return v;
      }),
      fetchMeshNodes(usp).then((v) {
        tick('Mesh Nodes');
        return v;
      }),
      LanNetworkInfo.fetch(usp).then((v) {
        tick('LAN Info');
        return v;
      }),
      EthernetInterfaces.fetch(usp).then((v) {
        tick('Ethernet Ports');
        return v;
      }),
    ]);

    final systemInfo = results[0] as SystemInfo;
    final connectedDevices = results[1] as ConnectedDevices;
    // DEBUG: Log connected devices Active field values
    for (final d in connectedDevices.items) {
      logger.d('[USP] Device ${d.hostName.isEmpty ? d.macAddress : d.hostName} '
          '— isActive: ${d.isActive}, IP: ${d.ipAddress}');
    }
    logger.d('[USP] Total devices: ${connectedDevices.items.length}, '
        'active: ${connectedDevices.items.where((d) => d.isActive).length}');
    final wifiRadios = results[2] as WiFiRadios;
    final wifiSsids = results[3] as WiFiSsids;
    final wifiAccessPoints = results[4] as WiFiAccessPoints;
    final timeSettings = results[5] as TimeSettings;
    final dhcpClients = results[6] as DhcpClients;
    final dhcpReservations = results[7] as DhcpReservations;
    final portForwarding = results[8] as PortForwarding;
    final portTriggering = results[9] as PortTriggering;
    final wifiClientMap = results[10] as Map<String, WifiClient>;
    final meshTopology = results[11] as MeshTopologyInfo;
    final lanNetworkInfo = results[12] as LanNetworkInfo;
    final ethernetInterfaces = results[13] as EthernetInterfaces;
    logger.d('[USP] WiFi clients enriched: ${wifiClientMap.length} entries');
    logger.d('[USP] Mesh nodes: ${meshTopology.nodes.length}, '
        'client mappings: ${meshTopology.clientToNodeMap.length}');

    // Cross-reference AP → SSID → Radio to get band + SSID name per client
    final connectionDetailMap = buildConnectionDetailMap(
      wifiClientMap: wifiClientMap,
      accessPoints: wifiAccessPoints,
      ssids: wifiSsids,
      radios: wifiRadios,
    );
    logger.d('[USP] Connection details: ${connectionDetailMap.length} entries');

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

    final systemInfoModel = svc.buildSystemInfoUIModel(systemInfo);

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
      isAuthenticated: usp.isAuthenticated,
      wifiClientMap: wifiClientMap,
      meshTopology: meshTopology,
      connectionDetailMap: connectionDetailMap,
      lanNetworkInfo: lanNetworkInfo,
      ethernetInterfaces: ethernetInterfaces,
      ethernetPortModels: svc.buildEthernetPortUIModels(
        ethernetInterfaces: ethernetInterfaces,
        connectedDevices: connectedDevices,
      ),
      lanInfoModel: svc.buildLanInfoUIModel(lanNetworkInfo),
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
      nodeModels: svc.buildNodeUIModels(
        meshTopology: meshTopology,
        deviceModels: deviceModels,
        systemInfo: systemInfoModel,
      ),
    );
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
