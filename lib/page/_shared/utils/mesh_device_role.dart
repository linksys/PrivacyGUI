/// The `Device.Hosts.Host.{i}.DeviceRole` values that identify a row as one of
/// the mesh's own nodes.
///
/// Firmware reports `'master'` for the gateway, `'slave'` for an extender and
/// `'client'` (or nothing at all) for an ordinary device — measured values,
/// see `doc/design/devices-nodes-topology-architecture.md`.
const meshNodeRoles = {'master', 'slave'};

/// Whether [deviceRole] identifies one of the mesh's own nodes.
///
/// Trimmed and lower-cased before comparison: `DeviceRole` is an unvalidated
/// wire string, and both callers of this predicate get it wrong in a way the
/// customer feels — a node not recognised as a node is a node offered as a
/// blockable row, and a node MAC missing from the allow-list is a node locked
/// out of its own network.
bool isMeshNodeRole(String? deviceRole) =>
    deviceRole != null &&
    meshNodeRoles.contains(deviceRole.trim().toLowerCase());
