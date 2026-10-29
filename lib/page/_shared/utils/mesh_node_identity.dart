/// Which `Device.Hosts.Host` rows are the mesh's own nodes.
///
/// **The one rule, for every consumer (#1688 item 3).** FL-WRT 2.0 has no
/// mesh-role leaf on `Hosts` — `DeviceRole`, `DeviceID` and `ParentNodeID` are
/// LinksysWRT 1.0 extensions, absent from the 2.0 schema and from TR-181 itself
/// (`Hosts.Host.{i}.DeviceRole` reads `does not exist in the schema` on
/// `2.0.3.26101482`). The firmware's contract instead (linksys/FWDEV#208, and
/// the header of linksys/usp_framework's `connected_devices.yaml`):
///
/// > Build the nodes from DataElements. A Hosts row whose `PhysAddress` equals
/// > a node's `Device.{i}.ID` is that node.
///
/// So membership is a set test against the IDs DataElements reports, and this
/// file is the only place that test is spelled. It takes plain ID strings
/// rather than a model because its two callers hold different layers: the
/// devices builder has the [MeshTopologyInfo] UI model, the MAC filter service
/// the raw codegen `DataElementsNetwork`. Each extracts its own IDs; neither
/// re-implements the comparison.
///
/// Replaces `mesh_device_role.dart` (`isMeshNodeRole`), which keyed on the
/// deleted `DeviceRole` and so recognised no node at all on 2.0.
library;

/// The normalized MAC set of every node in [nodeIds].
///
/// Normalization is upper-case hex with every separator removed, so the
/// comparison is indifferent to whether a side spells the MAC with colons,
/// dashes, or none — Hosts and DataElements both use colons today, but a
/// membership test that silently fails on a spelling change would turn every
/// node back into a client.
///
/// Only values that normalize to a full 48-bit MAC (12 hex digits) are kept.
/// That drops a blank ID, and it drops the instance path `MeshTopologyBuilder`
/// substitutes for a node whose `ID` is empty
/// (`Device.WiFi.DataElements.Network.Device.1.` keeps only a few hex letters),
/// which must not match a Hosts MAC by accident.
Set<String> meshNodeMacSet(Iterable<String> nodeIds) {
  final macs = <String>{};
  for (final id in nodeIds) {
    final mac = meshNodeMacKey(id);
    if (mac.length == 12) macs.add(mac);
  }
  return macs;
}

/// Whether the Hosts row with [physAddress] is one of the nodes in
/// [nodeMacSet] (built by [meshNodeMacSet]).
///
/// An empty [physAddress] is never a node.
bool isMeshNodeHost(String physAddress, Set<String> nodeMacSet) {
  final mac = meshNodeMacKey(physAddress);
  return mac.isNotEmpty && nodeMacSet.contains(mac);
}

/// [raw] as upper-case hex with every separator removed — the form both sides
/// of the node test are compared in.
///
/// Public so a caller that indexes rows by node (the devices builder pairs each
/// node with its Hosts row) keys them the same way [meshNodeMacSet] does,
/// rather than holding a second normalizer that has to agree with this one.
String meshNodeMacKey(String raw) =>
    raw.toUpperCase().replaceAll(RegExp('[^0-9A-F]'), '');
