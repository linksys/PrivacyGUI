import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

// Re-export so existing consumers can still import DevicesCodegenContext from here.
export 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart'
    show DevicesCodegenContext;

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — MeshNetwork as SSoT)
// ---------------------------------------------------------------------------

class DevicesData extends Equatable with DiagnosticLoggable {
  final DevicesCodegenContext codegenContext;
  final MeshTopologyInfo meshTopology;

  /// Pre-computed MAC → hostname map for DHCP hostname enrichment.
  final Map<String, String> hostNameByMac;

  /// Unified MeshNetwork container (SSoT for nodes and clients).
  final MeshNetwork meshNetwork;

  const DevicesData({
    this.codegenContext = DevicesCodegenContext.empty,
    this.meshTopology = MeshTopologyInfo.empty,
    this.hostNameByMac = const {},
    required this.meshNetwork,
  });

  /// All client devices.
  List<ClientDevice> get clientDevices => meshNetwork.allClients;

  /// All mesh nodes (master + slaves).
  List<NodeEntity> get nodes => meshNetwork.allNodes;

  /// Master node.
  MasterNode get master => meshNetwork.master;

  /// Slave nodes.
  List<SlaveNode> get slaves => meshNetwork.slaves;

  /// Count of online client devices.
  int get onlineClientCount => meshNetwork.onlineClientCount;

  /// Total count of client devices.
  int get totalClientCount => meshNetwork.totalClientCount;

  /// Whether this is a mesh network (has slave nodes).
  bool get hasMesh => meshNetwork.hasMesh;

  DevicesData copyWith({
    DevicesCodegenContext? codegenContext,
    MeshTopologyInfo? meshTopology,
    Map<String, String>? hostNameByMac,
    MeshNetwork? meshNetwork,
  }) {
    return DevicesData(
      codegenContext: codegenContext ?? this.codegenContext,
      meshTopology: meshTopology ?? this.meshTopology,
      hostNameByMac: hostNameByMac ?? this.hostNameByMac,
      meshNetwork: meshNetwork ?? this.meshNetwork,
    );
  }

  @override
  String get diagnosticName => 'DevicesData';

  @override
  Map<String, Object?> get namedProps => {
        'meshTopology': meshTopology,
        'meshNetwork': meshNetwork,
        'hostNameByMac': hostNameByMac,
      };

  // Explicit props override for reliable equality (includes the opaque
  // codegenContext). namedProps is kept lean for diagnostic JSON output.
  @override
  List<Object?> get props => [
        codegenContext,
        meshTopology,
        hostNameByMac,
        meshNetwork,
      ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final devicesDataProvider =
    AsyncNotifierProvider<DevicesDataNotifier, DevicesData>(
        DevicesDataNotifier.new);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class DevicesDataNotifier extends AsyncNotifier<DevicesData> {
  Timer? _debounce;

  /// Which refresh is allowed to publish.
  ///
  /// THIS PROVIDER PUBLISHES FROM THREE PLACES AND HAD NO ORDER (#1631). Two refreshes
  /// that overlap resolved in completion order rather than in the order the device was
  /// read, so an older read could win and nothing corrected it. `connectedDevices` is the
  /// highest-frequency domain the app subscribes to — `Device.Hosts.Host.` carries object
  /// creation, deletion and value change — and `_refetchPreservingMesh` awaits
  /// `wifiDataProvider.future` with a 5s timeout before it even calls `fetch()`, so the
  /// window is wide enough that a device joining and one leaving lands two refreshes
  /// inside it.
  ///
  /// A local counter rather than the event's `seq`: `seq` comes from the device and this
  /// code does not own its ordering guarantees, while a counter incremented here is
  /// monotonic by construction. `!=` rather than `<` for the same reason — it asks "am I
  /// still the newest?", which needs no ordering assumption at all.
  ///
  /// Same shape as the six L1 providers in #1615/#1628. Unlike those, this one never used
  /// `invalidateSelf()`, so it never had riverpod's coalescing to lose: the hazard has
  /// always been here rather than being introduced by removing that call.
  int _refreshGeneration = 0;

  @override
  Future<DevicesData> build() async {
    // A REBUILD SUPERSEDES ANY REFRESH IN FLIGHT, so it bumps the same counter. A save or
    // a pull-to-refresh calls `ref.invalidate`/`ref.refresh`, and without this bump a push
    // already awaiting its fetch would finish afterwards and publish pre-rebuild data.
    //
    // Cancelling the debounce here too: a timer armed before the rebuild would otherwise
    // fire afterwards and re-fetch data the rebuild just read.
    final generation = ++_refreshGeneration;
    _debounce?.cancel();

    // SSE: listen for device domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull?.domain;
      if (domain == InvalidationDomain.connectedDevices) {
        _debouncedInvalidate();
      }
    });

    // WiFi data changes → rebuild MeshNetwork with updated enrichment.
    //
    // The isLoading guard skipped the re-run frame `invalidateSelf()` published: it
    // carried the previous WifiData forward with isLoading set, so rebuilding on it
    // recomputed the mesh from stale data and emitted an extra state — which this
    // provider's own three listeners then saw as well (#1502 AC-4).
    //
    // As of #1615 `wifiDataProvider` assigns `state` directly, so that frame no longer
    // exists and this guard filters nothing: measured at most 1 notification per refresh that survives, versus 2
    // before. Kept deliberately — zero cost, and it still protects against a producer
    // that publishes a refresh frame again. See doc/riverpod/listen_site_audit.md.
    ref.listen(wifiDataProvider, (_, next) {
      if (next.isLoading) return;
      final wd = next.valueOrNull;
      final cur = state.valueOrNull;
      if (wd == null || cur == null) return;
      if (cur.codegenContext == DevicesCodegenContext.empty) return;

      final svc = ref.read(uspDevicesDataServiceProvider);

      // BARE READ ON PURPOSE HERE, unlike the two refresh paths which await `.future`.
      // This handler is synchronous by design — an `await` would open the overtaking
      // window that the comment below says does not exist. Read once rather than twice:
      // the previous version called this provider for the gateway name and again for the
      // model, which could return two different snapshots.
      //
      // If L1 is cold this degrades node identity the same way, so the refresh paths
      // awaiting it is what keeps that rare: by the time a WifiData push arrives, a
      // refresh has usually already populated L1.
      final sysInfo = ref.read(systemInfoDataProvider).valueOrNull?.model;
      final gatewayName = sysInfo?.gatewayName ?? 'Router';

      final meshNetwork = svc.rebuildWithWifiData(
        context: cur.codegenContext,
        wifiClientMap: wd.wifiClientMap,
        connectionDetailMap: wd.connectionDetailMap,
        meshTopology: cur.meshTopology,
        gatewayName: gatewayName,
        systemInfo: sysInfo,
      );

      // NOT GENERATION-GUARDED, and the reason is that a guard here would compare a
      // number against itself. This handler is synchronous end to end — it reads
      // `state.valueOrNull`, computes, and writes, with no `await` in between — so there
      // is no window in which a refresh could overtake it. The guard exists for writes
      // that publish a value captured before an `await`; this one publishes what it just
      // read. A refresh landing immediately after simply replaces it, which is correct.
      state = AsyncData(cur.copyWith(meshNetwork: meshNetwork));
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch(generation);
  }

  /// The two soft dependencies both refresh paths need, read once in one place.
  ///
  /// EXTRACTED BECAUSE IT WAS DUPLICATED VERBATIM. `_fetch()` and
  /// `_refetchPreservingMeshInner()` carried the same twelve lines, so adding the system
  /// info read meant writing it twice and any future change would too.
  ///
  /// SOFT in both cases: a failure degrades the page rather than failing it. Missing
  /// WifiData costs the per-client band and signal enrichment; missing system info costs
  /// node identity, which then falls back to the DataElements controller row — and that
  /// row describes prplMesh rather than the product (`Manufacturer=qcom`,
  /// `SerialNumber=prplmesh12345`, the prplMesh version as the firmware version), all four
  /// of which are shown in node detail. The device list itself is the useful half of this
  /// page and must still render.
  ///
  /// AWAITED, not `ref.read(...).valueOrNull`. A bare read returns null unless something
  /// else happens to hold L1 built and settled, and every `watch` of both providers is on
  /// another page — Statistics, Topology, Firmware Update, Admin, the dashboard cards. On
  /// the Devices page a bare read was therefore as likely to be null as not.
  Future<(WifiData, SystemInfoData?, String)> _readEnrichment() async {
    WifiData wifiData;
    try {
      wifiData = await ref
          .read(wifiDataProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      logger.w(
          '[USP][DevicesData]: WiFi data unavailable, proceeding without: $e');
      wifiData = const WifiData.empty();
    }

    SystemInfoData? sysData;
    try {
      sysData = await ref
          .read(systemInfoDataProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      logger.w(
          '[USP][DevicesData]: system info unavailable, node identity will fall '
          'back to DataElements: $e');
    }

    return (wifiData, sysData, sysData?.model.gatewayName ?? 'Router');
  }

  /// [generation] is passed in rather than read here, and that is the point: this method
  /// awaits three times — WifiData, system info, `svc.fetch()` — which is long enough for
  /// a push refresh to start and finish. A version of this read `_refreshGeneration` at
  /// the bottom and handed `_fetchMeshAndUpdate` the NEWER number, so a mesh update
  /// belonging to a superseded `build()` passed the guard and published. Taking it as a
  /// parameter makes that mistake impossible rather than merely documented.
  Future<DevicesData> _fetch(int generation) async {
    final svc = ref.read(uspDevicesDataServiceProvider);

    final (wifiData, sysData, gatewayName) = await _readEnrichment();

    final result = await svc.fetch(
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    logger.t('[USP][DevicesData]: Fetched — '
        'clients: ${result.meshNetwork.totalClientCount}, '
        'nodes: ${result.meshNetwork.allNodes.length}');

    // Preserve existing mesh topology during refetch to avoid UI flicker.
    // Fire-and-forget will update it shortly after.
    final existingMesh =
        state.valueOrNull?.meshTopology ?? MeshTopologyInfo.empty;

    // Fire-and-forget: fetch mesh topology in background, then update state. Carries the
    // generation captured at the top of this method — see there for why not the current one.
    _fetchMeshAndUpdate(
        svc, wifiData, gatewayName, sysData, result, generation);

    return DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      hostNameByMac: result.hostNameByMac,
      meshNetwork: result.meshNetwork,
    );
  }

  /// Background mesh topology fetch — updates state when complete.
  ///
  /// [generation] is the caller's, deliberately not a fresh one: this is a continuation of
  /// that refresh, so if the refresh was superseded while this was awaiting, its mesh must
  /// not publish either. Started AFTER the caller has already written `state`, and writing
  /// again when it finishes — two overlapping refreshes therefore produce four writes, and
  /// the generation is what orders them (#1631).
  void _fetchMeshAndUpdate(
    UspDevicesDataService svc,
    WifiData wifiData,
    String gatewayName,
    SystemInfoData? sysData,
    DevicesDataFetchResult fetchResult,
    int generation,
  ) {
    // `void`, so nothing can await this and nothing can catch what it throws — an error
    // from `fetchMeshTopology` or `rebuildWithMesh` would reach the zone's uncaught
    // handler. The mesh is the optional half of this page: the device list is already
    // published by the caller, and failing to decorate it with topology should cost the
    // decoration, not raise an error nobody asked for.
    unawaited(_fetchMeshAndUpdateInner(
      svc,
      wifiData,
      gatewayName,
      sysData,
      fetchResult,
      generation,
    ).catchError((Object e, StackTrace st) {
      logger.w(
          '[USP][DevicesData]: mesh topology update failed, keeping the '
          'device list as published',
          error: e,
          stackTrace: st);
    }));
  }

  Future<void> _fetchMeshAndUpdateInner(
    UspDevicesDataService svc,
    WifiData wifiData,
    String gatewayName,
    SystemInfoData? sysData,
    DevicesDataFetchResult fetchResult,
    int generation,
  ) async {
    // Build BSSID → band mapping for slave client band resolution
    final wifiCodegen = wifiData.codegenContext.raw;
    final bssidToBandMap = UspWifiDataService.buildBssidToBandMap(
      ssids: wifiCodegen.ssids,
      radios: wifiCodegen.radios,
    );

    final meshTopology = await svc.fetchMeshTopology(
      bssidToBandMap: bssidToBandMap,
    );
    if (meshTopology.isEmpty) return;

    final cur = state.valueOrNull;
    if (cur == null) return;

    final meshNetwork = svc.rebuildWithMesh(
      context: cur.codegenContext,
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    logger.t('[USP][DevicesData]: Mesh update — '
        'meshNodes: ${meshTopology.nodes.length}, '
        'clients: ${meshNetwork.totalClientCount}');

    // Superseded while the mesh fetch was awaiting — see [generation].
    if (generation != _refreshGeneration) return;

    state = AsyncData(cur.copyWith(
      meshTopology: meshTopology,
      meshNetwork: meshNetwork,
    ));
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refetchPreservingMesh();
    });
  }

  /// Refetch device data while preserving the existing mesh topology.
  /// This prevents the slave node from flickering during SSE-triggered refreshes.
  Future<void> _refetchPreservingMesh() async {
    try {
      await _refetchPreservingMeshInner();
    } catch (e, st) {
      // Called bare from a Timer callback, so without this a failure is an unhandled
      // async error rather than a log line — and the previous value is the right thing to
      // keep: a push-triggered refresh that fails should leave the list as it was, not
      // blank it. The six providers in #1615/#1628 do the same.
      logger.w(
          '[USP][DevicesData]: push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }

  Future<void> _refetchPreservingMeshInner() async {
    final generation = ++_refreshGeneration;
    final currentState = state.valueOrNull;
    final existingMesh = currentState?.meshTopology ?? MeshTopologyInfo.empty;

    final svc = ref.read(uspDevicesDataServiceProvider);

    final (wifiData, sysData, gatewayName) = await _readEnrichment();

    final result = await svc.fetch(
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    // Rebuild with existing mesh to preserve slave node visibility.
    final meshNetwork = existingMesh.isEmpty
        ? result.meshNetwork
        : svc.rebuildWithMesh(
            context: result.codegenContext,
            wifiClientMap: wifiData.wifiClientMap,
            connectionDetailMap: wifiData.connectionDetailMap,
            meshTopology: existingMesh,
            gatewayName: gatewayName,
            systemInfo: sysData?.model,
          );

    logger.t('[USP][DevicesData]: Refetch (preserve mesh) — '
        'clients: ${meshNetwork.totalClientCount}, '
        'existingMesh: ${existingMesh.nodes.length}');

    // Superseded — a newer refresh or a rebuild started while this one was awaiting.
    // Returning here rather than publishing is the whole point of #1631: this value was
    // read from the device BEFORE whatever is newer, so publishing it would move the app
    // backwards, and nothing would correct it.
    if (generation != _refreshGeneration) return;

    // Update state with new device data but preserve existing mesh topology.
    state = AsyncData(DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      hostNameByMac: result.hostNameByMac,
      meshNetwork: meshNetwork,
    ));

    // Fire-and-forget: fetch mesh topology in background, then update state.
    //
    // It inherits THIS refresh's generation rather than taking a fresh one, because it is
    // a continuation of this refresh and not a new one. Taking a new number would let a
    // superseded refresh's mesh fetch publish on top of a newer device read.
    _fetchMeshAndUpdate(
        svc, wifiData, gatewayName, sysData, result, generation);
  }
}
