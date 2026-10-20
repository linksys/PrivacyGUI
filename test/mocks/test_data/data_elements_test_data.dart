import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';

/// Builders for the DataElements codegen models (`DataElementsNetwork` and
/// `DataElementsInterfaces`), constitution Article I §1.6.2.
///
/// Promoted from `mesh_topology_builder_test.dart`'s file-local `_node` /
/// `_radio` / `_bss`, whose comment set the trigger: promote when a third
/// file needs a `MeshNode`. #1688 is that third caller — the wired-client
/// attribution tests need a node and its `Interface.{j}.Neighbor.{k}` rows
/// together. `mesh_backhaul_link_test.dart` keeps its own one-line `_node`:
/// it reads only the two backhaul fields, and a builder call there would say
/// less than the literal does.
///
/// Every parameter is named and defaulted, so a test states only the field it
/// is about.
class DataElementsTestData {
  DataElementsTestData._();

  /// `Device.WiFi.DataElements.Network.Device.{instance}.` — the path prefix
  /// every child of that node hangs off.
  static String nodePath(String instance) =>
      'Device.WiFi.DataElements.Network.Device.$instance.';

  /// One radio, optionally carrying the bSTA MAC and fronthaul BSSes.
  ///
  /// [backhaulStaMac] is where the node's own backhaul MAC lives since #1555.
  /// It used to be the node-level `BackhaulMACAddress`, which FL-WRT 2.0 does
  /// not define at all.
  static MeshRadio radio(
    String nodePath, {
    int index = 1,
    String? backhaulStaMac,
    List<MeshBss> bssList = const [],
  }) =>
      MeshRadio(
        instancePath: '${nodePath}Radio.$index.',
        backhaulStaMacAddress: backhaulStaMac,
        currentOperatingClassProfiles: const [],
        bssList: bssList,
      );

  /// One fronthaul BSS with [stations] attached.
  static MeshBss bss(
    String nodePath, {
    required String bssid,
    String ssid = 'HomeNetwork',
    List<({String mac, int rcpi})> stations = const [],
  }) =>
      MeshBss(
        instancePath: '${nodePath}Radio.1.BSS.1.',
        bssid: bssid,
        ssid: ssid,
        stations: [
          for (var i = 0; i < stations.length; i++)
            MeshStation(
              instancePath: '${nodePath}Radio.1.BSS.1.STA.${i + 1}.',
              macAddress: stations[i].mac,
              signalStrengthRcpi: stations[i].rcpi,
            ),
        ],
      );

  /// A `Device.{i}` row with only the fields a test names.
  ///
  /// The controller has no backhaul link: omit [linkType] and
  /// [parentDeviceId] (that is how `hasMeshBackhaulLink` recognises it).
  /// [backhaulMac] is `Backhaul.BackhaulMACAddress` and [backhaulMultiApMac]
  /// is `Backhaul.MACAddress` — both node-owned MACs that
  /// `wiredClientAttribution` must not mistake for a client.
  static MeshNode node({
    required String instance,
    required String id,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? softwareVersion,
    String? linkType,
    String? parentDeviceId,
    String? backhaulStaMac,
    String? backhaulMac,
    String? backhaulMultiApMac,
    int? rcpi,
    int? uplinkRate,
    int? downlinkRate,
    DateTime? lastContactTime,
    DateTime? statsTimeStamp,
    List<MeshBss> bssList = const [],
  }) {
    final path = nodePath(instance);
    return MeshNode(
      instancePath: path,
      id: id,
      manufacturerModel: model,
      manufacturer: manufacturer,
      serialNumber: serialNumber,
      softwareVersion: softwareVersion,
      multiApLastContactTime: lastContactTime,
      multiApEasyMeshAgentOperationMode: '',
      backhaulLinkType: linkType,
      backhaulBackhaulDeviceId: parentDeviceId,
      backhaulBackhaulMacAddress: backhaulMac,
      backhaulMacAddressMultiAp: backhaulMultiApMac,
      backhaulStatsLastDataDownlinkRate: downlinkRate,
      backhaulStatsLastDataUplinkRate: uplinkRate,
      backhaulStatsSignalStrengthRcpi: rcpi,
      backhaulStatsPacketsSent: 0,
      backhaulStatsPacketsReceived: 0,
      backhaulStatsErrorsSent: 0,
      backhaulStatsErrorsReceived: 0,
      backhaulStatsTimeStamp: statsTimeStamp,
      radios: [radio(path, backhaulStaMac: backhaulStaMac, bssList: bssList)],
    );
  }

  /// A whole `DataElementsNetwork`.
  static DataElementsNetwork network(List<MeshNode> nodes) =>
      DataElementsNetwork(items: nodes);

  /// One non-1905 or 1905 neighbor row.
  static MeshNeighbor neighbor(
    String interfacePath, {
    required int index,
    required String id,
    bool? isIeee1905 = false,
  }) =>
      MeshNeighbor(
        instancePath: '${interfacePath}Neighbor.$index.',
        id: id,
        isIeee1905: isIeee1905,
      );

  /// One `Interface.{index}` row of a node, with its neighbors given as
  /// `(id, isIeee1905)` pairs.
  ///
  /// [mediaType] uses prplMesh's enum spelling, as measured on
  /// 2.0.3.26101482: `IEEE_802_3AB_GIGABIT_ETHERNET` for a wired port,
  /// `IEEE_802_11BE` for Wi-Fi.
  static MeshInterface interface(
    String nodePath, {
    required int index,
    required String macAddress,
    String? mediaType,
    List<({String id, bool? isIeee1905})> neighbors = const [],
  }) {
    final path = '${nodePath}Interface.$index.';
    return MeshInterface(
      instancePath: path,
      macAddress: macAddress,
      mediaType: mediaType,
      neighbors: [
        for (var i = 0; i < neighbors.length; i++)
          neighbor(path,
              index: i + 1,
              id: neighbors[i].id,
              isIeee1905: neighbors[i].isIeee1905),
      ],
    );
  }

  /// One node's `Interface.*` subtree, joined to `DataElementsNetwork` on [id].
  static MeshNodeInterfaces nodeInterfaces({
    required String instance,
    required String id,
    List<MeshInterface> interfaces = const [],
  }) =>
      MeshNodeInterfaces(
        instancePath: nodePath(instance),
        id: id,
        interfaces: interfaces,
      );

  /// A whole `DataElementsInterfaces`.
  static DataElementsInterfaces interfaces(List<MeshNodeInterfaces> nodes) =>
      DataElementsInterfaces(items: nodes);
}
