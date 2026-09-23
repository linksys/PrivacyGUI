import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
// No `hide` needed since ui_kit 3.4.0: the kit's own `ConnectionType` became
// `EdgeKind`, so this model's same-named enum no longer clashes.
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/backhaul_parent_graph.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:privacy_gui/page/topology/helpers/topology_edge_strength.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [GraphData] from USP dashboard state for [AppTopology] widget.
///
/// Shared between the dashboard topology card and the full-page topology view.
class UspTopologyBuilder {
  UspTopologyBuilder._();

  /// Builds topology from new [MeshNetwork] architecture.
  ///
  /// Preferred method — uses SSoT container with pre-organized nodes and clients.
  static GraphData buildFromMeshNetwork({
    required MeshNetwork meshNetwork,
    required SystemInfoUIModel info,
  }) {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];

    final master = meshNetwork.master;

    // Gateway node
    const gatewayId = 'gateway';
    final gatewayIconName = routerIconTestByModel(
      modelNumber: master.model.isNotEmpty ? master.model : info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    nodes.add(GraphNode(
      id: gatewayId,
      identifier: kTopologyMasterIdentifier,
      name:
          master.displayName.isNotEmpty ? master.displayName : info.gatewayName,
      // Stated, not derived, even though derivation would agree here *today*.
      //
      // This build emits no external node, so the gateway is the structural root
      // and would derive `primary` anyway. It is stated because the agreement is a
      // coincidence of the current graph, not a property of it: adding an upstream
      // node — which `GraphNode.external` exists for — gives the gateway a parent
      // and silently demotes it to an interior appearance. Every origin states its
      // own slot so that none of them depends on the shape of the others.
      styleSlot: TopologySlots.master,
      status: master.isOnline ? NodeState.active : NodeState.inactive,
      image: DeviceImageHelper.getRouterImage(gatewayIconName),
      extra: _subtitle([
        // Model first: it is what distinguishes this row from the slaves under
        // it, whereas the manufacturer is the same word on every row in a
        // single-vendor mesh.
        master.model.isNotEmpty ? master.model : info.modelName,
        master.manufacturer.isNotEmpty
            ? master.manufacturer
            : info.manufacturer,
      ]),
      level: 1.0,
      metadata: {
        'deviceId': master.deviceId,
        'model': master.model.isNotEmpty ? master.model : info.modelName,
        'manufacturer': master.manufacturer.isNotEmpty
            ? master.manufacturer
            : info.manufacturer,
        'serialNumber': master.serialNumber.isNotEmpty
            ? master.serialNumber
            : info.serialNumber,
        'softwareVersion': master.softwareVersion.isNotEmpty
            ? master.softwareVersion
            : info.softwareVersion,
        'isMaster': true,
      },
    ));

    // Build extender ID lookup maps.
    // Normalized set (no colons, uppercase) for matching against parentNodeId
    // which comes from DataElements clientToNodeMap (no colons).
    // We add BOTH deviceId (from Hosts) and dataElementsId (from DataElements)
    // since they may be different MAC addresses for the same node.
    logger.t('[USP][TopologyBuilder]: hasMesh=${meshNetwork.hasMesh}, '
        'slaveNodes=${meshNetwork.slaves.length}, '
        'slaveDeviceIds=${meshNetwork.slaves.map((n) => '${n.deviceId}|DE:${n.dataElementsId}').toList()}');
    final extenderNodeIdsNormalized = <String>{};
    final normalizedToOriginal = <String, String>{};
    final deviceIdToExtenderId = <String, String>{};
    final parentQueries = <BackhaulParentQuery>[];

    for (final slave in meshNetwork.slaves) {
      final extenderId = 'extender-${slave.deviceId}';
      // `normalizeMac` rather than a hand-written
      // `toUpperCase().replaceAll(':', '')`, which is what these five sites used
      // to spell: it strips *every* separator, so a dashed or spaced identifier
      // — firmware writes MACs in more than one shape — keys the same entry
      // instead of missing the lookup and losing a hop (#1441). The keys and the
      // value probed against them must be normalised the same way, which is the
      // whole reason it is one named function — and it already existed in
      // `node_identifier.dart`, which this file imports.
      final normalizedHostsMac = normalizeMac(slave.deviceId);
      extenderNodeIdsNormalized.add(normalizedHostsMac);
      normalizedToOriginal[normalizedHostsMac] = slave.deviceId;
      deviceIdToExtenderId[normalizedHostsMac] = extenderId;

      if (slave.dataElementsId != null && slave.dataElementsId!.isNotEmpty) {
        final normalizedDeMac = normalizeMac(slave.dataElementsId!);
        if (normalizedDeMac != normalizedHostsMac) {
          extenderNodeIdsNormalized.add(normalizedDeMac);
          normalizedToOriginal[normalizedDeMac] = slave.deviceId;
          deviceIdToExtenderId[normalizedDeMac] = extenderId;
        }
      }
      parentQueries.add((
        extenderId: extenderId,
        parentDeviceId: slave.backhaul.parentNodeId,
      ));
      logger.t('[USP][TopologyBuilder]: Slave ${slave.deviceId} '
          '→ hostsMac: $normalizedHostsMac, '
          'dataElementsId: ${slave.dataElementsId}, '
          'backhaulParentDeviceId: ${slave.backhaul.parentNodeId}');
    }

    // Parent resolution, as a graph rather than a lookup per slave (#1441).
    //
    // Two things that `deviceIdToExtenderId[parent] ?? gatewayId` could not do,
    // and neither is about how the parent of one node is found:
    //
    // 1. **A cycle must not be emitted.** Nothing here walks the graph, so
    //    nothing here can loop — but ui_kit's layout walks it with no visited set
    //    and no depth bound, so A→B→A overflows the stack there, inside widgets
    //    we may not hand-roll around (constitution Article XV).
    // 2. **A failed lookup must not read like a correct one.** The gateway's own
    //    MAC is not a key in the map above — it has no `extender-` id — so a node
    //    correctly parented by the gateway took the same `??` fallback as a node
    //    whose parent is missing from the tree. The master's identifiers are
    //    passed in for exactly that distinction.
    final parentGraph = resolveBackhaulParents(
      // Collected in the loop above rather than re-derived here: a second pass
      // would re-spell `extender-<deviceId>`, and an id built two ways is an id
      // that can differ in one of them.
      slaves: parentQueries,
      extenderIdByNodeMac: deviceIdToExtenderId,
      gatewayNodeMacs: {
        for (final mac in [master.deviceId, master.dataElementsId])
          if (mac != null && mac.isNotEmpty) normalizeMac(mac),
      },
      gatewayId: gatewayId,
    );

    // Hoisted: the getter builds a fresh map, so reading it inside the loop
    // below would rebuild it once per slave.
    final parentIdByExtenderId = parentGraph.parentIdByExtenderId;

    // Warning level, and once per finding: both states mean the rendered topology
    // is not the one firmware described, and a support bundle is the only place
    // anyone will see it. `logger.t` is filtered out of release builds, which is
    // where the bundles come from.
    for (final miss in parentGraph.misses) {
      logger.w('[USP][TopologyBuilder]: backhaul parent MISS — '
          '${miss.extenderId} names ${miss.reportedParentDeviceId}, which is '
          'not a node in this topology; attaching it to the gateway. A hop is '
          'lost, so the tree renders flatter than the network is.');
    }
    for (final broken in parentGraph.brokenCycles) {
      logger.w('[USP][TopologyBuilder]: backhaul parent cycle — '
          '${broken.cycle.join(' → ')} → ${broken.cycle.first}; '
          'attaching ${broken.extenderId} to the gateway to break it. '
          'Emitting the cycle would overflow the layout\'s recursion.');
    }

    // Stable, data-derived E2E identifier keys (Article XVI §16.3): shortest
    // MAC suffix that stays unique within each node group, independent of the
    // display label / node order.
    final slaveIdKeys =
        shortestUniqueMacSuffixes(meshNetwork.slaves.map((s) => s.deviceId));

    // Slave nodes
    for (final slave in meshNetwork.slaves) {
      final extenderId = 'extender-${slave.deviceId}';

      // Resolved above, for the whole graph at once — a cycle is a property of
      // the set, not of one node.
      final parentId = parentIdByExtenderId[extenderId] ?? gatewayId;

      final extenderIconName = routerIconTestByModel(modelNumber: slave.model);
      nodes.add(GraphNode(
        id: extenderId,
        identifier: topologySlaveIdentifier(slaveIdKeys[slave.deviceId] ?? ''),
        name: slave.displayName,
        // Stated for every slave, whether or not it carries clients. A slave
        // with none is a structural leaf, and a derived slot would shrink it and
        // let an aggregate fold it away — the information that it is a node of
        // its own is not in the graph, only in the loop we are standing in.
        styleSlot: TopologySlots.slave,
        status: slave.isOnline ? NodeState.active : NodeState.inactive,
        parentId: parentId,
        image: DeviceImageHelper.getRouterImage(extenderIconName),
        // A slave used to carry no subtitle at all, so its tree row was a name
        // and nothing else. Model, then the backhaul — the one fact that
        // differs between two otherwise identical extenders — and its signal
        // where the medium is wireless and firmware measured one.
        extra: _subtitle([
          slave.model,
          _backhaulSummary(slave.backhaul),
        ]),
        level: _backhaulLevel(slave.backhaul),
        metadata: {
          'deviceId': slave.deviceId,
          'model': slave.model,
          'manufacturer': slave.manufacturer,
          'serialNumber': slave.serialNumber,
          'softwareVersion': slave.softwareVersion,
          'isMaster': false,
          'backhaulLinkType': slave.backhaul.linkType,
          'backhaulParentDeviceId': slave.backhaul.parentNodeId,
          'backhaulSignalStrength': slave.backhaul.signalStrength,
          'backhaulUplinkRate': slave.backhaul.uplinkRate,
          'backhaulDownlinkRate': slave.backhaul.downlinkRate,
          'lastContactTime': slave.backhaul.lastContactTime,
        },
      ));

      edges.add(GraphEdge(
        sourceId: parentId,
        targetId: extenderId,
        kind: _edgeKindFor(slave.backhaul),
        // Stated rather than left to the kit, and still stated for a backhaul of
        // unknown medium: `Backhaul.Stats.SignalStrength` measures *this* link
        // whether or not firmware named what carries it, so a row with an RSSI and
        // no medium is a link we graded and firmware did not label. Only read for
        // an indirect edge, so a wired backhaul's value is ignored rather than
        // needing to be suppressed here.
        strength: edgeStrengthFromRssi(slave.backhaul.signalStrength),
      ));
    }

    // Client devices — use allClients which includes master + slave clients
    final clientIdKeys =
        shortestUniqueMacSuffixes(meshNetwork.allClients.map((c) => c.mac));
    for (final client in meshNetwork.allClients) {
      final clientId = 'client-${client.mac}';
      final isEthernet = !client.isWifi;

      // Determine parent node
      String parentId = gatewayId;
      if (meshNetwork.hasMesh && client.parentNodeId != null) {
        // Normalised the same way as the keys it is probed against, which is why
        // this site moved to `normalizeMac` with the node-side ones (#1441): the
        // set below is built in the slave loop above, so leaving this probe on the
        // old `toUpperCase().replaceAll(':', '')` would make the two disagree on
        // any identifier that is not colon-separated — the mismatch #1441 is
        // about, pointed at clients. Client *attribution* logic is #1439's and is
        // untouched.
        final parentNormalized = normalizeMac(client.parentNodeId!);
        logger.t('[USP][TopologyBuilder]: Device ${client.displayName} '
            'parentNodeId=${client.parentNodeId}, '
            'normalized=$parentNormalized, '
            'inExtenders=${extenderNodeIdsNormalized.contains(parentNormalized)}');
        if (extenderNodeIdsNormalized.contains(parentNormalized)) {
          final originalDeviceId = normalizedToOriginal[parentNormalized]!;
          parentId = 'extender-$originalDeviceId';
        }
      } else {
        logger.t('[USP][TopologyBuilder]: Device ${client.displayName} '
            'hasMesh=${meshNetwork.hasMesh}, '
            'parentNodeId=${client.parentNodeId} → gateway');
      }

      final category = DeviceClassifier.classify(
        hostname: client.displayName,
        mac: client.mac,
      );

      nodes.add(GraphNode(
        id: clientId,
        identifier: topologyClientIdentifier(clientIdKeys[client.mac] ?? ''),
        name: client.displayName,
        styleSlot: TopologySlots.device,
        status: client.isOnline ? NodeState.active : NodeState.inactive,
        parentId: parentId,
        iconData: category.icon,
        // IP leads: it is what a viewer scans a list of devices for. The band
        // follows where there is one, because two rows for the same device on
        // different radios are otherwise identical.
        extra: _subtitle([
          client.ip,
          if (client.isWifi) client.band,
        ]),
        // `GraphNode.edgeStrength` (was `MeshNode.linkQuality`) is deliberately
        // not fed: measured zero reads across the whole kit on both 3.3.3 and
        // 3.4.0. The edge below carries the strength, and that one is read.
        level: _rssiToLevelForClient(client),
        // The facts a leaf's detail panel shows. ui_kit 3.4.0 opens a panel for a
        // leaf — it used to refuse one — so what the builder puts here is now
        // visible rather than dead weight, and a leaf carrying only its MAC gave
        // the viewer a panel with nothing in it (#1614).
        //
        // Written as a device's own facts, not as a mesh node's: the role,
        // model, serial and backhaul rows belong to a node and a leaf has none
        // of them. `isLeaf` is what the panel keys that split on, rather than
        // inferring it from which keys happen to be absent.
        metadata: {
          'isLeaf': true,
          'mac': client.mac,
          if (client.ip.isNotEmpty) 'ip': client.ip,
          'isWifi': client.isWifi,
          // Only for a wireless client: a wired one has no RSSI by design, and a
          // present-but-null entry would still draw an empty row.
          if (client.isWifi && client.signalStrength != null)
            'signalStrength': client.signalStrength,
          if (client.band != null && client.band!.isNotEmpty)
            'band': client.band,
          if (client.ssidName != null && client.ssidName!.isNotEmpty)
            'ssid': client.ssidName,
          // The node this device hangs off, by name where firmware gave one.
          if (client.parentNodeName != null &&
              client.parentNodeName!.isNotEmpty)
            'parentNodeName': client.parentNodeName,
          'hasMultipleInterfaces': client.hasMultipleInterfaces,
          'interfaceCount': client.interfaceCount,
          'allMacAddresses': client.allMacAddresses,
        },
      ));

      edges.add(GraphEdge(
        sourceId: parentId,
        targetId: clientId,
        kind: isEthernet ? EdgeKind.direct : EdgeKind.indirect,
        // Null for a wired client, rather than a fabricated grade. This used to
        // say `LinkQuality.stable` — a *medium* named inside an enum about
        // quality, which is why 3.4.0 deleted that member. `EdgeKind.direct`
        // already carries "wired", and `strength` is not read for it.
        strength:
            isEthernet ? null : edgeStrengthFromRssi(client.signalStrength),
        distanceFactor: _rssiToDistanceFactor(client.signalStrength),
      ));
    }

    return GraphData(
      nodes: nodes,
      edges: edges,
      lastUpdated: DateTime.now(),
    );
  }

  /// The one line a tree row shows under a node's name.
  ///
  /// Two or three facts, joined with a middle dot, skipping the ones this node
  /// has nothing for — so a row never leads with a separator and never shows a
  /// dangling one, which is what a naive `join` of a list containing empties
  /// produces. Null when nothing is known, because [GraphNode.extra] is nullable
  /// and an empty string is a subtitle the tree would still lay out.
  ///
  /// Deliberately short. It competes with the row's own slot label and status
  /// badge for a single line, and the detail panel is where the full field set
  /// lives.
  static String? _subtitle(List<String?> parts) {
    final kept =
        parts.map((p) => p?.trim() ?? '').where((p) => p.isNotEmpty).toList();
    return kept.isEmpty ? null : kept.join(' · ');
  }

  /// A slave's backhaul as one phrase: the medium, and its signal when that is
  /// both meaningful and measured.
  ///
  /// Null rather than a placeholder when firmware named no medium. `LinkType =
  /// None` is the ordinary state on FL-WRT 2.0, not an error, and claiming
  /// `Wi-Fi` for it is the defect #1464 closed — a subtitle is no place to
  /// re-introduce it. The caller drops the null, so such a row falls back to its
  /// model alone.
  ///
  /// The signal is withheld for a wired backhaul on the same grounds the link
  /// style is: a wire has no RSSI by design, so a reading beside `Ethernet`
  /// would be describing something else.
  static String? _backhaulSummary(BackhaulInfo backhaul) {
    final linkType = backhaul.linkType?.trim() ?? '';
    if (linkType.isEmpty || linkType.toLowerCase() == 'none') return null;
    final rssi = backhaul.signalStrength;
    if (backhaul.isEthernet || rssi == null) return linkType;
    return '$linkType $rssi dBm';
  }

  static double _rssiToLevelForClient(ClientDevice client) {
    if (!client.isWifi) return 1.0;
    return _rssiValueToLevel(client.signalStrength);
  }

  /// The medium to draw a slave's backhaul edge with, or null when firmware
  /// named none.
  ///
  /// Three outcomes, because the medium has three states and not two. A backhaul
  /// firmware named no medium for is neither wired nor wireless, and **null is how
  /// 3.4.0 spells that**: `EdgeKind` has two members and `GraphEdge.kind` is
  /// optional, so an undeclared kind and an unknown one are the same value. Before
  /// ui_kit v3.2.0 there was nowhere to say it at all and this site claimed `wifi`
  /// as the lesser of two wrong answers — and paid for it, because the wireless
  /// style animates flow, so the graph animated traffic along a link nothing was
  /// known about.
  ///
  /// Every renderer resolves its style through `GraphEdge.styleFrom`, which
  /// switches on the kind *first* and routes null to
  /// `TopologySpec.undeclaredEdgeStyle` — a style per visual language whose one
  /// cross-language guarantee is no flow animation. Nothing is hand-rolled here
  /// (constitution Article XV).
  ///
  /// **The strength axis is left alone, deliberately.** A row with an RSSI and no
  /// named medium is a link we measured and firmware did not label:
  /// `Backhaul.Stats.SignalStrength` reads *this* link, and a wired backhaul has
  /// none. So the caller states a strength beside a null kind, and the two axes
  /// stay independent — pinned as a pair in `usp_topology_builder_test.dart` so the
  /// next reader does not have to re-derive it.
  ///
  /// Keyed on **absence** of a medium, not on failing to match `Ethernet`: a value
  /// firmware named and we do not recognise stays wireless. The practical
  /// vocabulary is closed at `Wi-Fi` / `Ethernet` / `None` (#1464 AC1, measured
  /// against `beerocks_controller`), so an unrecognised medium is not a state this
  /// build produces, while an absent one is the *ordinary* state on FL-WRT 2.0 —
  /// the controller row reports `LinkType = None`, which `meshBackhaulLinkType`
  /// maps to null.
  ///
  /// [BackhaulInfo.isWifi] is deliberately not the test: it is true for a link
  /// known only by its parent ID, which is exactly the row that must not claim a
  /// medium here. See its doc and [BackhaulInfo.hasMedium].
  static EdgeKind? _edgeKindFor(BackhaulInfo backhaul) {
    if (backhaul.isEthernet) return EdgeKind.direct;
    if (!backhaul.hasMedium) return null;
    return EdgeKind.indirect;
  }

  /// Converts a slave node's backhaul to a display level.
  ///
  /// - Ethernet backhaul: full level (1.0), matching how wired links are shown
  ///   elsewhere — a wired connection has no RSSI by design, not by absence.
  /// - No backhaul data at all (e.g. an offline node with no DataElements
  ///   match): 0.0 — no signal, not a fabricated mid-strength 0.5 that looks
  ///   like a real reading (#1430, AC4).
  /// - Wi-Fi backhaul with an RSSI: the RSSI-derived level.
  /// - Wi-Fi backhaul whose stats are missing (`BackhaulStats` absent, or an
  ///   RCPI of `0` that [rcpiToRssi] maps to null): the neutral 0.5. The node is
  ///   up and its backhaul is real — only the reading is missing, so 0.0 would
  ///   paint a healthy node as dead. AC4's "no 0.5" applies to an *absent*
  ///   backhaul, which is the first case above. A truthful third state needs a
  ///   nullable level in the ui_kit `MeshNode` (`level` is a non-nullable
  ///   `double`), so this is the least-wrong value the current API allows.
  ///
  /// `isEthernet` is tested **before** `hasInfo`. That order used to be
  /// load-bearing: the two read different fields (`linkType` and `mediaType`)
  /// with nothing coupling them, so `linkType:'Ethernet'` with an empty
  /// `mediaType` was representable and checking `hasInfo` first painted that
  /// node at 0.0 — dead — while two other sites called the same node Ethernet.
  /// Since #1555 `isEthernet` and the medium half of `hasInfo` read the same
  /// field, so `isEthernet` implies `hasInfo` and that state cannot be
  /// constructed. The order is kept because it still reads as the intent (a
  /// positive medium wins), but it is no longer what prevents the disagreement.
  ///
  /// The `0.0` arm is narrower than it looks, and deliberately so. `hasInfo`
  /// counts a known parent as a link even when firmware named no medium (#1555),
  /// so a node like that falls through to `0.5`/RSSI here rather than being
  /// painted dead. Keying this on the medium alone is what made the same node
  /// read "dead link" here and "Wi-Fi, graded on signal" in
  /// `UnifiedDiagnosticsService` — see `BackhaulInfo.hasInfo`. `0.0` is now only
  /// for a node with neither medium nor parent, which is a backhaul we have no
  /// evidence of at all.
  static double _backhaulLevel(BackhaulInfo backhaul) {
    if (backhaul.isEthernet) return 1.0;
    if (!backhaul.hasInfo) return 0.0;
    if (backhaul.signalStrength == null) return 0.5;
    return _rssiValueToLevel(backhaul.signalStrength);
  }

  /// Common RSSI to level conversion. Uses [getWifiSignalLevel] as the single
  /// source of truth for RSSI thresholds.
  static double _rssiValueToLevel(int? rssi) {
    if (rssi == null) return 0.0;
    return switch (getWifiSignalLevel(rssi)) {
      NodeSignalLevel.excellent => 0.9,
      NodeSignalLevel.good => 0.65,
      NodeSignalLevel.fair => 0.4,
      NodeSignalLevel.poor => 0.1,
      NodeSignalLevel.none => 0.0,
      NodeSignalLevel.wired => 1.0,
    };
  }

  /// Maps RSSI (dBm) to normalized distance factor [0.0, 1.0].
  static double? _rssiToDistanceFactor(int? rssi) {
    if (rssi == null) return null;
    final clamped = rssi.clamp(-90, -50);
    return (clamped - (-50)).abs() / 40.0;
  }
}
