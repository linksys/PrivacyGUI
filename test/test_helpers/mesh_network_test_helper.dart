import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// Creates an empty MeshNetwork for testing purposes.
MeshNetwork createEmptyMeshNetwork() {
  return MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'Test Router',
      connectedClients: [],
    ),
  );
}

/// Creates a MeshNetwork with the given clients for testing purposes.
MeshNetwork createMeshNetworkWithClients(List<ClientDevice> clients) {
  return MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'Test Router',
      connectedClients: clients,
    ),
  );
}

/// Creates a MeshNetwork with both master and slave nodes for testing purposes.
MeshNetwork createMeshNetworkWithNodes({
  required MasterNode master,
  List<SlaveNode> slaves = const [],
}) {
  return MeshNetwork(master: master, slaves: slaves);
}

/// Creates an empty DevicesData for testing purposes.
DevicesData createEmptyDevicesData() {
  return DevicesData(meshNetwork: createEmptyMeshNetwork());
}

/// Creates DevicesData with the given clients for testing purposes.
DevicesData createDevicesDataWithClients(List<ClientDevice> clients) {
  return DevicesData(meshNetwork: createMeshNetworkWithClients(clients));
}
