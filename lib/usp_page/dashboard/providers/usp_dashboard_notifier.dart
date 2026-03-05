import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

/// USP Dashboard provider — AsyncNotifier for read + write operations.
final uspDashboardProvider =
    AsyncNotifierProvider.autoDispose<UspDashboardNotifier, UspDashboardState>(
  UspDashboardNotifier.new,
);

/// Tracks which card is currently being mutated (for loading overlay).
/// Values: null (idle), 'wifi', 'time', 'dhcp', 'portForwarding'
final uspMutationLoadingProvider = StateProvider<String?>((ref) => null);

class UspDashboardNotifier
    extends AutoDisposeAsyncNotifier<UspDashboardState> {
  /// Sequential lock — prevents parallel USP calls (WASM bug)
  bool _mutating = false;

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

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
    // Parallel fetch — WASM client v0.6.1+ supports concurrent HTTP requests.
    final results = await Future.wait([
      SystemInfo.fetch(usp),
      ConnectedDevices.fetch(usp),
      WiFiRadios.fetch(usp),
      WiFiSsids.fetch(usp),
      WiFiAccessPoints.fetch(usp),
      TimeSettings.fetch(usp),
      DhcpReservations.fetch(usp),
      PortForwarding.fetch(usp),
      fetchWifiClients(usp),
      fetchMeshNodes(usp), // graceful fallback if DataElements unsupported
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
    final dhcpReservations = results[6] as DhcpReservations;
    final portForwarding = results[7] as PortForwarding;
    final wifiClientMap = results[8] as Map<String, WifiClient>;
    final meshTopology = results[9] as MeshTopologyInfo;
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

    return UspDashboardState(
      systemInfo: systemInfo,
      connectedDevices: connectedDevices,
      wifiRadios: wifiRadios,
      wifiSsids: wifiSsids,
      wifiAccessPoints: wifiAccessPoints,
      timeSettings: timeSettings,
      dhcpReservations: dhcpReservations,
      portForwarding: portForwarding,
      isAuthenticated: usp.isAuthenticated,
      wifiClientMap: wifiClientMap,
      meshTopology: meshTopology,
      connectionDetailMap: connectionDetailMap,
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
      state = AsyncData(state.requireValue.copyWith(wifiRadios: radios));
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
      state = AsyncData(state.requireValue.copyWith(wifiRadios: radios));
    });
  }

  // ---------------------------------------------------------------------------
  // Time Settings mutations (2B-5)
  // ---------------------------------------------------------------------------

  Future<void> updateTimeSettings(
      {bool? enable, String? ntpServer1, String? ntpServer2}) async {
    await _withLock(() async {
      // Manual SET — codegen may not generate save() for single-instance
      final params = <String, dynamic>{};
      if (enable != null) params['Device.Time.Enable'] = enable;
      if (ntpServer1 != null) params['Device.Time.NTPServer1'] = ntpServer1;
      if (ntpServer2 != null) params['Device.Time.NTPServer2'] = ntpServer2;
      if (params.isNotEmpty) await _usp.set(params);
      final timeSettings = await TimeSettings.fetch(_usp);
      state =
          AsyncData(state.requireValue.copyWith(timeSettings: timeSettings));
    });
  }

  // ---------------------------------------------------------------------------
  // DHCP Reservation mutations (2B-3)
  // ---------------------------------------------------------------------------

  Future<void> toggleDhcpReservation(
      String instancePath, bool enable) async {
    await _withLock(() async {
      await DhcpReservations.update(
        _usp,
        DhcpReservationUpdate(instancePath: instancePath, enable: enable),
      );
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(
          state.requireValue.copyWith(dhcpReservations: reservations));
    });
  }

  Future<void> addDhcpReservation(
      {required String mac, required String ip, bool enable = true}) async {
    await _withLock(() async {
      await DhcpReservations.add(_usp,
          enable: enable, chaddr: mac, yiaddr: ip);
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(
          state.requireValue.copyWith(dhcpReservations: reservations));
    });
  }

  Future<void> deleteDhcpReservation(String instancePath) async {
    await _withLock(() async {
      await DhcpReservations.delete(_usp, instancePath);
      final reservations = await DhcpReservations.fetch(_usp);
      state = AsyncData(
          state.requireValue.copyWith(dhcpReservations: reservations));
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
      state = AsyncData(state.requireValue.copyWith(portForwarding: pf));
    });
  }

  Future<void> addPortForwardingRule({
    required int externalPort,
    required int internalPort,
    required String internalClient,
    required String protocol,
    String description = '',
    bool enabled = true,
  }) async {
    await _withLock(() async {
      await PortForwarding.add(
        _usp,
        enabled: enabled,
        externalPort: externalPort,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        description: description,
      );
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(portForwarding: pf));
    });
  }

  Future<void> updatePortForwardingRule(
      PortForwardingRuleUpdate update) async {
    await _withLock(() async {
      await PortForwarding.update(_usp, update);
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(portForwarding: pf));
    });
  }

  Future<void> deletePortForwardingRule(String instancePath) async {
    await _withLock(() async {
      await PortForwarding.delete(_usp, instancePath);
      final pf = await PortForwarding.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(portForwarding: pf));
    });
  }
}
