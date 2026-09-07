import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/network_entity.dart';

/// Sealed class for mesh network nodes (master or slave).
///
/// Use pattern matching to distinguish between [MasterNode] and [SlaveNode]:
/// ```dart
/// switch (node) {
///   case MasterNode m: print('Gateway: ${m.wanIpAddress}');
///   case SlaveNode s: print('Extender via ${s.backhaul.linkType}');
/// }
/// ```
sealed class NodeEntity extends NetworkEntity with DiagnosticNamed {
  // ─── Identity ───
  /// Device ID (MAC address, uppercase, normalized).
  String get deviceId;

  /// DataElements ID (may differ from deviceId for matching).
  String? get dataElementsId;

  /// User-friendly name.
  String? get friendlyName;

  /// Hostname from Hosts table.
  String? get hostName;

  // ─── Device Info ───
  /// Model name (e.g., "MR7500").
  String get model;

  /// Manufacturer name.
  String get manufacturer;

  /// Serial number.
  String get serialNumber;

  /// Firmware version.
  String get softwareVersion;

  // ─── Network ───
  /// LAN IP address.
  @override
  String? get ipAddress;

  /// LAN IPv6 addresses.
  @override
  List<String> get ipv6Addresses;

  // ─── DataElements internal ───
  /// DataElements instance path.
  String? get instancePath;

  // ─── Children ───
  /// Client devices connected to this node.
  List<ClientDevice> get connectedClients;

  // ─── NetworkEntity implementation ───
  @override
  String get id => deviceId;

  @override
  String get displayName {
    if (friendlyName != null && friendlyName!.isNotEmpty) return friendlyName!;
    if (hostName != null && hostName!.isNotEmpty) return hostName!;
    if (model.isNotEmpty) return model;
    return deviceId;
  }

  /// Node liveness. Deliberately left abstract: the master and a slave derive it
  /// from different facts, and a wrong inherited default is how #1430 shipped
  /// (`=> true` for every node) — see the overrides on [MasterNode] and
  /// [SlaveNode].
  ///
  /// Do **not** derive this from the Hosts row's `Device.Hosts.Host.{i}.Active`
  /// value. That field drives client online/offline, but firmware leaves it `0`
  /// for a *node* row whether the node is up or powered off (measured on the
  /// live bench, #1430), because node rows key on a STA-side MAC the backfill
  /// lookup never matches.
  @override
  bool get isOnline;

  // ─── Computed ───
  /// Whether this is the master (gateway) node.
  bool get isMaster;

  /// Role label for UI display.
  String get roleLabel => isMaster ? 'Master' : 'Slave';

  /// Number of connected clients.
  int get connectedDeviceCount => connectedClients.length;
}

/// Master (gateway) mesh node.
///
/// The primary router that connects to the internet via WAN.
final class MasterNode extends NodeEntity {
  @override
  final String deviceId;
  @override
  final String? dataElementsId;
  @override
  final String? friendlyName;
  @override
  final String? hostName;
  @override
  final String model;
  @override
  final String manufacturer;
  @override
  final String serialNumber;
  @override
  final String softwareVersion;
  @override
  final String? ipAddress;
  @override
  final List<String> ipv6Addresses;
  @override
  final String? instancePath;
  @override
  final List<ClientDevice> connectedClients;

  /// WAN IPv4 address.
  final String? wanIpAddress;

  /// WAN IPv6 address.
  final String? wanIpv6Address;

  /// Hosts DeviceID (UUID) — used by Remote Assistance / Guardian API calls.
  final String? hostsDeviceId;

  MasterNode({
    required this.deviceId,
    this.dataElementsId,
    this.friendlyName,
    this.hostName,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.ipAddress,
    this.ipv6Addresses = const [],
    this.instancePath,
    this.connectedClients = const [],
    this.wanIpAddress,
    this.wanIpv6Address,
    this.hostsDeviceId,
  });

  @override
  bool get isMaster => true;

  /// The master is the data source itself — it is online whenever the topology
  /// is being rendered at all, independent of any DataElements agent match
  /// (#1430, AC1).
  @override
  bool get isOnline => true;

  /// Returns a copy with the given fields replaced.
  ///
  /// A nullable field cannot be *cleared* through this method: every parameter
  /// merges with `?? this.field`, so passing `null` (or omitting it) both keep
  /// the current value — `copyWith(dataElementsId: null)` is indistinguishable
  /// from `copyWith()`. This is deliberate: no caller needs to null a field on
  /// a node, and the merge form keeps the builder call sites (which only ever
  /// set values) terse. To clear a field, construct a new [MasterNode]
  /// directly. Pinned by node_entity_test.dart. (Same idiom as
  /// ClientDevice.copyWith.)
  MasterNode copyWith({
    String? deviceId,
    String? dataElementsId,
    String? friendlyName,
    String? hostName,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? softwareVersion,
    String? ipAddress,
    List<String>? ipv6Addresses,
    String? instancePath,
    List<ClientDevice>? connectedClients,
    String? wanIpAddress,
    String? wanIpv6Address,
    String? hostsDeviceId,
  }) {
    return MasterNode(
      deviceId: deviceId ?? this.deviceId,
      dataElementsId: dataElementsId ?? this.dataElementsId,
      friendlyName: friendlyName ?? this.friendlyName,
      hostName: hostName ?? this.hostName,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      instancePath: instancePath ?? this.instancePath,
      connectedClients: connectedClients ?? this.connectedClients,
      wanIpAddress: wanIpAddress ?? this.wanIpAddress,
      wanIpv6Address: wanIpv6Address ?? this.wanIpv6Address,
      hostsDeviceId: hostsDeviceId ?? this.hostsDeviceId,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        dataElementsId,
        friendlyName,
        hostName,
        model,
        manufacturer,
        serialNumber,
        softwareVersion,
        ipAddress,
        ipv6Addresses,
        instancePath,
        connectedClients,
        wanIpAddress,
        wanIpv6Address,
        hostsDeviceId,
      ];

  @override
  String get diagnosticName => 'MasterNode';

  @override
  Map<String, Object?> get namedProps => {
        'deviceId': deviceId,
        'dataElementsId': dataElementsId,
        'friendlyName': friendlyName,
        'hostName': hostName,
        'model': model,
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'softwareVersion': softwareVersion,
        'ipAddress': ipAddress,
        'ipv6Addresses': ipv6Addresses,
        'instancePath': instancePath,
        'connectedClients': connectedClients,
        'wanIpAddress': wanIpAddress,
        'wanIpv6Address': wanIpv6Address,
        'hostsDeviceId': hostsDeviceId,
      };
}

/// Slave (extender) mesh node.
///
/// Extends the network via WiFi or Ethernet backhaul to the parent node.
final class SlaveNode extends NodeEntity {
  @override
  final String deviceId;
  @override
  final String? dataElementsId;
  @override
  final String? friendlyName;
  @override
  final String? hostName;
  @override
  final String model;
  @override
  final String manufacturer;
  @override
  final String serialNumber;
  @override
  final String softwareVersion;
  @override
  final String? ipAddress;
  @override
  final List<String> ipv6Addresses;
  @override
  final String? instancePath;
  @override
  final List<ClientDevice> connectedClients;

  /// Backhaul connection info to parent node.
  final BackhaulInfo backhaul;

  /// Whether DataElements liveness information was available for this node's
  /// network at all.
  ///
  /// A **whole-network** fact, not a per-node one: every slave produced by one
  /// build receives the same value. It answers "did the DataElements subtree
  /// answer at all", never "was this row found in it" — that second question is
  /// [dataElementsId], and it is only a verdict when this is `true`.
  ///
  /// `false` means the subtree carried nothing: the router does not implement
  /// it, the fetch failed (every error is swallowed into
  /// `MeshTopologyInfo.empty`, see `UspDevicesDataService.fetchMeshTopology`),
  /// or the first build pass ran before the background fetch returned. Nothing
  /// is known about any node there, so [isOnline] must not read the absent match
  /// as a verdict.
  ///
  /// `true` does not claim the set is *complete*. A slave absent from a
  /// non-empty set is judged offline, and that is intended — it is the
  /// powered-off extender #1430 exists to catch. See the producer at
  /// `MeshNetworkBuilder.build` for why the predicate is the topology being
  /// non-empty rather than the narrower "some slave agent answered".
  ///
  /// Defaults to `true` so that every construction site keeps AC1's rule
  /// unchanged; defaulting to `false` would not be a default but a rule change,
  /// making every node built anywhere else online unconditionally. The cost is
  /// that the default is the *unsafe* direction: a site with no topology to match
  /// against, such as `MeshTopologyBuilder`, silently reproduces the offline
  /// verdict with no analyzer signal. Making it `required` is #1466.
  final bool livenessKnown;

  SlaveNode({
    required this.deviceId,
    this.dataElementsId,
    this.friendlyName,
    this.hostName,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.ipAddress,
    this.ipv6Addresses = const [],
    this.instancePath,
    this.connectedClients = const [],
    required this.backhaul,
    this.livenessKnown = true,
  });

  @override
  bool get isMaster => false;

  /// A slave is online when it matched a DataElements agent. A powered-off node
  /// leaves `DataElements.Network.Device.` within ~20-50s while its
  /// `Device.Hosts.Host` row persists, so an unmatched node row is the offline
  /// shape (#1430, AC1).
  ///
  /// The match is only a verdict when there was something to match against. With
  /// [livenessKnown] false the absent match says nothing, and asserting offline
  /// there would render a healthy mesh offline and non-navigable
  /// (`usp_topology_view.dart` blocks taps on an offline node, and
  /// `node_detail_popup.dart` hides its Details button) for the whole session on
  /// any firmware or transport state that does not deliver DataElements.
  @override
  bool get isOnline => !livenessKnown || dataElementsId != null;

  /// Whether backhaul is Ethernet.
  bool get isEthernetBackhaul => backhaul.isEthernet;

  /// Whether backhaul info is available.
  bool get hasBackhaul => backhaul.hasInfo;

  /// Returns a copy with the given fields replaced.
  ///
  /// A nullable field cannot be *cleared* through this method: every parameter
  /// merges with `?? this.field`, so passing `null` (or omitting it) both keep
  /// the current value — `copyWith(dataElementsId: null)` is indistinguishable
  /// from `copyWith()`. This is deliberate: no caller needs to null a field on
  /// a node, and the merge form keeps the builder call sites (which only ever
  /// set values) terse. To clear a field, construct a new [SlaveNode]
  /// directly. Pinned by node_entity_test.dart. (Same idiom as
  /// ClientDevice.copyWith.)
  SlaveNode copyWith({
    String? deviceId,
    String? dataElementsId,
    String? friendlyName,
    String? hostName,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? softwareVersion,
    String? ipAddress,
    List<String>? ipv6Addresses,
    String? instancePath,
    List<ClientDevice>? connectedClients,
    BackhaulInfo? backhaul,
    bool? livenessKnown,
  }) {
    return SlaveNode(
      deviceId: deviceId ?? this.deviceId,
      dataElementsId: dataElementsId ?? this.dataElementsId,
      friendlyName: friendlyName ?? this.friendlyName,
      hostName: hostName ?? this.hostName,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      instancePath: instancePath ?? this.instancePath,
      connectedClients: connectedClients ?? this.connectedClients,
      backhaul: backhaul ?? this.backhaul,
      livenessKnown: livenessKnown ?? this.livenessKnown,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        dataElementsId,
        friendlyName,
        hostName,
        model,
        manufacturer,
        serialNumber,
        softwareVersion,
        ipAddress,
        ipv6Addresses,
        instancePath,
        connectedClients,
        backhaul,
        livenessKnown,
      ];

  @override
  String get diagnosticName => 'SlaveNode';

  @override
  Map<String, Object?> get namedProps => {
        'deviceId': deviceId,
        'dataElementsId': dataElementsId,
        'friendlyName': friendlyName,
        'hostName': hostName,
        'model': model,
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'softwareVersion': softwareVersion,
        'ipAddress': ipAddress,
        'ipv6Addresses': ipv6Addresses,
        'instancePath': instancePath,
        'connectedClients': connectedClients,
        'backhaul': backhaul,
        'livenessKnown': livenessKnown,
      };
}

/// Extension methods for List<NodeEntity>.
extension NodeEntityListExt on List<NodeEntity> {
  /// Returns the master (gateway) node, or null if not found.
  MasterNode? get master {
    for (final n in this) {
      if (n is MasterNode) return n;
    }
    return null;
  }

  /// Returns all slave (extender) nodes.
  List<SlaveNode> get slaves => whereType<SlaveNode>().toList();

  /// Whether this topology has mesh extenders.
  bool get hasMesh => any((n) => n is SlaveNode);
}
