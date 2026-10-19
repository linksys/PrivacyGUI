import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';

/// Builds [MeshTopologyInfo] from DataElements network data.
///
/// Shared utility for converting TR-181 DataElements to UI models.
/// Used by both [UspDevicesDataService] and [PnpService].
class MeshTopologyBuilder {
  MeshTopologyBuilder._();

  /// Converts [DataElementsNetwork] to [MeshTopologyInfo].
  ///
  /// Extracts mesh nodes and builds client MAC → node ID mapping
  /// for determining which mesh node each client device is connected to.
  ///
  /// [bssidToBandMap] is optional mapping of BSSID (uppercase) → band string
  /// (e.g., "2.4GHz", "5GHz"). When provided, allows extracting band info
  /// for clients connected to any node (including slave nodes).
  ///
  /// Set [includeBackhaulStats] to true to include backhaul signal strength
  /// and uplink rate (requires DataElements backhaul stats to be available).
  ///
  /// [interfaces] is the separately fetched `Interface.{j}.Neighbor.{k}`
  /// subtree. Null when it was not read or the read failed; then no wired
  /// client is attributed and every wired client stays on the master, as
  /// before #1688.
  ///
  /// [controllerId] is `Device.WiFi.DataElements.Network.ControllerID`. When
  /// given, the node with that ID is the master and **every other node is a
  /// slave**, backhaul evidence or not. Without it the master is the node with
  /// no backhaul link ([hasMeshBackhaulLink]), which builds an agent whose
  /// backhaul has not been filled in yet — just joined, or re-associating — as
  /// a second master. Since #1688 the nodes come only from here, and a second
  /// master is not a slave, so that agent vanished from the topology. Null
  /// when the read failed or the firmware did not answer: the backhaul rule
  /// then decides, as before.
  static MeshTopologyInfo build(
    DataElementsNetwork network, {
    Map<String, String> bssidToBandMap = const {},
    bool includeBackhaulStats = true,
    DataElementsInterfaces? interfaces,
    String? controllerId,
  }) {
    final controllerKey = _nodeKey(controllerId);
    // Only trust ControllerID when it names a node actually in this read; a
    // stale or foreign value must not turn the real controller into a slave.
    final controllerListed = controllerKey != null &&
        network.items.any((n) => _nodeKey(n.id) == controllerKey);
    final nodes = <NodeEntity>[];
    final clientToNodeMap = <String, String>{};
    final clientSignalMap = <String, int>{};
    final clientBandSsidMap = <String, ({String band, String ssid})>{};

    for (final node in network.items) {
      final rawId = node.id.trim().toUpperCase();
      final nodeDeviceId = rawId.isNotEmpty ? rawId : node.instancePath;

      // Build client MAC → node ID mapping, signal strength, and band/SSID
      for (final radio in node.radios) {
        for (final bss in radio.bssList) {
          // Resolve band from BSSID → band mapping
          final bssidUpper = bss.bssid.trim().toUpperCase();
          final band = bssidToBandMap[bssidUpper] ?? '';
          final ssid = bss.ssid.trim();

          for (final sta in bss.stations) {
            final mac = sta.macAddress.trim();
            if (mac.isNotEmpty && nodeDeviceId.isNotEmpty) {
              final upperMac = mac.toUpperCase();
              clientToNodeMap[upperMac] = nodeDeviceId;
              // DataElements STA.SignalStrength is RCPI (0-220), convert to
              // RSSI. This field is declared `check_maximum 255` upstream, so
              // it can carry the 221-255 "not available" band; `rcpiToRssi`
              // returns null for those and the entry is simply not written.
              final rssi = rcpiToRssi(sta.signalStrengthRcpi);
              if (rssi != null) {
                clientSignalMap[upperMac] = rssi;
              }
              // Store band + SSID for this client
              if (band.isNotEmpty || ssid.isNotEmpty) {
                clientBandSsidMap[upperMac] = (band: band, ssid: ssid);
              }
            }
          }
        }
      }

      int? backhaulSignalStrength;
      int? backhaulUplinkRate;
      int? backhaulDownlinkRate;
      if (includeBackhaulStats) {
        // Same conversion as the STA field above, but for the opposite reason
        // (#1555, AC5). This one is declared `check_range [0, 220]` upstream
        // (`device.odl:168`), so the controller rejects a reserved value before
        // it can reach us and `rcpiToRssi` is here for the `0` case —
        // `BackhaulStats` not populated yet — not for the 221-255 band. The
        // asymmetry with the STA field is the firmware's, deliberate, and not an
        // inconsistency to unify: `rcpiToRssi` covers both because it is the one
        // place either can be read, and dropping the range check because *this*
        // path cannot trigger it would re-open the STA path.
        backhaulSignalStrength =
            rcpiToRssi(node.backhaulStatsSignalStrengthRcpi);
        if ((node.backhaulStatsLastDataUplinkRate ?? 0) > 0) {
          backhaulUplinkRate = node.backhaulStatsLastDataUplinkRate;
        }
        if ((node.backhaulStatsLastDataDownlinkRate ?? 0) > 0) {
          backhaulDownlinkRate = node.backhaulStatsLastDataDownlinkRate;
        }
      }

      // Master node = the controller, the one node with no backhaul of its own.
      final isMaster = controllerListed
          ? _nodeKey(node.id) == controllerKey
          : !hasMeshBackhaulLink(node);

      // These nodes are built from DataElements, so `deviceId` *is* the
      // DataElements identifier; carry it in `dataElementsId` too so a
      // topology-derived node matches the same way a Hosts-derived one does.
      // Liveness (`isOnline`) is deliberately not set from it here: NodeEntity
      // reports `isOnline => true` unconditionally, so these nodes do not — and
      // must not appear to — report liveness of their own.
      if (isMaster) {
        nodes.add(MasterNode(
          deviceId: nodeDeviceId,
          dataElementsId: nodeDeviceId,
          model: _identity(node.manufacturerModel),
          manufacturer: _identity(node.manufacturer),
          serialNumber: _identity(node.serialNumber),
          softwareVersion: _identity(node.softwareVersion),
          instancePath: node.instancePath,
        ));
      } else {
        nodes.add(SlaveNode(
          deviceId: nodeDeviceId,
          dataElementsId: nodeDeviceId,
          model: _identity(node.manufacturerModel),
          manufacturer: _identity(node.manufacturer),
          serialNumber: _identity(node.serialNumber),
          softwareVersion: _identity(node.softwareVersion),
          instancePath: node.instancePath,
          backhaul: BackhaulInfo(
            linkType: meshBackhaulLinkType(node),
            signalStrength: backhaulSignalStrength,
            uplinkRate: backhaulUplinkRate,
            downlinkRate: backhaulDownlinkRate,
            // Read through the all-zero guard: it is a MAC from the same
            // `MultiAPDevice.Backhaul` object as the bench-measured sentinel, and
            // it is the field the master/slave discriminator keys on, so an
            // unguarded `00:00:00:00:00:00` would build the controller as a slave
            // whose parent nothing can resolve (#1555).
            //
            // `Backhaul.MACAddress` used to be read here too, onto a
            // `parentBssid` field. It is **not** the parent's BSSID — prplMesh's
            // own datamodel declaration
            // (`/opt/prplmesh/config/controller/odl/device.odl`) documents
            // `Backhaul.ServingBSSID` as that, and says nothing of the sort about
            // `MACAddress`, which is the node's own station address. Neither the
            // field nor the correct one beside it had a display consumer, so
            // #1441 AC4 deleted it rather than re-point it at a value no bench has
            // ever seen populated. Surfacing the parent BSSID is separate scope
            // and starts from `ServingBSSID` (already fetched as
            // `prplServingBssid`), not from here.
            parentNodeId: meshBackhaulParentId(node),
            lastContactTime:
                nonEpoch(node.multiApLastContactTime)?.toIso8601String(),
            backhaulMacAddress: _backhaulStaMac(node),
          ),
        ));
      }
    }

    final wired = interfaces == null
        ? null
        : wiredClientAttribution(
            network: network,
            interfaces: interfaces,
            wifiStations: clientToNodeMap.keys.toSet(),
          );

    return MeshTopologyInfo(
      nodes: nodes,
      clientToNodeMap: clientToNodeMap,
      clientSignalMap: clientSignalMap,
      clientBandSsidMap: clientBandSsidMap,
      wiredClientToNodeMap: wired?.byNode ?? const {},
      ambiguousWiredClients: wired?.ambiguous ?? const {},
    );
  }

  /// Which node each wired client is behind, from DataElements
  /// `Interface.{j}.Neighbor.{k}` (#1688 item 2).
  ///
  /// A non-1905 neighbor is a MAC in the node's bridge forwarding table — "seen
  /// through this port", not "plugged into this node". So most of them are not
  /// clients, and the rules are the ones `data_elements_interfaces.yaml`
  /// (linksys/usp_framework) and linksys/FWDEV#208 rule 2 set out:
  ///
  /// 1. Only `IsIEEE1905 == false`. `true` is another mesh node; `null` is
  ///    unknown, and an unknown row attributes nothing.
  /// 2. Drop every MAC that belongs to a mesh node. prplMesh removes only the
  ///    AL MAC, and on the bench 4 of 5 non-1905 neighbors were nodes' guest
  ///    bridges, backhaul STAs and backhaul BSSes. A node's MACs are its ID, its
  ///    `Interface.{j}.MACAddress`, `Backhaul.MACAddress`,
  ///    `Backhaul.BackhaulMACAddress`, its radios' `BackhaulSta.MACAddress` and
  ///    its BSSIDs.
  /// 3. A MAC in [wifiStations] (a `BSS.STA` entry) is a Wi-Fi client, not a
  ///    wired one: a Wi-Fi STA is a bridge-FDB entry too, and the station entry
  ///    wins.
  /// 4. A MAC exactly one node lists goes to `byNode`. A MAC two or more nodes
  ///    list goes to `ambiguous`: each node sees it through its own uplink.
  ///
  /// Presence here is not liveness — the forwarding table ages an unplugged
  /// client out only after ~300 s — so consumers keep reading `Hosts.Active`.
  /// All MACs are trimmed and upper-cased, the same form as [clientToNodeMap].
  static ({Map<String, String> byNode, Set<String> ambiguous})
      wiredClientAttribution({
    required DataElementsNetwork network,
    required DataElementsInterfaces interfaces,
    required Set<String> wifiStations,
  }) {
    String key(String mac) => mac.trim().toUpperCase();

    // Rule 2: every MAC any node owns.
    final nodeMacs = <String>{};
    void addNodeMac(String? mac) {
      final value = nonUnsetMac(mac);
      if (value != null) nodeMacs.add(key(value));
    }

    for (final node in network.items) {
      addNodeMac(node.id);
      addNodeMac(node.backhaulBackhaulMacAddress);
      addNodeMac(node.backhaulMacAddressMultiAp);
      for (final radio in node.radios) {
        addNodeMac(radio.backhaulStaMacAddress);
        for (final bss in radio.bssList) {
          addNodeMac(bss.bssid);
        }
      }
    }
    for (final node in interfaces.items) {
      addNodeMac(node.id);
      for (final interface in node.interfaces) {
        addNodeMac(interface.macAddress);
      }
    }

    // The two subtrees are separate Gets, so an agent can join or leave
    // between them. A client listed only by a node the network read did not
    // return would point at a node that is never built; count only nodes both
    // reads agree on, so such a client is "no evidence" and stays on the master.
    final builtNodeIds = {
      for (final node in network.items)
        if (key(node.id).isNotEmpty) key(node.id),
    };

    // Rules 1, 3: which nodes list each remaining non-1905 MAC.
    final listedBy = <String, Set<String>>{};
    for (final node in interfaces.items) {
      final nodeId = key(node.id);
      if (nodeId.isEmpty || !builtNodeIds.contains(nodeId)) continue;
      for (final interface in node.interfaces) {
        for (final neighbor in interface.neighbors) {
          if (neighbor.isIeee1905 != false) continue;
          final mac = nonUnsetMac(neighbor.id);
          if (mac == null) continue;
          final clientMac = key(mac);
          if (nodeMacs.contains(clientMac)) continue;
          if (wifiStations.contains(clientMac)) continue;
          (listedBy[clientMac] ??= <String>{}).add(nodeId);
        }
      }
    }

    // Rule 4.
    final byNode = <String, String>{};
    final ambiguous = <String>{};
    listedBy.forEach((mac, nodeIds) {
      if (nodeIds.length == 1) {
        byNode[mac] = nodeIds.single;
      } else {
        ambiguous.add(mac);
      }
    });
    return (byNode: byNode, ambiguous: ambiguous);
  }

  /// A trimmed identity string, empty when firmware reported nothing.
  ///
  /// The empty string rather than null because [NodeEntity]'s identity fields
  /// are non-nullable `String`, so absence has to arrive as `''`. That is the
  /// only reason this exists beside [nonEmpty] rather than being it, and the
  /// distinction matters one layer up: `MeshNetworkBuilder` merges these against
  /// `system_info`, where a `''` must not count as a value.
  ///
  /// Defined in terms of [nonEmpty] so the two cannot drift on what "reported
  /// nothing" means — the `?? ''` is the whole difference.
  static String _identity(String? value) => nonEmpty(value) ?? '';

  /// A node or controller ID as the master test compares it: separators
  /// stripped and upper-cased, or null when absent, blank, or the all-zero
  /// sentinel. `ControllerID` and `Device.{i}.ID` are separate leaves, so the
  /// comparison must not depend on them sharing a spelling.
  static String? _nodeKey(String? id) {
    final mac = nonUnsetMac(id);
    if (mac == null) return null;
    final key = meshNodeMacKey(mac);
    return key.isEmpty ? null : key;
  }

  /// The node's own station-side backhaul MAC.
  ///
  /// `Radio.{i}.BackhaulSta.MACAddress` is per-radio and only one radio carries
  /// the backhaul, so this takes the first radio that reports a real address.
  /// It replaces `Device.{i}.BackhaulMACAddress`, which the prplMesh schema does
  /// not define (#1555). The all-zero sentinel that the other radios report is
  /// recognised by [isUnsetMac], shared with `UspInstantPrivacyService` — the two
  /// read the same field and must agree on what "no station" looks like.
  static String? _backhaulStaMac(MeshNode node) {
    for (final radio in node.radios) {
      final mac = nonUnsetMac(radio.backhaulStaMacAddress);
      if (mac != null) return mac;
    }
    return null;
  }
}
